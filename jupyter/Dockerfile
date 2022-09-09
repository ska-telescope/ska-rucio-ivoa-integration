FROM jupyter/minimal-notebook

RUN pip3 install pyvo

COPY --chown=root:users etc/generate_password.py .
COPY --chown=root:users etc/jupyter_server_config.py /home/jovyan/.jupyter/jupyter_server_config.py
COPY --chown=root:users work/ /home/jovyan/work/

COPY --chown=root:users etc/docker/init.sh .

CMD ["/bin/bash", "init.sh"] 
