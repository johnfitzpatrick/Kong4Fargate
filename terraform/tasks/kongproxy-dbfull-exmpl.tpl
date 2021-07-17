[
  {
    "essential": false,
    "name": "kong-db-task-bootstrap",
    "image": "kong/kong-gateway:2.3.3.2-alpine",
    "entrypoint": [
      "/docker-entrypoint.sh"
    ],
    "command": [
      "kong",
      "migrations",
      "bootstrap",
      "--vv",
      "-y",
      ";echo;",
      "kong",
      "migrations",
      "list"
    ],
    "healthCheck": {
      "command": [
        "CMD-SHELL",
        "echo"
      ],
      "startPeriod": 5,
      "interval": 10,
      "timeout": 5,
      "retries": 3
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "/ecs/${stack_name}"
      }
    },
    "environment": [
      {
        "name": "KONG_PG_USER",
        "value": "${KONG_PG_USER}"
      },
      {
        "name": "KONG_PG_SSL_VERIFY",
        "value": "${KONG_PG_SSL_VERIFY}"
      },
      {
        "name": "KONG_PG_PORT",
        "value": "${KONG_PG_PORT}"
      },
      {
        "name": "KONG_PG_HOST",
        "value": "${KONG_PG_HOST}"
      },
      {
        "name": "KONG_PG_PASSWORD",
        "value": "${KONG_PG_PASSWORD}"
      },
      {
        "name": "KONG_PG_DATABASE",
        "value": "${KONG_PG_DATABASE}"
      },
      {
        "name": "KONG_DATABASE",
        "value": "${KONG_DATABASE}"
      },
      {
        "name": "KONG_KIC",
        "value": "off"
      },
      {
        "name": "KONG_LOG_LEVEL",
        "value": "debug"
      },
      {
        "name": "KONG_PLUGINS",
        "value": "${KONG_PLUGINS}"
      },
      {
        "name": "KONG_SMTP_MOCK",
        "value": "on"
      },
      {
        "name": "KONG_CLUSTER_LISTEN",
        "value": "off"
      },
      {
        "name": "KONG_STREAM_LISTEN",
        "value": "off"
      },
      {
        "name": "KONG_CLUSTER_TELEMETRY_LISTEN",
        "value": "off"
      },
      {
        "name": "KONG_PORT_MAPS",
        "value": "80:8080, 443:8443"
      },
      {
        "name": "KONG_ADMIN_LISTEN",
        "value": "0.0.0.0:8444 http2 ssl"
      },
      {
        "name": "KONG_STATUS_LISTEN",
        "value": "0.0.0.0:8100"
      },
      {
       "name": "KONG_PROXY_LISTEN",
        "value": "0.0.0.0:8001, 0.0.0.0:8443 http2 ssl"
      },
      {
        "name": "KONG_ADMIN_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PROXY_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PROXY_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_GUI_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PORTAL_API_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PORTAL_API_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_GUI_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_NGINX_WORKER_PROCESSES",
        "value": "${KONG_NGINX_WORKER_PROCESSES}"
      },
      {
        "name": "KONG_LUA_PACKAGE_PATH",
        "value": "/opt/?.lua;/opt/?/init.lua;;"
      }
    ],
    "secrets": [
      {
        "name": "KONG_LICENSE_DATA",
        "valueFrom": "arn:aws:secretsmanager:us-east-2:761729409112:secret:xccp-upsell-service-flask-dev-JjXG5b:license::"
      }
    ]
  },
  {
    "environment": [
      {
        "name": "KONG_PG_USER",
        "value": "${KONG_PG_USER}"
      },
      {
        "name": "KONG_PG_SSL_VERIFY",
        "value": "${KONG_PG_SSL_VERIFY}"
      },
      {
        "name": "KONG_PG_PORT",
        "value": "${KONG_PG_PORT}"
      },
      {
        "name": "KONG_PG_HOST",
        "value": "${KONG_PG_HOST}"
      },
      {
        "name": "KONG_PG_PASSWORD",
        "value": "${KONG_PG_PASSWORD}"
      },
      {
        "name": "KONG_PG_DATABASE",
        "value": "${KONG_PG_DATABASE}"
      },
      {
        "name": "KONG_DATABASE",
        "value": "${KONG_DATABASE}"
      },
      {
        "name": "KONG_KIC",
        "value": "off"
      },
      {
        "name": "KONG_PLUGINS",
        "value": "${KONG_PLUGINS}"
      },
      {
        "name": "KONG_SMTP_MOCK",
        "value": "on"
      },
      {
        "name": "KONG_CLUSTER_TELEMETRY_LISTEN",
        "value": "off"
      },
      {
        "name": "KONG_CLUSTER_TELEMETRY_LISTEN",
        "value": "off"
      },
      {
        "name": "KONG_NGINX_DAEMON",
        "value": "${KONG_NGINX_DAEMON}"
      },
      {
        "name": "KONG_CLUSTER_LISTEN",
        "value": "${KONG_CLUSTER_LISTEN}"
      },
      {
        "name": "KONG_STREAM_LISTEN",
        "value": "${KONG_STREAM_LISTEN}"
      },
      {
        "name": "KONG_PORT_MAPS",
        "value": "80:8000, 443:8443"
      },
      {
        "name": "KONG_ADMIN_LISTEN",
        "value": "0.0.0.0:8444 http2 ssl"
      },
      {
        "name": "KONG_STATUS_LISTEN",
        "value": "0.0.0.0:8100"
      },
      {
        "name": "KONG_PROXY_LISTEN",
        "value": "0.0.0.0:8001, 0.0.0.0:8443 http2 ssl"
      },
      {
        "name": "KONG_ADMIN_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PROXY_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PROXY_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_GUI_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PORTAL_API_ERROR_LOG",
        "value": "/dev/stderr"
      },
      {
        "name": "KONG_PORTAL_API_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_ADMIN_GUI_ACCESS_LOG",
        "value": "/dev/stdout"
      },
      {
        "name": "KONG_NGINX_WORKER_PROCESSES",
        "value": "${KONG_NGINX_WORKER_PROCESSES}"
      },
      {
        "name": "KONG_LUA_PACKAGE_PATH",
        "value": "/opt/?.lua;/opt/?/init.lua;;"
      }
    ],
    "essential": true,
    "image": "kong/kong-gateway:2.3.3.2-alpine",
    "name": "${container_name}",
    "secrets": [
      {
        "name": "KONG_LICENSE_DATA",
        "valueFrom": "arn:aws:secretsmanager:us-east-2:761729409112:secret:xccp-upsell-service-flask-dev-JjXG5b:license::"
      }
    ],
    "entrypoint": [
      "/docker-entrypoint.sh"
    ],
    "command": [
      "kong",
      "docker-start"
    ],
    "healthCheck": {
      "command": [
        "CMD-SHELL",
        "/usr/local/bin/kong health"
      ],
      "startPeriod": 5,
      "interval": 10,
      "timeout": 5,
      "retries": 3
    },
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      },
