{
  grafanaDashboards:: {
    http: (import 'http.jsonnet'),
    kafka: (import 'kafka.jsonnet'),
    rabbit: (import 'rabbit.jsonnet'),
    trivy: (import 'trivy.jsonnet'),
  },
}
