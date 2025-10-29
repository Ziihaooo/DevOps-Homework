CREATE DATABASE IF NOT EXISTS stagingdb;
USE stagingdb;


CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100)
);


INSERT INTO users (name) VALUES ('Daniel'), ('Bob'),('Lu'), ('Fan');