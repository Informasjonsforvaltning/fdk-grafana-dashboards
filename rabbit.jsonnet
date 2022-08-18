// https://grafana.com/grafana/dashboards/10991-rabbitmq-overview/
local rabbit = (import 'rabbit.json');

local patch = {
  templating: {
    list: rabbit.templating.list + [{
      hide: 2,
      name: 'DS_PROMETHEUS',
      query: 'prometheus',
      skipUrlSync: false,
      type: 'constant',
    }],
  },
};

std.mergePatch(rabbit, patch)
