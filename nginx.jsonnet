// https://grafana.com/grafana/dashboards/9614-nginx-ingress-controller/
local nginx = (import 'nginx.json');

local patch = {
  templating: {
    list: nginx.templating.list + [{
      hide: 2,
      name: 'DS_PROMETHEUS',
      query: 'prometheus',
      skipUrlSync: false,
      type: 'constant',
    }],
  },
};

std.mergePatch(nginx, patch)
