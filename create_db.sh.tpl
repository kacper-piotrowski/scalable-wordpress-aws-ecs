#!/bin/bash
dnf install -y mariadb105 2>/dev/null || true

for i in $(seq 1 40); do
    mysql -h "${db_host}" -u "${db_user}" -p"${db_password}" -e "SELECT 1" 2>/dev/null && break
    sleep 15
done

%{ for svc in wp_services ~}
mysql -h "${db_host}" -u "${db_user}" -p"${db_password}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${svc}_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`${svc}_db\`.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
SQL
%{ endfor ~}