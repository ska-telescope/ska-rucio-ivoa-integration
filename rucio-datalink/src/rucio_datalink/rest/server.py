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
from starlette.responses import Response, HTMLResponse, JSONResponse

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

# FIXME: needs to update periodically, but don't want to hammer the api
# Query sited for list of storage lat/longs and services
#
rses = None
services = None
if config.get("SITED_STORAGES_ENDPOINT", default=None):
    response = requests.get("{}/storages/grafana".format(config.get('SITED_STORAGES_ENDPOINT')))
    content = response.content.decode('utf-8')
    rses = json.loads(content)

    response = requests.get("{}/services".format(config.get('SITED_STORAGES_ENDPOINT')))
    content = response.content.decode('utf-8')
    services_by_site = json.loads(content)

# Dependency to refresh access token if necessary.
def refresh_access_token() -> Union[str, HTTPException]:
    try:
        token = agent.get_access_token(config.get('OIDC_CLIENT_NAME'))
    except agent.OidcAgentError as e:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Error getting token: {}".format(e))
    return token


@app.get('/ping')
async def ping(request: Request):
    return JSONResponse('pong')


@app.get('/links', response_class=HTMLResponse)
async def links(id, request: Request, client_ip_address: str = None, sort: str = 'nearest_by_client', must_include_soda: bool = False,
                ranking: int = 0, token=Depends(refresh_access_token)) -> Union[templates.TemplateResponse, HTTPException]:
    try:
        scope, name = id.split(':')
    except ValueError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, 'could not parse id.')

    # Get replicas for this DID.
    #
    parameters = {
        'dids': [{
            'scope': scope,
            'name': name
        }],
    }
    response = requests.post(urllib.parse.urljoin(config.get('RUCIO_CFG_HOST'), 'replicas/list'),
        headers={
            'X-Rucio-Auth-Token': token,
            'Content-type': 'application/json'
        },
        data=json.dumps(parameters).encode('utf-8')
    )
    content = response.content.decode('utf-8')
    if response.status_code != 200:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "error getting replica data {}".format(content))
    if content:
        replicas_by_rse = json.loads(content)['rses']
    else:
        raise HTTPException(status.HTTP_204_NO_CONTENT)

    # Get metadata for this DID.
    #
    params = {
        'plugin': 'POSTGRES_JSON'
    }
    response = requests.get(
        urllib.parse.urljoin(config.get('RUCIO_CFG_HOST'), 'dids/{}/{}/meta'.format(
            scope, name
        )),
        headers={
            'X-Rucio-Auth-Token': token,
            'Content-type': 'application/json'
        },
        params=params
        )
    content = response.content.decode('utf-8')
    if response.status_code != 200:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "error getting metadata {}".format(content))
    metadata = json.loads(content)

    # Refine replicas based on SODA service availability, if requested.
    #
    soda_sync_services_by_rse = OrderedDict()
    soda_async_services_by_rse = OrderedDict()
    if must_include_soda:
        # Get a list of SODA services per RSE.
        #
        # FIXME: yikes
        if not services_by_site:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "must_include_soda not supported.")
        for rse, replicas in replicas_by_rse.items():
            for site in services_by_site:
                for service in site['services']:
                    if service['type'] == 'Rucio Storage Element (RSE)' and \
                            service['identifier'] == rse:
                        # sync
                        for _service in site['services']:
                            if _service['type'] == 'SODA (sync)':
                                if not soda_sync_services_by_rse.get(rse, None):
                                    soda_sync_services_by_rse[rse] = []
                                soda_sync_services_by_rse[rse].append(_service)
                        # async
                        for _service in site['services']:
                            if _service['type'] == 'SODA (async)':
                                if not soda_async_services_by_rse.get(rse, None):
                                    soda_async_services_by_rse[rse] = []
                                soda_async_services_by_rse[rse].append(_service)
        # remove sites with no SODA services (both sync and async)
        for site in set(replicas_by_rse.keys()) - \
                    set(soda_sync_services_by_rse.keys()) - \
                    set(soda_async_services_by_rse.keys()):
            replicas_by_rse.pop(site)

    if not replicas_by_rse:
        if must_include_soda:
            details = "No replicas with local SODA service found for this DID."
        else:
            details = "No replicas found for this DID."
        raise HTTPException(status.HTTP_404_NOT_FOUND, details)

    # FIXME: some of this should has been abstracted into the datalake api
    # Get a replica depending on the sort algorithm.
    #
    selected_rse = None
    selected_rse_replica = None
    if sort == 'random':
        selected_rse = random.choice(list(replicas_by_rse.keys()))
        selected_rse_replica = random.choice(replicas_by_rse[selected_rse])
    elif sort == 'nearest_by_client':
        if not geoip_reader or not rses:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "nearest_by_client not supported.")
        if not client_ip_address:
            client_ip_address = request.headers.get('x-real-ip', '')
        try:
            response = geoip_reader.city(client_ip_address)
            client_location = (response.location.latitude, response.location.longitude)
            distances_by_rse = OrderedDict()
            for rse in rses:
                if rse['name'] in replicas_by_rse:
                    rse_location = (rse['latitude'], rse['longitude'])
                    distances_by_rse[rse['name']] = int(great_circle(client_location, rse_location).km)
            selected_rse = sorted(distances_by_rse, key=distances_by_rse.get)[ranking]
            selected_rse_replica = random.choice(replicas_by_rse[selected_rse])
        except geoip2.errors.AddressNotFoundError:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "client ip addressed could not be geolocated.")
    else:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "sort algorithm not understood.")

    access_url = selected_rse_replica
    soda_sync_service = {}
    soda_async_service = {}
    if must_include_soda:
        soda_sync_service = random.choice(soda_sync_services_by_rse[selected_rse])
        soda_async_service = random.choice(soda_async_services_by_rse[selected_rse])
    return templates.TemplateResponse("datalink.template.xml", {
        "request": request,
        "ivoa_authority": config.get('IVOA_AUTHORITY'),
        "path_on_storage": "{}/{}".format(scope, access_url.split(scope)[1].lstrip('/')),       #FIXME: this doesn't necessarily work for non-deterministic, need to look it up
        "access_url": access_url,
        "description": metadata.get('obs_id', ''),
        "content_type": metadata.get('content_type', ''),
        "content_length": metadata.get('content_length', ''),
        "include_soda": must_include_soda,
        "soda_sync_resource_identifier": soda_sync_service.get('other_attributes', {}).get(
            'resourceIdentifier', {}).get('value', None) or '',    # e.g. {"resourceIdentifier": {"value": "ivo://skao.src/spsrc-soda/"}}
        "soda_sync_access_url": "{}://{}:{}/{}".format(
            soda_sync_service.get('prefix', ''),
            soda_sync_service.get('host', ''),
            soda_sync_service.get('port', ''),
            soda_sync_service.get('path', '').lstrip('/')
        ),
        "soda_async_resource_identifier": soda_async_service.get('other_attributes', {}).get(
            'resourceIdentifier', {}).get('value', None) or '',     # e.g. {"resourceIdentifier": {"value": "ivo://skao.src/spsrc-soda/"}}
        "soda_async_access_url": "{}://{}:{}/{}".format(
            soda_async_service.get('prefix', ''),
            soda_async_service.get('host', ''),
            soda_async_service.get('port', ''),
            soda_async_service.get('path', '').lstrip('/')
        )
    }, media_type="application/xml")

