# FDK Grafana Dashboards

Collection of Grafana dashboards
written in [jsonnet](https://jsonnet.org)
using [grafonnet](https://grafana.github.io/grafonnet-lib)
and deployed with [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
and [grizzly](https://grafana.github.io/grizzly).

## Development through previews

You may create a PR into `main` to trigger a preview of the changes, linked in a PR comment.  
Although sufficient for small changes, the feedback loop between change and
result is quite slow. For frequent changes and continous visual updates, local
development is advised.

## Local development

### Requirements

See links in intro for install instructions.

- kubectl
- docker
- jsonnet-bundler
- grizzly

### Running Grafana with docker

```bash
docker run --rm -d -p 3000:3000 --name grafana --net host grafana/grafana
export GRAFANA_HOST=localhost:3000
export GRAFANA_URL=http://${GRAFANA_HOST}
while ! curl "http://admin:admin@${GRAFANA_HOST}/api/auth/keys" -s && echo ...; do sleep 1; done
export GRAFANA_TOKEN=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' "http://admin:admin@${GRAFANA_HOST}/api/auth/keys" | jq -r .key)
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_TOKEN" -d "{\"uid\":\"prometheus\",\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://localhost:9090\",\"access\":\"proxy\",\"basicAuth\":false}" $GRAFANA_URL/api/datasources
```

### Port forwarding to thanos in running in kubernetes

In another terminal, port-forward to thanos-query-frontend, so that grafana can access metric data from the cluster:

```bash
kubectl get pods -n monitoring | grep thanos-query-frontend | awk '{print $1}' | xargs -i kubectl port-forward -n monitoring {} 9090:10902
```

### Apply dashboards

Then back to the original terminal, apply the dashboards and update on any saved changes:

```bash
jb install
grr apply main.jsonnet
grr watch . main.jsonnet
```

Then finally open [http://localhost:3000](http://localhost:3000) and login with
`admin` `admin`.
