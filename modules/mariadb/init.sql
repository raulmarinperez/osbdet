CREATE USER 'osbdet'@'localhost' IDENTIFIED BY 'osbdet123$';
GRANT ALL PRIVILEGES ON *.* TO 'osbdet'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;