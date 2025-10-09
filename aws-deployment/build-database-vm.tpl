#!/bin/bash
echo "🗄️ Setting up Database VM..."

apt-get update

export MYSQL_PWD='insecure_mysqlroot_pw'
echo "mysql-server mysql-server/root_password password $MYSQL_PWD" | debconf-set-selections 
echo "mysql-server mysql-server/root_password_again password $MYSQL_PWD" | debconf-set-selections

apt-get install -y mysql-server
service mysql start

echo "CREATE DATABASE tasktracker;" | mysql
echo "CREATE USER 'apiuser'@'%' IDENTIFIED BY 'insecure_api_pw';" | mysql
echo "GRANT ALL PRIVILEGES ON tasktracker.* TO 'apiuser'@'%';" | mysql

# Embed your setup-database.sql directly
export MYSQL_PWD='insecure_api_pw'
cat <<'EOF' | mysql -u apiuser tasktracker
-- Task Tracker Database Schema
-- Used by build-database-vm.sh

CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    due_date DATE,
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO tasks (title, description, completed, due_date, priority) VALUES 
('Setup 3-VM Architecture', 'Split into Frontend + API + Database VMs', FALSE, '2025-09-08', 'high'),
('Build REST API', 'Create PHP endpoints for task management', FALSE, '2025-09-09', 'high'),
('Create Frontend Interface', 'Build JavaScript interface for task tracker', FALSE, '2025-09-10', 'medium'),
('Test VM Communication', 'Verify all 3 VMs work together', FALSE, '2025-09-11', 'medium'),
('Organize Lab 6 Style', 'Use clean script-based architecture', FALSE, '2025-09-12', 'medium');
EOF

sed -i'' -e '/bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

echo "✅ Database VM ready"