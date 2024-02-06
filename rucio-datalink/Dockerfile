FROM ubuntu:22.04

RUN apt-get update -y && apt-get -y install python3.10 python3-pip oidc-agent vim curl jq wget

USER root

RUN useradd -ms /bin/bash user

COPY --chown=user:user . /opt/rucio_datalink

RUN python3 -m pip install ska-src-data-management-api --index-url https://gitlab.com/api/v4/projects/47269526/packages/pypi/simple
RUN cd /opt/rucio_datalink && python3 -m pip install -e .

WORKDIR /opt/rucio_datalink

USER user

ENTRYPOINT ["/bin/bash", "etc/docker/init.sh"]
