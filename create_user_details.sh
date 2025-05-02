echo "Creating userdetails table"
apk add mysql-client
mysql --skip-ssl -uroot -proot -huser_db -e "create database govwifi_test"
mysql --skip-ssl -uroot -proot -huser_db govwifi_test  < mysql_user/schema.sql
