#!/bin/bash

# ##############################################################################
#
# Deploy N postgres instances locally. Create the same relation at each node and
# create a foreign server cross links.
#
# This script creates an environment for development of the global tables
# feature.
#
# ##############################################################################

PGINSTALL=`pwd`/tmp_install/

export LD_LIBRARY_PATH=$PGINSTALL/lib:$LD_LIBRARY_PATH
export PATH=$PGINSTALL/bin:$PATH
export LC_ALL=C
export LANGUAGE="en_US:en"
export PGPORT=5432 #default head
export PGDATABASE=`whoami`
export PGHOST=localhost
export PGUSER=`whoami`

pkill -U `whoami` -9 -e postgres
pkill -U `whoami` -9 -e pgbench

D1=`pwd`/PGDATA1
D2=`pwd`/PGDATA2
D3=`pwd`/PGDATA3

#rm -rf $D1 && mkdir $D1 && rm -rf $D2 && mkdir $D2 && rm -rf $D3 && mkdir $D3
rm -rf $PGINSTALL && rm n1.log && rm n2.log && rm n3.log

# Building project
make > /dev/null
make -C contrib > /dev/null
make install > /dev/null
make -C contrib install > /dev/null

SERVERS_NUM=3
remoteSrvName=fdwremote

# Create and init each server
for (( i=1; i <= $SERVERS_NUM; i++ ))
do
  pgdata=`pwd`/PGDATA$i
  port=$(( 5431 + i ))
  rm -rf $pgdata && mkdir $pgdata
  rm n$i.log
  initdb -D $pgdata -E UTF8 --locale=C
  echo "shared_preload_libraries = 'postgres_fdw, gtables_fdw'" >> $pgdata/postgresql.conf
  pg_ctl -w -c -o "-p $port" -D $pgdata -l n$i.log start
  createdb -p $port
  
  psql -p $port -c "CREATE EXTENSION postgres_fdw; CREATE EXTENSION gtables_fdw;"
  # Create global table
  psql -p $port -c "CREATE TABLE gt (id serial PRIMARY KEY, payload text);"
  # Create partitioned table
  psql -p $port -c "CREATE TABLE pt (id serial, payload text) PARTITION BY HASH(id);"
done

# Create cross links.
for (( i=1; i <= $SERVERS_NUM; i++ ))
do
  myport=$(( 5431 + i ))
  for (( j=1; j <= $SERVERS_NUM; j++ ))
  do
    port=$(( 5431 + j ))
    rs=$remoteSrvName$j
    remainder=$((j-1))

    if [ $port -eq $myport ]; then
      psql -p $myport -c "CREATE TABLE pt_$j PARTITION OF pt FOR VALUES WITH (modulus $SERVERS_NUM, remainder $remainder)"
      continue
    fi

    echo "CREATE FOREIGN SERVER from $port on $myport"
	psql -p $myport -c "CREATE SERVER $rs FOREIGN DATA WRAPPER postgres_fdw OPTIONS (port '$port')"
	psql -p $myport -c "CREATE USER MAPPING FOR PUBLIC SERVER $rs"
	psql -p $myport -c "CREATE FOREIGN TABLE gtn$j (id serial, payload text) SERVER $rs OPTIONS (table_name 'gt')"
	
	# Create foreign partition
	psql -p $myport -c "CREATE FOREIGN TABLE pt_$j PARTITION OF pt FOR VALUES WITH (modulus $SERVERS_NUM, remainder $remainder) SERVER $rs"
  done
  echo "------"
done

psql -p 5432 -c "explain SELECT * FROM gt,pt WHERE gt.id = pt.id"
