# cpdb
Copy all of tables in mssql to postgres Database.

## What does it?
Mostly to copy the table from one database to another database, first you have to create the exact table structure for the new table as old one, using somethiing like DDL, then copy the table entries from one table to another.

But cpdb simplify all of the above procedures, just copy table from mssql to postgresql.

## Prerequisites
cpdb is a tiny bash shell script so it needs some install before use.

### 1. mssql for linux
> <span style='color: #9061ff'> Microsoft (R) SQL Server Command Line Tool</spqn>
>
> sqlcmd 17.10.0001.1 Linux
>
> https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup?view=sql-server-ver16
>
### 2. mssql for linux mssql-scripter
>
> python 3.7.15
>
> pip 20.2.2
>
> https://github.com/microsoft/mssql-scripter.git

### 3. sqlserver2pgsql
>
> perl 5.16.3
>
> https://github.com/dalibo/sqlserver2pgsql

### 4. psql
> <span style='color: #9061ff'> PostgreSQL interactive terminal </span>
> 
> psql 13.9
>
> https://www.postgresql.org/download/

Here is sample for installing required before use cpdb.

```bash
# ldc_cpd

Copy mssql db to postgres

-- python, perl install
[ec2-user@ip-10-129-97-208 ~]$ sudo yum update -y
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
232 packages excluded due to repository priority protections
No packages marked for update
[ec2-user@ip-10-129-97-208 ~]$ sudo yum install -y python3 pip3
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
amzn2-core                                                                                                                                                                                 | 3.7 kB  00:00:00
232 packages excluded due to repository priority protections
Package python3-3.7.15-1.amzn2.0.2.x86_64 already installed and latest version
No package pip3 available.
Nothing to do
[ec2-user@ip-10-129-97-208 ~]$ pip3 install mssql-scripter
Defaulting to user installation because normal site-packages is not writeable
Collecting mssql-scripter
  Downloading mssql_scripter-1.0.0a23-py2.py3-none-manylinux1_x86_64.whl (38.0 MB)
     |████████████████████████████████| 38.0 MB 772 kB/s
Collecting enum34>=1.1.6
  Downloading enum34-1.1.10-py3-none-any.whl (11 kB)
Collecting wheel>=0.29.0
  Downloading wheel-0.38.4-py3-none-any.whl (36 kB)
Collecting future>=0.16.0
  Downloading future-0.18.2.tar.gz (829 kB)
     |████████████████████████████████| 829 kB 96.7 MB/s
Using legacy 'setup.py install' for future, since package 'wheel' is not installed.
Installing collected packages: enum34, wheel, future, mssql-scripter
    Running setup.py install for future ... done
Successfully installed enum34-1.1.10 future-0.18.2 mssql-scripter-1.0.0a23 wheel-0.38.4
[ec2-user@ip-10-129-97-208 dbwork]$ vi ~/.local/bin/mssql-scripter
change python -m mssqlscripter "$@" to python3 -m mssqlscripter "$@"

[ec2-user@ip-10-129-97-208 dbwork]$ mssql-scripter -h
usage: mssql-scripter [-h] [--connection-string  | -S ] [-d] [-U] [-P] [-f]
..



[ec2-user@ip-10-129-97-208 ~]$ cd ~/download
[ec2-user@ip-10-129-97-208 ~]$ git clone https://github.com/dalibo/sqlserver2pgsql.git
Cloning into 'sqlserver2pgsql'...
remote: Enumerating objects: 1012, done.
remote: Counting objects: 100% (201/201), done.
```
## Usage
And use like this
```bash
[ec2-user@ip-10-129-97-208 ~]$ cd /home/ec2-user/mig/workspace/ldc_mig/cpdb
[ec2-user@ip-10-129-97-208 cpdb]$ ./cpdb.sh
Invalid arguments
cpdb.sh -lw(lia_web) | -ld(lia_direct) -t {schema.table_name}
ex> cpdb.sh -lw
    cpdb.sh -lw -t dbo.test
[ec2-user@ip-10-129-97-208 cpdb]$

-- ./cpdb.sh -ld : lia_direct
[ec2-user@ip-10-129-97-208 cpdb]$ ./cpdb.sh -ld
COPY 15
dbo.direct_application_form_enc copy completed. [ OK ]

-- ./cpdb.sh -lw : lia_web
[ec2-user@ip-10-129-97-208 cpdb]$ ./cpdb.sh -lw
COPY 15213
dbo.aaa_test copy completed. [ OK ]

-- ./cpdb.sh -ld -t dbo.bbb_test : specify one table in lia_direct
[ec2-user@ip-10-129-97-208 cpdb]$ ./cpdb.sh -ld -t dbo.direct_application_form_enc
COPY 15
dbo.direct_application_form_enc copy completed. [ OK ]

-- ./cpdb.sh -lw -t dbo.aaa_test : specify one table in lia_web
[ec2-user@ip-10-129-97-208 cpdb]$ ./cpdb.sh -lw -t lia_web.clickok_illustration
COPY 15213
lia_web.clickok_illustration copy completed. [ OK ]
...

Before execute cpdb.sh, you should grant priviledges to psql user.

grant usage on schema cpmgldds to myuser;
grant usage on schema cpmglwds to myuser;
grant usage on schema cpmglwls to myuser;
grant all on schema cpmgldds to myuser;
grant all on schema cpmglwds to myuser;
grant all on schema cpmglwls to myuser;
...
