CREATE DATABASE IF NOT EXISTS app_db_test;
USE app_db_test;


CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100)
);


INSERT INTO users (name) VALUES ('Daniel'), ('Bob'),('Lu'), ('Fan');