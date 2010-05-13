CREATE USER cos IDENTIFIED BY 'password_here';

CREATE DATABASE commonservices_test CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE commonservices_development CHARACTER SET utf8 COLLATE utf8_general_ci; 
CREATE DATABASE commonservices_production CHARACTER SET utf8 COLLATE utf8_general_ci;

GRANT all privileges ON commonservices_development.* TO 'cos'@'localhost' IDENTIFIED BY 'password_here';
GRANT all privileges ON commonservices_production.* TO 'cos'@'localhost' IDENTIFIED BY 'password_here';
GRANT all privileges ON commonservices_test.* TO 'cos'@'localhost' IDENTIFIED BY 'password_here';
