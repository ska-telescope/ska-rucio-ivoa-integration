FROM tomcat:9.0

ARG TOMCAT_TAPSERVER_BASE_URL=/tapserver

COPY conf/* $CATALINA_HOME/conf

COPY tapserver $CATALINA_HOME/webapps${TOMCAT_TAPSERVER_BASE_URL}

#RUN mv $CATALINA_HOME/webapps.dist/manager $CATALINA_HOME/webapps
#COPY manager $CATALINA_HOME/webapps/manager

CMD ["catalina.sh", "run"]

