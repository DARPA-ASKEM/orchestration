-- Create keycloak DB
CREATE USER keycloak;
ALTER USER keycloak WITH PASSWORD 'keycloak';
CREATE DATABASE keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

-- Create askem DB
CREATE USER terarium_user;
ALTER USER terarium_user WITH PASSWORD 'terarium';
CREATE DATABASE askem;
GRANT ALL PRIVILEGES ON DATABASE askem TO terarium_user;

-- Create terarium DB
CREATE DATABASE terarium;
GRANT ALL PRIVILEGES ON DATABASE terarium TO terarium_user;
