#!/bin/bash

# Execute commands as root
sudo tcsh -c "source /MYSQL/cloud101/env/cloud101.rc"

# Create a new directory under /data/mariadb/backups
mkdir -p /data/mariadb/backups/work

# Change to the specified directory
cd /data/mariadb/backups/work

# Generate a dynamic filename with timestamp
DUMP_FILENAME="dump_$(date +"%Y%m%d%H%M%S")"

# Prompt for MySQL Connection Details
read -p "MySQL Host: " 
read -p "MySQL User: "
read -s -p "MySQL Password: "
echo    ####################################################################################

# Prompt for list of MySQL Databases (comma-separated)
read -p "MySQL Database: " 

# Convert comma-separated values to an array
IFS=',' read -ra DB_ARRAY <<< "$MYSQL_DATABASES"

# Prompt for MariaDB Galera Cluster Connection Details
read -p "Galera Cluster Host: "
read -p "Galera Cluster User: " 
read -s -p "Galera Cluster Password: "
echo    #####################################################################################

# Execute commands as root
sudo tcsh -c "source /MYSQL/cloud101/env/cloud101.rc"

# change a new directory befoe the restore
cd /MYSQL/cloud101/work
mkdir dump 
cd dump

for DATABASE in "${DB_ARRAY[@]}"; do
    # Dump MySQL database to a dynamic filename using nohup
    DUMP_FILENAME="$DUMP_FILENAME_PREFIX"_"$DATABASE".gz
    nohup mysqldump --single-transaction --master-data=2 -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE | gzip -c > $DUMP_FILENAME &
done

# Wait for the background process to finish
wait $!

# Import the dump into MariaDB Galera Cluster inside the 'work' directory
zcat $DUMP_FILENAME | mysql -h $NODE1_IP -u $GALERA_USER -p$GALERA_PASSWORD

# Configure replication to node 1
echo "CHANGE MASTER TO MASTER_HOST='$NODE1_IP', MASTER_USER='$GALERA_USER', MASTER_PASSWORD='$GALERA_PASSWORD';" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

# Start replication
echo "START SLAVE;" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

# Check replication status
echo "SHOW SLAVE STATUS \G" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

