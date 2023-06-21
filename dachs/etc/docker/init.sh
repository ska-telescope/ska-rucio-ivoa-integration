echo "host: $DACHS_POSTGRES_HOST"
echo "dbname: $DACHS_POSTGRES_DBNAME"
echo
echo -n "Waiting for postgres to come up..."
while ! su - dachsroot -c "psql -h ${DACHS_POSTGRES_HOST} --quiet ${DACHS_POSTGRES_DBNAME} -c 'SELECT 1' > /dev/null 2>&1" ;
do
    sleep 5
    echo -n "."
done
echo

# substitute env into gavo.rc template
cat /tmp/gavo.rc.template | envsubst > /etc/gavo.rc

# subsitute envvars into driver connection string
cat /tmp/inputs/externaldb/data/driver.template | envsubst > /tmp/inputs/externaldb/data/driver

su dachsroot -c "gavo init -d 'host=${DACHS_POSTGRES_HOST} dbname=${DACHS_POSTGRES_DBNAME}'"

echo "Copying in inputs from /tmp/inputs..."
cp -r /tmp/inputs/* /var/gavo/inputs/

# the following must be done after gavo init (hence can't be done at db init), otherwise the roles don't exist
echo "Altering permissions for rucio related tables and schema..."
psql -h $DACHS_POSTGRES_HOST --dbname $DACHS_POSTGRES_DBNAME -c "ALTER SCHEMA rucio OWNER TO gavoadmin;"
psql -h $DACHS_POSTGRES_HOST --dbname $DACHS_POSTGRES_DBNAME -c "ALTER TABLE rucio.dids OWNER TO gavoadmin;"
psql -h $DACHS_POSTGRES_HOST --dbname $DACHS_POSTGRES_DBNAME -c "ALTER TABLE rucio.obscore OWNER TO gavoadmin;"

echo "Starting DaCHS in background and initialising obscore..."
dachs serve start
dachs imp //obscore

echo "Importing RDs..."
# note: can't have both of these as they occupy same schema space

# if externaldb is used, uncomment this
#dachs imp externaldb/externaldb && gavo pub externaldb/externaldb

# if externally managed rucio table is used, uncomment this (note -m flag)
dachs imp -m rucio/rucio && gavo pub rucio/rucio

echo "Reload DaCHS..."
dachs serve reload

# the next command hangs the container, this is necessary as running dachs in the fg (-f) doesn't output the 
# pid to /var/gavo/etc/state, so subsequent commands don't work (unless this is manually populated as 
# commented at the bottom of this Dockerfile
while true; do sleep 30; done; 

#export gavo_pid=`ps -ef | grep gavo | awk -F " " {' print $2 '}`
#echo $gavo_pid > /var/gavo/state/web.pid
