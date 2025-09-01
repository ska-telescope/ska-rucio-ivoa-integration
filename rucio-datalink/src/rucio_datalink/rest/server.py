import ast
from collections import OrderedDict
import json
import os
import random
import requests
from typing import Union, Optional, List, Dict

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
                                       config.get(
                                           "DATA_MANAGEMENT_CLIENT_SECRET"),
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


def build_service_info(service):
    """Extract relevant info from a single service dict."""
    other_attrs = service.get('other_attributes', {})
    resource_identifier = (
        other_attrs.get('resourceIdentifier', {}).get('value', '') or ''
    )
    access_url = "{prefix}://{host}:{port}/{path}".format(
        prefix=service.get('prefix', ''),
        host=service.get('host', ''),
        port=service.get('port', ''),
        path=service.get('path', '').lstrip('/')
    )
    return {
        'resource_identifier': resource_identifier,
        'access_url': access_url,
    }


@app.get('/ping')
async def ping(request: Request):
    """ Service aliveness. """
    return JSONResponse({
        'status': "UP",
        'version': os.environ.get('SERVICE_VERSION'),
    })


@app.get('/links', response_class=HTMLResponse)
async def links(id, request: Request, client_ip_address: str = None, sort: str = 'random',
                str_services: str = None, ranking: int = 0) -> Union[templates.TemplateResponse, HTTPException]:
    '''
    Parameters
    ----------
    id : TYPE
        DESCRIPTION.
    request : Request
        DESCRIPTION.
    client_ip_address : str, optional
        DESCRIPTION. The default is None.
    sort : str, optional
        DESCRIPTION. The default is 'random'.
    str_services : str, optional
        string with list of services separted by comma. The default is None.
        example: "soda_sync, soda_async, gauss_conv"
    ranking : int, optional
        DESCRIPTION. The default is 0.

    Raises
    ------
    HTTPException
        DESCRIPTION.

    Returns
    -------
    None.

    '''
    try:
        scope, name = id.split(':')
    except ValueError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, 'Could not parse id.')

    # First we must get the replica locations (with some sort algorithm, e.g. geolocation) and data identifier metadata.
    # This is retrieved from the data-management API.
    #
    metadata = {}
    replicas_by_rse = None
    if config.get("DATA_MANAGEMENT_API_URL", default=None):
        dm_client = DataManagementServiceToken()
        dm_token = dm_client.get_token()

        dm_session = requests.Session()
        dm_session.headers.update(
            {'Authorization': 'Bearer {}'.format(dm_token)})
        data_management = DataManagementClient(config.get(
            'DATA_MANAGEMENT_API_URL'), session=dm_session)

        metadata = data_management.get_metadata(
            namespace=scope, name=name).json()

        # Get list of replicas
        location_response = data_management.locate_replicas_of_file(
            namespace=scope,
            name=name,
            sort=sort,
            ip_address=client_ip_address,
            colocated_services=str_services
        ).json()

        #  Parse service types from string
        if str_services:
            service_types = [s.strip() for s in str_services.split(',')]
        else:
            service_types = []

        # To store replicas and services grouped by type and RSE identifier
        replicas_by_rse = {}
        services_by_rse = {stype: {} for stype in service_types}

        # Iterate over each entry in the location response
        for entry in location_response:
            rse = entry.get('identifier')
            replicas = entry.get('replicas', [])

            if rse and replicas:
                replicas_by_rse[rse] = replicas

            # Get colocated services for this RSE (default to empty list)
            colocated_services = entry.get("colocated_services", [])

            # Filter colocated services by each service type
            for stype in service_types:
                filtered_services = [
                    service for service in colocated_services
                    if service.get("type") == stype
                ]
                # Store filtered services under their type and RSE identifier
                services_by_rse[stype][rse] = filtered_services

    if not replicas_by_rse:
        raise HTTPException(status.HTTP_204_NO_CONTENT)

    # Select the RSE (by ranking) and replica (randomly)
    if ranking > len(replicas_by_rse)-1:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "Ranking is greater than number of replicas.")

    # Select the RSE (by ranking) and replica (randomly)
    selected_rse = list(replicas_by_rse.keys())[ranking]

    if not replicas_by_rse[selected_rse]:
        raise HTTPException(status_code=status.HTTP_204_NO_CONTENT,
                            detail=f"No replicas found for RSE {selected_rse}")

    selected_rse_replica = random.choice(replicas_by_rse[selected_rse])
    access_url = selected_rse_replica

    # Select one random service per service type for the selected RSE,
    selected_services = {}
    for stype in service_types:
        services_list = services_by_rse.get(stype, {}).get(selected_rse, [])
        if services_list:
            selected_services[stype] = random.choice(services_list)
        else:
            selected_services[stype] = None

    # Build a dictionary with extracted service info for the template
    services_info = {
        stype: build_service_info(service)
        for stype, service in selected_services.items()
        if service is not None
    }

    include_services_flags = {
        stype: (selected_services.get(stype) is not None)
        for stype in service_types
    }

    return templates.TemplateResponse(
        "datalink.template.xml",
        {
            "request": request,
            "ivoa_authority": config.get('IVOA_AUTHORITY'),
            # FIXME: this doesn't necessarily work for non-deterministic
            "path_on_storage": "{}/{}".format(
                scope,
                access_url.split(scope)[1].lstrip('/')),
            "access_url": access_url,
            "description": metadata.get('obs_id', ''),
            "content_type": metadata.get('content_type', ''),
            "content_length": metadata.get('content_length', ''),
            "datalinks": ast.literal_eval(metadata.get('datalinks', '[]')),
            "services": services_info,
            "include_services_flags": include_services_flags,
        },
        media_type="application/xml"
    )
