# Cluster

Create cluster with mostly default options.
Current pool consists of two n1-standard-2 instances.

# Cloud SQL

Create 2nd gen instance in same zone as cluster. Current specs are db-n1-standard-2 with
20 GB of storage capacity.

## Custom MySQL flags:

lower_case_table_names: 1
character_set_server: utf8
max_allowed_packet: 32000000

## Set root password

Access Control -> Users -> Change root password

See https://cloud.google.com/sql/docs/create-manage-user-mysql

## Set up emonocot user

```
create user 'emonocot'@'%' identified by '<password>';
grant all privileges on emonocot.* to 'emonocot'@'%';
flush privileges;
```

## Create secrets

```
bin/encode_secrets.py db-secrets ../powop-secrets/gcp-production/powop-prod-sql-user > secrets/prod_db.yml
kubectl create -f secrets/prod_db.yml
kubectl create -f secrets/geo_db.yml
kubectl create secret generic cloudsql-oauth-credentials --from-file=secrets/cloudsql-credentials.json
```

# Solr

## Create persistent disk

On `powop-sysadmin` machine:

```
# Create persistent disk. Call disk `solr-data-[env]` (env = `dev`, `uat`, `prod`, etc)
# For non-prod instances, use gc.mkgcedisk
gc.mkgcediskssd solr-data-[env] 20

# mount and format the persistent disk as ext4
gc.formatgcedisk-local solr-data-[env] solr-data

# set permissions on disk to uid solr runs under
sudo chown -R 8983:8983 /mnt/solr-data

# dettach disk from admin machine
gc.dettachgcedisk powop-sysadmin solr-data
```
