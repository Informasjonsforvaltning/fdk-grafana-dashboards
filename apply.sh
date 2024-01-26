#!/bin/sh

printf "FDK Grafana Dashboards\n\n"
printf "Loading environment variables\n"
if [ -f .env ]
then
    export $(cat .env | xargs)
fi

export GRAFANA_URL="${GRAFANA_SCHEME}://${GRAFANA_HOST}"
printf "Connecting to Grafana at ${GRAFANA_URL} as ${GRAFANA_ADMIN_USER}...\n"

while ! curl "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts/search" -s > /dev/null && echo ...; do sleep 1; done
printf "Connected to Grafana\n"

printf "Creating access token\n"
export SERVICE_ACCOUNT=$(curl -X GET "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts/search?query=grafonnet" -s | jq -r '.serviceAccounts[0].id')
if [ "null" = "$SERVICE_ACCOUNT" ]
then
  export SERVICE_ACCOUNT=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"grafonnet", "role": "Admin", "isDisabled": false}' "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts" -s | jq -r '.id')  
fi

if [ "null" = "$SERVICE_ACCOUNT" ]
then
  printf "ERROR: Failed to create service account\n"
  exit 1
else 
  printf "Using service account with id ${SERVICE_ACCOUNT}\n"
fi
export TOKENS=$(curl -X GET "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts/${SERVICE_ACCOUNT}/tokens" -s | jq -r)
for item in $(echo "${TOKENS}" | jq -r '.[].id'); do
  curl -X DELETE "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts/${SERVICE_ACCOUNT}/tokens/${item}" -s > /dev/null
done

export GRAFANA_TOKEN=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"grafonnet"}' "${GRAFANA_SCHEME}://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST}/api/serviceaccounts/${SERVICE_ACCOUNT}/tokens" -s | jq -r .key)
if [ "null" = "$GRAFANA_TOKEN" ]
then
    printf "ERROR: Failed to create access token\n"
    exit 1
else
    printf "Created access token\n"
fi

printf "Create Prometheus datasource\n"
curl -X POST -s -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_TOKEN" -d "{\"uid\":\"prometheus\",\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"$PROMETHEUS_URL\",\"access\":\"proxy\",\"basicAuth\":true,\"basicAuthUser\":\"$BASIC_AUTH_USER\",\"secureJsonData\":{\"basicAuthPassword\":\"$BASIC_AUTH_PASSWORD\"}}" $GRAFANA_URL/api/datasources > /dev/null

printf "Install Grafonnet\n"
jb install

printf "Apply main.jsonnet\n\n"
grr apply main.jsonnet
