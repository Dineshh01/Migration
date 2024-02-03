# Prompt for MariaDB Galera Cluster Connection Details
read -p "Galera Cluster Host: "
read -p "Galera Cluster User: "
read -s -p "Galera Cluster Password: "
echo    #####################################################################################

# Create a new directory under /data/mariadb/backups
mkdir -p /data/mariadb/backups/work

# Change to the specified directory
cd /data/mariadb/backups/work

# Scp from the MYSQL server
scp -i 504000 -u $MYSQL_USER@$MYSQL_HOST:/MYSQL/cloud101/work/dump/*.gz .

# Checking if database exists with same name and dropping them 
for DATABASE in "${DB_ARRAY[@]}"; do
    mysql -h $NODE1_IP -u $GALERA_USER -p$GALERA_PASSWORD -e "DROP DATABASE IF EXISTS $DATABASE;"
done

# creating the same Databases as mysql
for DATABASE in "${DB_ARRAY[@]}"; do
    # Create the database on Galera Cluster
    mysql -h $NODE1_IP -u $GALERA_USER -p$GALERA_PASSWORD -e "CREATE DATABASE $DATABASE;"


# Configure replication to node 1
echo "CHANGE MASTER TO MASTER_HOST='$NODE1_IP', MASTER_USER='$GALERA_USER', MASTER_PASSWORD='$GALERA_PASSWORD';" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

# Start replication
echo "START SLAVE;" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

# Check replication status
echo "SHOW SLAVE STATUS \G" | mysql -u $GALERA_USER -p$GALERA_PASSWORD

