from collections import OrderedDict
import logging
import json
import random
import requests
from typing import Union
import urllib.parse

from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
import geoip2.database
from geopy.distance import great_circle
import liboidcagent as agent
from starlette.config import Config
from starlette.responses import Response, JSONResponse

config = Config()

# Instantiate FastAPI() allowing CORS.
#
app = FastAPI()
origins = ["*"]     # security risk if service is used externally

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

templates = Jinja2Templates(directory="templates")

# Instantiate geoip reader if GEOIP_LICENSE_KEY is set in environment
#
geoip_reader = None
if config.get("GEOIP_LICENSE_KEY", default=None):
    geoip_reader = geoip2.database.Reader(config.get('GEOIP_DATABASE_PATH'))

# Query sited for list of storage lat/longs #FIXME: needs to update periodically
#
sites = None
if config.get("SITED_STORAGES_ENDPOINT_JSON", default=None):
    response = requests.get(config.get('SITED_STORAGES_ENDPOINT_JSON'))
    content = response.content.decode('utf-8')
    sites = json.loads(content)

# Dependency to refresh access token if necessary.
async def refresh_access_token() -> Union[str, HTTPException]:
    try:
        token = agent.get_access_token(config.get('OIDC_CLIENT_NAME'))
    except agent.OidcAgentError as e:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Error getting token: {}".format(e))
    return token


@app.get('/links', response_class=templates.TemplateResponse)
async def links(id, request: Request, client_ip_address: str = None, sort: str = 'nearest_by_client',
                ranking: int = 0, token=Depends(refresh_access_token)) -> Union[templates.TemplateResponse, HTTPException]:
    scope, name = id.split(':')
    parameters = {
        'dids': [{
            'scope': scope,
            'name': name
        }]
    }
    response = requests.post(urllib.parse.urljoin(config.get('RUCIO_API_BASEURL'), 'replicas/list'),
        headers={
            'X-Rucio-Auth-Token': token,
            'Content-type': 'application/json'
        },
        data=json.dumps(parameters).encode('utf-8')
    )
    content = response.content.decode('utf-8')

    if response.status_code != 200:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Error getting replica data {}".format(content))

    if content:
        replicas_by_rse = json.loads(content)['rses']
    else:
        raise HTTPException(status.HTTP_204_NO_CONTENT)

    if sort == 'random':
        selection = random.choice(list(replicas_by_rse.values()))[0]
    elif sort == 'nearest_by_client':
        if not geoip_reader or not sites:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "nearest_by_client not supported.")

        if not client_ip_address:
            client_ip_address = request.client.host

        try:
            response = geoip_reader.city(client_ip_address)
            client_location = (response.location.latitude, response.location.longitude)
            distances_by_site = OrderedDict()
            for site in sites:
                if site['name'] in replicas_by_rse:
                    site_location = (site['latitude'], site['longitude'])
                    distances_by_site[site['name']] = int(great_circle(client_location, site_location).km)
            access_url = replicas_by_rse[sorted(distances_by_site, key=distances_by_site.get)[ranking]][0]
        except geoip2.errors.AddressNotFoundError:
            logging.warning("address not found, falling back to random")
            access_url = random.choice(list(replicas_by_rse.values()))

        return templates.TemplateResponse("datalink.xml", {
            "request": request,
            "did": id,
            "access_url": access_url,
            "ivoa_authority": config.get('IVOA_AUTHORITY')
        })

