# FDK Grafana Dashboards

Collection of Grafana dashboards
written in [jsonnet](https://jsonnet.org)
using [grafonnet](https://grafana.github.io/grafonnet-lib)
and deployed with [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
and [grizzly](https://grafana.github.io/grizzly).

```bash
jb install
export GRAFANA_URL=http://localhost:3000
export GRAFANA_TOKEN=eyJrIjoiaUNVWjk4VGVzZTMwUm52TmFrcUczb3ZZemZMeVdVNDIiLCJuIjoiYSIsImlkIjoxfQo=
grr apply main.jsonnet
```
