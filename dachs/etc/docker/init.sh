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

su dachsroot -c "gavo init -d 'host=${DACHS_POSTGRES_HOST} dbname=${DACHS_POSTGRES_DBNAME}'"

echo "Starting GAVO..."
gavo serve start -f
