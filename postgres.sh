export DEBIAN_FRONTEND=noninteractive

apt update
apt install postgresql-common -y
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

apt install postgresql-16 -y

# https://pgtune.leopard.in.ua
cat <<EOT >> /etc/postgresql/16/main/postgresql.conf
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 768MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 7864kB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 655kB
huge_pages = off
min_wal_size = 1GB
max_wal_size = 4GB
EOT
service postgresql restart
