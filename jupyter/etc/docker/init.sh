#!/bin/bash

if [ -v JUPYTER_SERVER_PASSWORD ]
then 
  echo "c.ServerApp.password = u'`python3 generate_password.py $JUPYTER_SERVER_PASSWORD`'" >> /home/jovyan/.jupyter/jupyter_server_config.py 
fi

if [ -v JUPYTER_SERVER_BASE_URL ]                                                       
then
  echo "c.ServerApp.base_url = '`echo $JUPYTER_SERVER_BASE_URL`'" >> /home/jovyan/.jupyter/jupyter_server_config.py 
fi

/bin/bash start-notebook.sh
