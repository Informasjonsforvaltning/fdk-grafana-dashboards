# FDK Grafana Dashboards

Collection of Grafana dashboards
written in [jsonnet](https://jsonnet.org)
using [grafonnet](https://grafana.github.io/grafonnet-lib)
and deployed with [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
and [grizzly](https://grafana.github.io/grizzly).

## Dashboard Development Tips

When developing dashboards, it is often helpfull to explore changes in the Grafana
GUI itself, and then find and update the corresponding fields in grafonnet code.

The supported field and methods are documented through docstrings in the GitHub
repo
[grafana/grafonnet-lib/grafonnet](https://github.com/grafana/grafonnet-lib/tree/master/grafonnet)
repo, e.g
[graph_panel.libsonnet](https://github.com/grafana/grafonnet-lib/blob/30280196507e0fe6fa978a3e0eaca3a62844f817/grafonnet/graph_panel.libsonnet#L6-L70).

## Development Through Previews

You may create a PR into `main` to trigger a preview of the changes, linked in a
PR comment.  
Although sufficient for small changes, the feedback loop between change and
result is quite slow. For frequent changes and continous visual updates, local
development is advised.

## Local Development

### Requirements

- [docker](https://docs.docker.com/engine/install/ubuntu)/[podman](https://podman.io/getting-started/installation)
- [jq](https://stedolan.github.io/jq)
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
- [grizzly](https://grafana.github.io/grizzly)

### Running Grafana With Docker

Define basic auth credentials for prometheus datasource in staging cluster:

```bash
export PROMETHEUS_URL=https://thanos.dev.fellesdatakatalog.digdir.no
export BASIC_AUTH_USER=<ask someone>
export BASIC_AUTH_PASSWORD=<ask someone>
```

Run Grafana with docker, wait for it to init, create an access token, configure
datasource from dev cluster:

```bash
docker run --rm -d -p 3000:3000 --name grafana grafana/grafana
export GRAFANA_HOST=localhost:3000
export GRAFANA_URL=http://${GRAFANA_HOST}
while ! curl "http://admin:admin@${GRAFANA_HOST}/api/auth/keys" -s && echo ...; do sleep 1; done
export GRAFANA_TOKEN=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' "http://admin:admin@${GRAFANA_HOST}/api/auth/keys" | jq -r .key)
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_TOKEN" -d "{\"uid\":\"prometheus\",\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"$PROMETHEUS_URL\",\"access\":\"proxy\",\"basicAuth\":true,\"basicAuthUser\":\"$BASIC_AUTH_USER\",\"secureJsonData\":{\"basicAuthPassword\":\"$BASIC_AUTH_PASSWORD\"}}" $GRAFANA_URL/api/datasources
```

### Apply Dashboards

Apply the dashboards and update on any saved changes:

```bash
jb install
grr apply main.jsonnet
grr watch . main.jsonnet
```

Any local code changes will now instantly be pushed to Grafana.

Open [http://localhost:3000](http://localhost:3000) and login with `admin`
`admin`.

Run `docker rm -f grafana` to stop Grafana.
