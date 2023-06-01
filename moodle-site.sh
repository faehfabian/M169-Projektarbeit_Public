#!/bin/bash

mkdir ./moodle-persistence
mkdir ./mariadb-persistence
mkdir ./moodledata-persistence

sudo chown -R 1001:1001 ./mariadb-persistence
sudo chown -R 1001:1001 ./moodle-persistence
sudo chown -R 1001:1001 ./moodledata-persistence

# Dockerfile erstellen
echo "FROM bitnami/moodle:4.1

LABEL maintainer "fabian@example.com"
LABEL description "Moodle-Seite fuers M169"

ENV APACHE_HTTPS_PORT_NUMBER="443"
ENV APACHE_HTTP_PORT_NUMBER="80"

EXPOSE 80 443" > /home/vmadmin/Desktop/Dockerfile

# Docker-Secret Passwortdatei erstellen
echo "bitnami" > db_password.txt


# Docker-compose File erstellen
echo "version: '3.8'

services:
  mariadb:
    image: bitnami/mariadb:latest
    container_name: mymariadb
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=bn_moodle
      - MARIADB_PASSWORD_FILE=/run/secrets/db_password
      - MARIADB_DATABASE=bitnami_moodle
    networks:
      - moodle-network
    volumes:
      - /home/vmadmin/Desktop/mariadb-persistence:/bitnami/mariadb
    secrets:
      - db_password

  moodle:
    build: /home/vmadmin/Desktop/
    container_name: moodle
    ports:
      - \"80:80\"
      - \"443:443\"
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MOODLE_DATABASE_USER=bn_moodle
      - MOODLE_DATABASE_PASSWORD_FILE=/run/secrets/db_password
      - MOODLE_DATABASE_NAME=bitnami_moodle
    networks:
      - moodle-network
    volumes:
      - /home/vmadmin/Desktop/moodle-persistence:/bitnami/moodle
      - /home/vmadmin/Desktop/moodledata-persistence:/bitnami/moodledata
    secrets:
      - db_password

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    ports:
      - \"81:80\"
    environment:
      - PMA_HOST=mariadb
    networks:
      - moodle-network

networks:
  moodle-network:
    driver: bridge
 
secrets:
   db_password:
     file: db_password.txt" > docker-compose.yml

# Docker Compose ausführen
docker-compose up -d

# Warten, bis die Container gestartet sind
sleep 300

# MySQL-Dump erstellen
sudo mysqldump --password='Riethuesli>12345' moodle > dump.sql

sleep 10

# Dump in den MySQL-Container laden
docker cp dump.sql mymariadb:/var/lib/mysql

sleep 10

# In den MariaDB-Container wechseln und den Dump importieren
docker exec -i mymariadb bash -c "mysql -u root -e 'DROP DATABASE bitnami_moodle; CREATE DATABASE bitnami_moodle;'"
docker exec -i mymariadb mysql -u root bitnami_moodle < ./dump.sql

echo "Öffnen Sie http://localhost:80 in ihrem Browser und führen Sie das Datenbankupgrade aus."
# Ausgabe einer Nachricht
echo "Das Skript wurde pausiert. Drücken Sie Enter um fortzufahren."

# Warten auf Benutzereingabe
read

# Fortsetzung des Skripts
echo "Fortsetzung des Skripts..."

sleep 10

sudo cp -r /var/www/moodledata/* /home/vmadmin/Desktop/moodledata-persistence/

# Aufräumen: Lokalen Dump und docker-compose file entfernen
rm dump.sql
rm docker-compose.yml