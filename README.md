# cpdb
Copy all of tables in mssql to postgres Database.

## What does it?
Mostly to copy the table from one database to another database, first you have to create the exact table structure for the new table as old one, using somethiing like DDL, than copy the table entries from one table to another.
cpdb automated the whole procedures to just copy table from mssql to postgresql.

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

-- python, perl insttall
[ec2-user@ip-10-129-97-208 ~]$ ls
dbwork  download  mig  time.sh
[ec2-user@ip-10-129-97-208 ~]$ cd dbwork

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
Requirement already satisfied: mssql-scripter in /usr/local/lib/python3.7/site-packages (1.0.0a23)
Requirement already satisfied: enum34>=1.1.6 in /usr/local/lib/python3.7/site-packages (from mssql-scripter) (1.1.10)
Requirement already satisfied: wheel>=0.29.0 in /usr/local/lib/python3.7/site-packages (from mssql-scripter) (0.38.4)
Requirement already satisfied: future>=0.16.0 in /usr/local/lib/python3.7/site-packages (from mssql-scripter) (0.18.2)
[ec2-user@ip-10-129-97-208 dbwork]$ mssql-scripter -h
usage: mssql-scripter [-h] [--connection-string  | -S ] [-d] [-U] [-P] [-f]
..
[ec2-user@ip-10-129-97-208 ~]$ git clone https://github.com/dalibo/sqlserver2pgsql.git
..
[ec2-user@ip-10-129-97-208 ~]$ sudo yum install perl-Data-Dumper
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
232 packages excluded due to repository priority protections
Package perl-Data-Dumper-2.145-3.amzn2.0.2.x86_64 already installed and latest version
Nothing to do
[ec2-user@ip-10-129-97-208 dbwork]$ ./sqlserver2pgsql/sqlserver2pgsql.pl -h
Usage:
    sqlserver2pgsql.pl -f SQLSERVER_SCHEMA_FILE -b BEFORE_FILE -a AFTER_FILE -u UNSURE_FILE ... OPTIONS
..
```
## Usage
And use like this
```bash
[ec2-user@ip-10-129-97-208 ldc_cpdb]$ ./cpdb.sh
Invalid arguments
cpdb.sh -lw(lina_web) | -ld(lina_direct) -t {schema.table_name}
ex> cpdb.sh -lw
    cpdb.sh -lw -t dbo.test
[ec2-user@ip-10-129-97-208 dbwork]$

-- ./cpdb.sh -ld : lina_direct
[ec2-user@ip-10-129-97-208 dbwork]$ ./cpdb.sh -ld
COPY 15
dbo.direct_application_form_enc copy completed. [ OK ]

-- ./cpdb.sh -lw : lina_web
[ec2-user@ip-10-129-97-208 dbwork]$ ./cpdb.sh -lw
COPY 15213
dbo.aaa_test copy completed. [ OK ]

-- ./cpdb.sh -ld -t dbo.bbb_test : specify one table in lina_direct
[ec2-user@ip-10-129-97-208 dbwork]$ ./cpdb.sh -ld -t dbo.direct_application_form_enc
COPY 15
dbo.direct_application_form_enc copy completed. [ OK ]

-- ./cpdb.sh -lw -t dbo.aaa_test : specify one table in lina_web
[ec2-user@ip-10-129-97-208 dbwork]$ ./cpdb.sh -lw -t lina_web.clickok_illustration
COPY 15213
lina_web.clickok_illustration copy completed. [ OK ]
...
