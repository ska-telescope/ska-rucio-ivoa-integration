import ast
from collections import OrderedDict
import json
import random
import requests
from typing import Union, Optional

from authlib.integrations.requests_client import OAuth2Session
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
from starlette.config import Config
from starlette.responses import Response, HTMLResponse, JSONResponse

from ska_src_data_management_api.client.data_management import DataManagementClient

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

# Instantiate an OAuth2 request session for the data-management-api.
#
DATA_MANAGEMENT_CLIENT = OAuth2Session(config.get("DATA_MANAGEMENT_CLIENT_ID"),
                                         config.get("DATA_MANAGEMENT_CLIENT_SECRET"),
                                         scope=config.get("DATA_MANAGEMENT_CLIENT_SCOPES", default=""))

templates = Jinja2Templates(directory="templates")


# A service token is used to get client_credentials access to other APIs.
class ServiceToken:
    def __init__(self, default_scopes, audience, client, iam_token_endpoint, additional_scopes: Optional[str] = None):
        self.default_scopes = default_scopes
        self.audience = audience
        self.client = client
        self.iam_token_endpoint = iam_token_endpoint
        self.additional_scopes = additional_scopes

    def get_token(self):
        additional_scopes = self.additional_scopes if self.additional_scopes else ''
        scopes = "{} {}".format(self.default_scopes, additional_scopes)

        token = None
        try:
            token = self.client.fetch_token(
                self.iam_token_endpoint,
                grant_type="client_credentials",
                audience=self.audience,
                scope=scopes
            )
        except Exception as e:
            raise Exception(repr(e))
        return token.get('access_token')


# A data management service token.
#
class DataManagementServiceToken(ServiceToken):
    def __init__(self, additional_scopes: Optional[str] = None):
        super().__init__(
            default_scopes=config.get("DATA_MANAGEMENT_CLIENT_SCOPES"),
            audience=config.get("DATA_MANAGEMENT_CLIENT_AUDIENCE"),
            client=DATA_MANAGEMENT_CLIENT,
            iam_token_endpoint="https://ska-iam.stfc.ac.uk/token",
            additional_scopes=additional_scopes,
        )


@app.get('/ping')
async def ping(request: Request):
    return JSONResponse('pong')


@app.get('/links', response_class=HTMLResponse)
async def links(id, request: Request, client_ip_address: str = None, sort: str = 'random',
                must_include_soda: bool = False, ranking: int = 0) -> Union[templates.TemplateResponse, HTTPException]:
    try:
        scope, name = id.split(':')
    except ValueError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, 'Could not parse id.')

    # First we must get the replica locations (with some sort algorithm, e.g. geolocation) and data identifier metadata.
    # This is retrieved from the data-management API.
    #
    metadata = {}
    replicas_by_rse = None
    if config.get("DATA_MANAGEMENT_ENDPOINT", default=None):
        client = DataManagementServiceToken()
        dm_token = client.get_token()

        session = requests.Session()
        session.headers.update({'Authorization': 'Bearer {}'.format(dm_token)})
        data_management = DataManagementClient(config.get('DATA_MANAGEMENT_ENDPOINT'), session=session)

        metadata = data_management.get_metadata(namespace=scope, name=name).json()

        replicas_by_rse = {}

        if must_include_soda:
            soda_sync_services_by_rse = {}
            soda_async_services_by_rse = {}
            # Get list of replicas colocated with SODA services
            replicas_and_services_by_rse = data_management.locate_replicas_of_file(
                namespace=scope,
                name=name,
                sort=sort,
                ip_address=client_ip_address,
                colocated_services="SODA (async), SODA (sync)"                                                          #FIXME: Just SODA for now.
            ).json()

            # Sort response into replicas by RSE and SODA services by RSE
            for rse, replicas_and_services in replicas_and_services_by_rse.items():
                replicas_by_rse[rse] = replicas_and_services.get('replicas', [])
                soda_sync_services_by_rse[rse] = [service for service in replicas_and_services.get('services', [])
                                                  if service.get('type') == 'SODA (sync)']
                soda_async_services_by_rse[rse] = [service for service in replicas_and_services.get('services', [])
                                                   if service.get('type') == 'SODA (async)']
        else:
            replicas_by_rse = data_management.locate_replicas_of_file(
                namespace=scope,
                name=name,
                sort=sort,
                ip_address=client_ip_address
            ).json()

        if not replicas_by_rse:
            raise HTTPException(status.HTTP_204_NO_CONTENT)

    # Select the RSE (by ranking) and replica (randomly)
    if ranking > len(replicas_by_rse)-1:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Ranking is greater than number of replicas.")
    selected_rse = list(replicas_by_rse.keys())[ranking]
    selected_rse_replica = random.choice(replicas_by_rse[selected_rse])

    # Return populated Datalink XML result
    access_url = selected_rse_replica
    soda_sync_service = {}
    soda_async_service = {}
    if must_include_soda:
        soda_sync_service = random.choice(soda_sync_services_by_rse[selected_rse])
        soda_async_service = random.choice(soda_async_services_by_rse[selected_rse])
    return templates.TemplateResponse("datalink.template.xml", {
        "request": request,
        "ivoa_authority": config.get('IVOA_AUTHORITY'),
        "path_on_storage": "{}/{}".format(scope, access_url.split(scope)[1].lstrip('/')),                               #FIXME: this doesn't necessarily work for non-deterministic, need to look it up
        "access_url": access_url,
        "description": metadata.get('obs_id', ''),
        "content_type": metadata.get('content_type', ''),
        "content_length": metadata.get('content_length', ''),
        "datalinks": ast.literal_eval(metadata.get('datalinks', '[]')),
        "include_soda": must_include_soda,
        "soda_sync_resource_identifier": soda_sync_service.get('other_attributes', {}).get(
            'resourceIdentifier', {}).get('value', None) or '',    # e.g. {"resourceIdentifier": {"value": "ivo://skao.src/spsrc-soda/"}}
        "soda_sync_access_url": "https://data-management.srcdev.skao.int/api/v1/data/soda/{}/{}/{}".format(
            soda_sync_service.get('id'), scope, name),
        "soda_async_resource_identifier": soda_async_service.get('other_attributes', {}).get(
            'resourceIdentifier', {}).get('value', None) or '',     # e.g. {"resourceIdentifier": {"value": "ivo://skao.src/spsrc-soda/"}}
        "soda_async_access_url": "https://data-management.srcdev.skao.int/api/v1/data/soda/{}/{}/{}".format(
            soda_sync_service.get('id'), scope, name),
    }, media_type="application/xml")

