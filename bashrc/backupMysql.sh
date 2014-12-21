#!/usr/bin/env bash
# backupMysql.sh: backup mysql databases and keep newest 5 days backup.
#   restore db(test) use the follow command:
#   $ gzip < test.2014-04-09.gz | /home/mysql/mysql/bin/mysqldump -uroot -p test
# -----------------------------

db_user="root";
db_passwd="xxxxx";
db_host="localhost";

# the directory for story your backup file.
backup_dir="/home/xxxx/mysqlbackup";

# date format for backup file (yyyy-mm-dd)
#   or  time="$(date +"%Y-%m-%d_%H:%M:%S")"
time="$(date +"%Y-%m-%d")";

# mysql, mysqldump and some other bin's path
MYSQL="$(which mysql)";
MYSQL="${MYSQL:-/home/mysql/mysql/bin/mysql}";
MYSQLDUMP="$(which mysqldump)";
MYSQLDUMP="${MYSQLDUMP:-/home/mysql/mysql/bin/mysqldump}";
MKDIR="$(which mkdir)";
RM="$(which rm)";
MV="$(which mv)";
GZIP="$(which gzip)";

# the directory for story the newest backup
test ! -d "$backup_dir" && $MKDIR -p "$backup_dir";
# check the directory for store backup is writeable
test ! -w $backup_dir && echo "Error: $backup_dir is un-writeable." && exit 1;

# get all databases
####for loop, mysqldump backup db for (db1/db2...), backup the data to $backup_dir/$time.$db.gz
for db in highcharts mysql
do
    $MYSQLDUMP -u $db_user -h $db_host -p$db_passwd $db | $GZIP -9 > "$backup_dir/$db.$time.gz";
done

#delete the oldest backup 30 days ago
find $backup_dir -name "*.gz" -mtime +30 |xargs rm -rf

exit 0;
