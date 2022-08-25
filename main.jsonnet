{
  grafanaDashboards:: {
    elasticsearch: (import 'elasticsearch.jsonnet'),
    http: (import 'http.jsonnet'),
    kafka: (import 'kafka.jsonnet'),
    nginx: (import 'nginx.jsonnet'),
    rabbit: (import 'rabbit.jsonnet'),
    trivy: (import 'trivy.jsonnet'),
  },
}
