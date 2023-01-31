FROM gavodachs/server 

ENV GAVORC_SERVER_URL=http://localhost:8080
ENV GAVORC_SERVER_PORT=8080

RUN apt-get update -y && apt-get install gettext-base

# copy in gavo config and make environment subsitutions
COPY etc/dachs/gavo.rc /tmp/gavo.rc
RUN cat /tmp/gavo.rc | envsubst > /etc/gavo.rc

COPY etc/docker/init.sh /init.sh
ENTRYPOINT ["/bin/bash", "init.sh"]
