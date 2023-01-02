#!/bin/sh
# db copy : lina_web.dbo => cpmglwds, lina_web.lina_web => cpmglwls, lina_direct.dbo => cpmgldds
source ~/.bash_profile 
source ./conf/.cpdb.props

if [ $# != 1 ] && [ $# != 3 ]; then
  echo "Invalid arguments"
  echo "cpdb.sh -lw(lina_web) | -ld(lina_direct) -t {schema.table_name}"
  echo "ex> cpdb.sh -lw"
  echo "    cpdb.sh -lw -t dbo.test"
  exit 1
fi

echo Started at `date`

if [ "$1" == "-lw" ]; then
  ASIS_DB=lina_web
  REMAP_SCH="dbo=>cpmglwds;lina_web=>cpmglwls"
fi
if [ "$1" == "-ld" ]; then
  ASIS_DB=lina_direct
  REMAP_SCH="dbo=>cpmgldds"
fi
DUMP_DIR=${DUMP_DIR}/${ASIS_DB}
ASIS_TABS=${DUMP_DIR}/asis.tabs
ANUL_COLS=${CONF_DIR}/${ASIS_DB}/anul.cols
CNVS_COLS=${CONF_DIR}/${ASIS_DB}/cnvs.cols
UPTS_COLS=${CONF_DIR}/${ASIS_DB}/upts.cols
EXPT_TABS=$(cat ${CONF_DIR}/${ASIS_DB}/expt.tabs)
ASIS_PSWD=$(echo ${ASIS_PSWD} |openssl enc -aes-256-cbc -a -pass pass:'pick.your.password' -d)
TOBE_PSWD=$(echo ${TOBE_PSWD} |openssl enc -aes-256-cbc -a -pass pass:'pick.your.password' -d)

# 1. Get list of tables from mssql (@sqlcmd)
if [ "$2" == "-t" ]; then
  tab_escape=$(echo $3 |sed 's/\x27/\x27\x27/g')
#echo ${tab_escape}
  sqlcmd -S ${ASIS_HOST},${ASIS_PORT} -d ${ASIS_DB} -U ${ASIS_USER} -P ${ASIS_PSWD} -y 0 << ED1 |head -n -2 | sed -e 's/ *$//g' > ${ASIS_TABS}
  select lower(table_schema + '.' + table_name) as tab from information_schema.tables where table_schema + '.' + table_name = '${tab_escape}'
  go
ED1
else
  sqlcmd -S ${ASIS_HOST},${ASIS_PORT} -d ${ASIS_DB} -U ${ASIS_USER} -P ${ASIS_PSWD} -y 0 << ED2 |head -n -2 | sed -e 's/ *$//g' > ${ASIS_TABS}
  select lower(table_schema + '.' + table_name) as tab from information_schema.tables where table_type = 'BASE TABLE' and table_schema + '.' + table_name not in ${EXPT_TABS} and table_schema in ('dbo','lina_web') order by table_name
  go
ED2
fi

# 2. Export and import
for tab in `cat ${ASIS_TABS}`; do
  if [ "${ASIS_DB}" == "lina_web" ]; then
    tab_tobe=`echo ${tab} |sed -e "s/^dbo/cpmglwds/" |sed -e "s/^lina_web/cpmglwls/"`
  fi
  if [ "${ASIS_DB}" == "lina_direct" ]; then
    tab_tobe=`echo ${tab} |sed -e "s/^dbo/cpmgldds/"`
  fi
  echo -e "\e[38;5;11m+[ ${tab} -> ${tab_tobe} ] \e[m"

  tab_escape=$(echo ${tab} |sed 's/\x27/\x27\x27/g')
  tab_bracket=$(echo ${tab} |sed 's/\./\]\.\[/;s/^/\[/;s/$/\]/')

  # 2-0. Geneerate create scripts for mssql tables (@python)
  mssql-scripter -S ${ASIS_HOST},${ASIS_PORT} -d ${ASIS_DB} -U ${ASIS_USER} -P ${ASIS_PSWD} --script-create --check-for-existence --include-types table --exclude-primary-keys --exclude-foreign-keys --exclude-check-constraints --exclude-extended-properties --exclude-defaults --exclude-indexes --exclude-triggers --include-objects ${tab} -f ${DUMP_DIR}/${tab}.sql

  # 2-1. Generate columns for quoted string with csv format (@sqllcmd or @bcp)
  columns=$(sqlcmd -S ${ASIS_HOST},${ASIS_PORT} -d ${ASIS_DB} -U ${ASIS_USER} -P ${ASIS_PSWD} -Q "select case when data_type in ('char','nchar','varchar','nvarchar','text','ntext') then case when column_name is null then 'NULL,' else 'concat(''\"'',replace(replace(replace(convert(varchar(max),'+'['+column_name+']'+') COLLATE Korean_Wansung_BIN,0x00,0x),''\\'',''\\\\''),''\"'',''\\\"''),''\"''),' end when data_type in ('varbinary') then 'convert(varchar(max),['+column_name+'],2),' when data_type in ('image') then 'convert(varchar(max),convert(varbinary(max),['+column_name+'],2),2),' else '['+column_name+'],' end from information_schema.columns where table_schema+'.'+table_name = '${tab}'" -y 0 -I |head -n -2 |tr -d '\n' |sed 's/,$//' |sed 's/\[\[/\"\[/g' |sed 's/\]\]/\]\"/g')
#echo select ${columns} from ${tab_bracket}
  
  # 2-2. Convert create scripts to postgres (@perl)
  ~/download/sqlserver2pgsql/sqlserver2pgsql.pl -f ${DUMP_DIR}/${tab}.sql -b ${DUMP_DIR}/${tab}.obs -a ${DUMP_DIR}/dummy.oas -u ${DUMP_DIR}/dummy.ous -relabel_schemas ${REMAP_SCH}

  # 2-3. Create postgres table (@psql)
  export PGPASSWORD=${TOBE_PSWD}
  tab_tobe_quoted=$(echo ${tab_tobe} |sed 's/\./\"\.\"/;s/^/\"/;s/$/\"/')
  echo "drop table if exists ${tab_tobe_quoted}" |psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -q
  psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -q < ${DUMP_DIR}/${tab}.obs

  # 2-4. Change ddl for graceful import, if table matched
  grep ${tab_tobe} ${ANUL_COLS} |while read table column; do
    psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -c "alter table ${table} alter column ${column} drop not null"
  done
  grep ${tab_tobe} ${CNVS_COLS} |while read table column type; do
    psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -c "alter table ${table} alter column ${column} type ${type}"
  done

  # 2-5. Copy and replicate data via pipeline : mssql <STDOUT> => poqstgres <STDIN>
  sqlcmd -S ${ASIS_HOST},${ASIS_PORT} -d ${ASIS_DB} -U ${ASIS_USER} -P ${ASIS_PSWD} -Q "select ${columns} from ${tab_bracket} with (nolock);" -y 0 -s"," -I |head -n -2 |psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -c "\\copy ${tab_tobe_quoted} from stdin with (format csv, NULL 'NULL', delimiter ',', quote '\"', escape '\')"

  # 2-6($?). Sweep the floor for clean
  if [ $? == 0 ]; then
    echo -e "${tab} copy completed. [ \e[1;32mOK\e[m ]"
    rm ${DUMP_DIR}/${tab}.*
  fi

  # 2-7. Update data in postgres hex string to binary byte
  grep ${tab_tobe} ${UPTS_COLS} |while read table column; do
    psql -h ${TOBE_HOST} -p ${TOBE_PORT} -d ${TOBE_DB} -U ${TOBE_USER} -c "update ${tab_tobe} set ${column} = decode(convert_from(${column}, 'UTF8'),'hex')"
  done

  echo ""
done

echo Finished at `date`
