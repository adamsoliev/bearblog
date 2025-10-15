# https://wiki.postgresql.org/wiki/Sample_Databases

# 1) get into the VM
multipass shell <name_of_instance>

# 2) grab the db
cd /tmp
git clone https://github.com/devrimgunduz/pagila.git

# 3) create the database 
sudo -u postgres createdb pagila

# 4) load schema, then data
sudo -u postgres psql -d pagila -f /tmp/pagila/pagila-schema.sql
sudo -u postgres psql -d pagila -f /tmp/pagila/pagila-data.sql
