# https://docs.konghq.com/gateway-oss/2.4.x/configuration/#environment-variables
[{
  "essential": false,
  "name": "kong-dbtask-bootstrap",
  "image": "${image_kong_proxy}",
  "entryPoint": ["/docker-entrypoint.sh"],
  "command": ["kong", "migrations", "bootstrap", "--vv", "-y"],
  "healthCheck": {"command": ["CMD-SHELL","ping","google.com"],
    "startPeriod": 5,
    "interval": 10,
    "timeout": 5,
    "retries": 3
  },
  "logConfiguration": {
    "logDriver": "awslogs"
      "options": {
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "kong-proxy",
        "awslogs-group": "${aws_cloudwatch_group}-${environment}"
      },
  },
  "environment": [
      {"name": "KONG_DATABASE",                 "value": "${kong_database}"
    },{"name": "KONG_PG_PORT",                  "value": "${kong_pg_port}"
    },{"name": "KONG_PG_HOST",                  "value": "${kong_pg_host}"
    },{"name": "KONG_PG_USER",                  "value": "${kong_pg_user}"
    },{"name": "KONG_PG_PASSWORD",              "value": "${kong_pg_password}"
    },{"name": "KONG_PG_DATABASE",              "value": "${kong_pg_database}"
    },{"name": "KONG_PG_SSL_VERIFY",            "value": "${kong_pg_ssl_verify}"
    },{"name": "KONG_PLUGINS",                  "value": "bundled"
    },{"name": "KONG_STREAM_LISTEN",            "value": "off"
    },{"name": "KONG_CLUSTER_LISTEN",           "value": "off"
    },{"name": "KONG_PROXY_LISTEN",             "value": "0.0.0.0:${lb_tcp_http_listen_port}, 0.0.0.0:${lb_tcp_https_listen_port} http2 ssl"
    },{"name": "KONG_ADMIN_LISTEN",             "value": "0.0.0.0:${lb_tcp_admin_api_listen_port} http2 ssl"
    },{"name": "KONG_STATUS_LISTEN",            "value": "0.0.0.0:${lb_tcp_health_port}"
    },{"name": "KONG_ADMIN_GUI_LISTEN",         "value": "0.0.0.0:${lb_tcp_admin_gui_listen_port} http2 ssl"
    },{"name": "KONG_PORT_MAPS",                "value": "80:${lb_tcp_http_listen_port}, 443:${lb_tcp_https_listen_port}"
    },{"name": "KONG_CLUSTER_TELEMETRY_LISTEN", "value": "off"
    },{"name": "KONG_LUA_PACKAGE_PATH",         "value":"/opt/?.lua;/opt/?/init.lua;;"
    },{"name": "KONG_LICENSE_DATA_B64",         "value": "${kong_license_base64}"
    },{"name": "KONG_ADMIN_ERROR_LOG",          "value": "/dev/stdout"
    },{"name": "KONG_PROXY_ERROR_LOG",          "value": "/dev/stdout"
    },{"name": "KONG_PROXY_ACCESS_LOG",         "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_ACCESS_LOG",         "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_GUI_ERROR_LOG",      "value": "/dev/stdout"
    },{"name": "KONG_PORTAL_API_ERROR_LOG",     "value": "/dev/stdout"
    },{"name": "KONG_PORTAL_API_ACCESS_LOG",    "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_GUI_ACCESS_LOG",     "value": "/dev/stdout"
    },{"name": "KONG_NGINX_WORKER_PROCESSES",   "value": "auto"
    },{"name": "KONG_LOG_LEVEL",                "value": "${kong_log_level}"
    },{"name": "KONG_SMTP_MOCK",                "value": "on"
    },{"name": "KONG_KIC",                      "value": "off"
    }
  ]
 },
 {
  "essential": true,
  "name": "kong-proxy",
  "image": "${image_kong_proxy}",
  "entryPoint": ["/docker-entrypoint.sh"],
  "command": ["kong","docker-start"],
  "healthCheck": {
  "command": ["CMD-SHELL","/usr/local/bin/kong health"],
    "startPeriod": 5,
    "interval": 10,
    "timeout": 5,
    "retries": 3
  },
  "logConfiguration": {
    "logDriver": "awslogs"
    "options": {
      "awslogs-region": "${region}",
      "awslogs-stream-prefix": "kong-proxy",
      "awslogs-group": "${aws_cloudwatch_group}-${environment}"
    },
  },
  "portMappings": [
      {"containerPort": ${lb_tcp_health_port},"protocol": "tcp"
    },{"containerPort": ${lb_tcp_http_listen_port},"protocol": "tcp"
    },{"containerPort": ${lb_tcp_https_listen_port},"protocol": "tcp"
    },{"containerPort": ${lb_tcp_admin_api_listen_port},"protocol": "tcp"
    },{"containerPort": ${lb_tcp_admin_gui_listen_port},"protocol": "tcp"
    },{"containerPort": 8000,"protocol": "tcp"
    },{"containerPort": 8003,"protocol": "tcp"
    },{"containerPort": 8004,"protocol": "tcp"
    },{"containerPort": 8446,"protocol": "tcp"
    },{"containerPort": 8447,"protocol": "tcp"
    },{"containerPort": 10254,"protocol": "tcp"
    }
  ],
  "environment": [
      {"name": "KONG_DATABASE",                 "value": "${kong_database}"
    },{"name": "KONG_PG_PORT",                  "value": "${kong_pg_port}"
    },{"name": "KONG_PG_HOST",                  "value": "${kong_pg_host}"
    },{"name": "KONG_PG_USER",                  "value": "${kong_pg_user}"
    },{"name": "KONG_PG_PASSWORD",              "value": "${kong_pg_password}"
    },{"name": "KONG_PG_DATABASE",              "value": "${kong_pg_database}"
    },{"name": "KONG_PG_SSL_VERIFY",            "value": "${kong_pg_ssl_verify}"
    },{"name": "KONG_STREAM_LISTEN",            "value": "off"
    },{"name": "KONG_CLUSTER_LISTEN",           "value": "off"
    },{"name": "KONG_PROXY_LISTEN",             "value": "0.0.0.0:${lb_tcp_http_listen_port}, 0.0.0.0:${lb_tcp_https_listen_port} http2 ssl"
    },{"name": "KONG_ADMIN_LISTEN",             "value": "0.0.0.0:${lb_tcp_admin_api_listen_port} http2 ssl"
    },{"name": "KONG_STATUS_LISTEN",            "value": "0.0.0.0:${lb_tcp_health_port}"
    },{"name": "KONG_ADMIN_GUI_LISTEN",         "value": "0.0.0.0:${lb_tcp_admin_gui_listen_port} http2 ssl"
    },{"name": "KONG_PORT_MAPS",                "value": "80:${lb_tcp_http_listen_port}, 443:${lb_tcp_https_listen_port}"
    },{"name": "KONG_CLUSTER_TELEMETRY_LISTEN", "value": "off"
    },{"name": "KONG_LUA_PACKAGE_PATH",         "value":"/opt/?.lua;/opt/?/init.lua;;"
    },{"name": "KONG_LICENSE_DATA_B64",         "value": "${kong_license_base64}"
    },{"name": "KONG_ADMIN_ERROR_LOG",          "value": "/dev/stdout"
    },{"name": "KONG_PROXY_ERROR_LOG",          "value": "/dev/stdout"
    },{"name": "KONG_PROXY_ACCESS_LOG",         "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_ACCESS_LOG",         "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_GUI_ERROR_LOG",      "value": "/dev/stdout"
    },{"name": "KONG_PORTAL_API_ERROR_LOG",     "value": "/dev/stdout"
    },{"name": "KONG_PORTAL_API_ACCESS_LOG",    "value": "/dev/stdout"
    },{"name": "KONG_ADMIN_GUI_ACCESS_LOG",     "value": "/dev/stdout"
    },{"name": "KONG_NGINX_WORKER_PROCESSES",   "value": "auto"
    },{"name": "KONG_LOG_LEVEL",                "value": "${kong_log_level}"
    },{"name": "KONG_SMTP_MOCK",                "value": "on"
    },{"name": "KONG_PLUGINS",                  "value": "bundled"
    },{"name": "KONG_KIC",                      "value": "off"
    }
  }
]