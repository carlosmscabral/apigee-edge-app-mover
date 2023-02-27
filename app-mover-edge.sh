#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export APP_NAME=testapp
export ORG=amer-demo69
export CURRENT_DEV=josedev@google.com
export NEW_DEV=josedev2@google.com

# Make sure get_token is installed 

# curl https://login.apigee.com/resources/scripts/sso-cli/ssocli-bundle.zip -O 
# unzip ssocli-bundle.zip
# sudo ./install -b /usr/local/bin   
# export SSO_LOGIN_URL=https://login.apigee.com
# get_token

# Export current app
curl -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$CURRENT_DEV/apps/$APP_NAME > export_app.json

# Delete current app (app keys are unique in a given org)
curl -X DELETE -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$CURRENT_DEV/apps/$APP_NAME 

# Remove the credentials object
sanitized_export_app=$(cat export_app.json | jq 'del(.credentials)')

# Import the app without credentials first, save the ouput
curl -X POST -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$NEW_DEV/apps -d $sanitized_export_app -H "Content-Type: application/json" > new_app.json

# Parse variables
auto_created_key=$(cat new_app.json | jq -r '.credentials[] | .consumerKey')
api_products=$(cat export_app.json | jq '{ "apiProducts" : [ .credentials[].apiProducts[].apiproduct ] }')
key_and_secret=$(cat export_app.json | jq '.credentials[] | {consumerKey,consumerSecret}') 
consumer_key_string=$(cat export_app.json | jq -r '.credentials[] | .consumerKey')

# Import Credentials
curl -X POST -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$NEW_DEV/apps/$APP_NAME/keys/create -d "$key_and_secret" -H "Content-Type: application/json"

# Associate products
curl -X POST -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$NEW_DEV/apps/$APP_NAME/keys/$consumer_key_string -H "Content-Type: application/json" -d $api_products

# Delete auto generated keys
curl -X DELETE -H "Authorization: Bearer $(get_token)" \
https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/$NEW_DEV/apps/$APP_NAME/keys/$auto_created_key