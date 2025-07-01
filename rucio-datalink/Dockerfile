FROM ubuntu:22.04

RUN apt-get update -y && apt-get -y install python3.10 python3-pip oidc-agent vim curl jq wget git
USER root

RUN useradd -ms /bin/bash user

COPY --chown=user:user . /opt/rucio_datalink

RUN cd /opt/rucio_datalink && python3 -m pip install -e . --extra-index-url https://gitlab.com/api/v4/projects/47269526/packages/pypi/simple --extra-index-url https://gitlab.com/api/v4/projects/44294004/packages/pypi/simple --extra-index-url https://gitlab.com/api/v4/projects/48060714/packages/pypi/simple  --extra-index-url https://gitlab.com/api/v4/projects/48376510/packages/pypi/simple
WORKDIR /opt/rucio_datalink

USER user

ENTRYPOINT ["/bin/bash", "etc/docker/init.sh"]
