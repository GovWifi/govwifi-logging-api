echo "Creating userdetails table"
apk add mysql-client
mysql --skip-ssl -uroot -proot -huser_db -e "create database govwifi_test"
mysql --skip-ssl -uroot -proot -huser_db -D govwifi_test < mysql_user/schema.sql
