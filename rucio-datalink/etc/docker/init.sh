#!/bin/bash

get_token () {
  # authn/z
  if [ "${RUCIO_CFG_AUTH_TYPE,,}" == 'oidc' ]
  then
    if [ -v OIDC_AGENT_AUTH_CLIENT_CFG_VALUE ] && [ -v OIDC_AGENT_AUTH_CLIENT_CFG_PASSWORD ] && [ -v RUCIO_CFG_ACCOUNT ] # if client config is being passed in as a value (e.g. from a k8s secret)
    then
      echo "proceeding with oidc authentication via passed client values..."
      # initialise oidc-agent
      # n.b. this assumes that the configuration has a refresh token attached to it with infinite lifetime
      eval "$(oidc-agent-service use)"
      mkdir -p ~/.oidc-agent
      # copy across the auth client configuration (-e to interpolate newline characters)
      echo -e "$OIDC_AGENT_AUTH_CLIENT_CFG_VALUE" > ~/.oidc-agent/rucio-auth
      # add configuration to oidc-agent
      oidc-add --pw-env=OIDC_AGENT_AUTH_CLIENT_CFG_PASSWORD rucio-auth
      # get client name (can be different to short name used by oidc-agent)
      export OIDC_CLIENT_NAME=$(oidc-gen --pw-env=OIDC_AGENT_AUTH_CLIENT_CFG_PASSWORD -p rucio-auth | jq -r .name)
      # retrieve token from oidc-agent
      oidc-token --scope "$RUCIO_CFG_OIDC_SCOPE" --aud "$RUCIO_CFG_OIDC_AUDIENCE" $OIDC_CLIENT_NAME > "/tmp/tmp_auth_token_for_account_$RUCIO_CFG_ACCOUNT"
    elif [ -v OIDC_ACCESS_TOKEN ] && [ -v RUCIO_CFG_ACCOUNT ] # if access token is being passed in directly
    then
      echo "proceeding with oidc authentication using an access token..."
      echo "$OIDC_ACCESS_TOKEN" > "/tmp/tmp_auth_token_for_account_$RUCIO_CFG_ACCOUNT"
    else
      echo "requested oidc auth but one or more of \$OIDC_AGENT_AUTH_CLIENT_CFG_VALUE, \$OIDC_AGENT_AUTH_CLIENT_CFG_PASSWORD, \$RUCIO_CFG_ACCOUNT or \$OIDC_ACCESS_TOKEN are not set"
      exit 1
    fi
    tr -d '\n' < "/tmp/tmp_auth_token_for_account_$RUCIO_CFG_ACCOUNT" > "/tmp/auth_token_for_account_$RUCIO_CFG_ACCOUNT"
    # move this token to the location expected by Rucio
    mkdir -p /tmp/user/.rucio_user/
    mv "/tmp/auth_token_for_account_$RUCIO_CFG_ACCOUNT" /tmp/user/.rucio_user/
  fi
}

# get a token ad-hoc
get_token 

# do a simple whoami query
echo "querying Rucio endpoint for account details..."
export ACCESS_TOKEN=`cat /tmp/user/.rucio_user/auth_token_for_account_$RUCIO_CFG_ACCOUNT`
curl -s -XGET $RUCIO_CFG_HOST/accounts/$RUCIO_CFG_ACCOUNT -H "X-Rucio-Auth-Token: $ACCESS_TOKEN" | jq

# get geoip database
if [ -v GEOIP_LICENSE_KEY ]
then
  geoip_database_compressed_sha256_path='/opt/rucio_datalink/GeoLite2-City.tar.gz.sha256'
  wget -O $geoip_database_compressed_sha256_path "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$GEOIP_LICENSE_KEY&suffix=tar.gz.sha256"

  geoip_database_path_compressed="/opt/rucio_datalink/"`cat GeoLite2-City.tar.gz.sha256 | awk -F ' ' '{ print $2 }'`
  wget -O $geoip_database_path_compressed "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$GEOIP_LICENSE_KEY&suffix=tar.gz"

  sha256sum -c $geoip_database_compressed_sha256_path
  if [ $? -eq 0 ]
  then
    echo "Geoip checksum ok."
  else
    echo "Geoip checksum failed."
    exit 1
  fi

  top_level_directory=`tar -tzf $geoip_database_path_compressed | head -1 | cut -f1 -d"/"`
  tar -xzvf $geoip_database_path_compressed
  database_filename=`ls $top_level_directory | grep mmdb`
  export GEOIP_DATABASE_PATH=`readlink -f $top_level_directory/$database_filename`
fi

cd /opt/rucio_datalink/src/rucio_datalink/rest

# run server in bg
uvicorn server:app --host "0.0.0.0" --port $SERVICE_DATALINK_PORT --reload --reload-dir ../../../etc/ --reload-include *.xml &

# periodically get a new token
while true; do get_token & sleep 3600; done
