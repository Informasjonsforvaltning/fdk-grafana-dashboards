{
  grafanaDashboards:: {
    elasticsearch: (import 'elasticsearch.jsonnet'),
    http: (import 'http.jsonnet'),
    blackbox: (import 'blackbox.jsonnet'),
    harvest: (import 'harvest.jsonnet'),
    reasoning: (import 'reasoning.jsonnet'),
    rdfparsing: (import 'rdfparsing.jsonnet'),
    kafka: (import 'kafka.jsonnet'),
    mqa: (import 'mqa.jsonnet'),
    nginx: (import 'nginx.jsonnet'),
    rabbit: (import 'rabbit.jsonnet'),
    search: (import 'search.jsonnet'),
    trivy: (import 'trivy.jsonnet'),
  },
}
