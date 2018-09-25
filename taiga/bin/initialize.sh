#!/bin/bash
HOMEDIR=/home/taiga
source ${HOMEDIR}/.profile

# Change directory to /home/taiga/taiga.
cd ${HOMEDIR}/taiga

# Build ./conf/taiga-back.py.
cat > ./src/taiga-back/settings/local.py <<EOF
from .common import *

DEBUG = False
PUBLIC_REGISTER_ENABLED = True
SECRET_KEY = "${TAIGA_SECRET}"
CELERY_ENABLED = True

MEDIA_URL = "${TAIGA_SCHEME}://${TAIGA_DOMAIN}/media/"
STATIC_URL = "${TAIGA_SCHEME}://${TAIGA_DOMAIN}/static/"
SITES["front"]["scheme"] = "${TAIGA_SCHEME}"
SITES["front"]["domain"] = "${TAIGA_DOMAIN}"

DEFAULT_FROM_EMAIL = "${TAIGA_EMAIL}"
SERVER_EMAIL = DEFAULT_FROM_EMAIL
ADMINS = (
    ("Admin", "${TAIGA_EMAIL}"),
)

EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://taiga:${TAIGA_PASSWORD}@localhost:5672/taiga"}

# Uncomment and populate with proper connection parameters
# for enable email sending. EMAIL_HOST_USER should end by @domain.tld
#EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
#EMAIL_USE_TLS = False
#EMAIL_HOST = "localhost"
#EMAIL_HOST_USER = ""
#EMAIL_HOST_PASSWORD = ""
#EMAIL_PORT = 25

# Uncomment and populate with proper connection parameters
# for enable github login/singin.
#GITHUB_API_CLIENT_ID = "yourgithubclientid"
#GITHUB_API_CLIENT_SECRET = "yourgithubclientsecret"
EOF
ln -s $(pwd)/src/taiga-back/settings/local.py ./conf/taiga-back.py

# Build ./conf/taiga-front.json.
cat > ./src/taiga-front-dist/dist/conf.json <<EOF
{
    "api": "http://${TAIGA_DOMAIN}/api/v1/",
    "eventsUrl": "ws://${TAIGA_DOMAIN}/events",
    "eventsMaxMissedHeartbeats": 5,
    "eventsHeartbeatIntervalTime": 60000,
    "eventsReconnectTryInterval": 10000,
    "debug": true,
    "debugInfo": false,
    "defaultLanguage": "en",
    "themes": ["taiga"],
    "defaultTheme": "taiga",
    "publicRegisterEnabled": true,
    "feedbackEnabled": true,
    "supportUrl": "https://tree.taiga.io/support",
    "privacyPolicyUrl": null,
    "termsOfServiceUrl": null,
    "GDPRUrl": null,
    "maxUploadFileSize": null,
    "contribPlugins": [],
    "tribeHost": null,
    "importers": [],
    "gravatar": false,
    "rtlLanguages": ["fa"]
}
EOF
ln -s $(pwd)/src/taiga-front-dist/dist/conf.json ./conf/taiga-front.json

# Build ./conf/taiga-events.json.
cat > ./src/taiga-events/config.json <<EOF
{
    "url": "amqp://taiga:${TAIGA_PASSWORD}@localhost:5672/taiga",
    "secret": "${TAIGA_SECRET}",
    "webSocketServer": {
        "port": 8888
    }
}
EOF
ln -s $(pwd)/src/taiga-events/config.json ./conf/taiga-events.json

# Build ./conf/circus-back.ini.
cat >> /etc/circus/conf.d/circus-back.ini <<EOF
[watcher:taiga]
working_dir = $(pwd)/src/taiga-back
cmd = gunicorn
args = -w 3 -t 60 --pythonpath=. -b 127.0.0.1:8001 taiga.wsgi
uid = taiga
numprocesses = 1
autostart = true
send_hup = true
stdout_stream.class = FileStream
stdout_stream.filename = $(pwd)/log/taiga-back.stdout.log
stdout_stream.max_bytes = 10485760
stdout_stream.backup_count = 4
stderr_stream.class = FileStream
stderr_stream.filename = $(pwd)/log/taiga-back.stderr.log
stderr_stream.max_bytes = 10485760
stderr_stream.backup_count = 4

[env:taiga]
PATH = ${HOMEDIR}/.virtualenvs/taiga/bin:\$PATH
TERM=rxvt-256color
SHELL=/bin/bash
USER=taiga
LANG=en_US.UTF-8
HOME=${HOMEDIR}
PYTHONPATH=$(cd ${HOMEDIR}/.virtualenvs/taiga/lib/*/site-packages && pwd)
EOF
ln -s /etc/circus/conf.d/circus-back.ini ./conf/circus-back.ini

# Build ./conf/circus-celery.ini.
cat >> /etc/circus/conf.d/circus-celery.ini <<EOF
[watcher:taiga-celery]
working_dir = $(pwd)/src/taiga-back
cmd = celery
args = -A taiga worker -c 4
uid = taiga
numprocesses = 1
autostart = true
send_hup = true
stdout_stream.class = FileStream
stdout_stream.filename = $(pwd)/log/taiga-celery.stdout.log
stdout_stream.max_bytes = 10485760
stdout_stream.backup_count = 4
stderr_stream.class = FileStream
stderr_stream.filename = $(pwd)/log/taiga-celery.stderr.log
stderr_stream.max_bytes = 10485760
stderr_stream.backup_count = 4

[env:taiga-celery]
PATH = ${HOMEDIR}/.virtualenvs/taiga/bin:\$PATH
TERM=rxvt-256color
SHELL=/bin/bash
USER=taiga
LANG=en_US.UTF-8
HOME=${HOMEDIR}
PYTHONPATH=$(cd ${HOMEDIR}/.virtualenvs/taiga/lib/*/site-packages && pwd)
EOF
ln -s /etc/circus/conf.d/circus-celery.ini ./conf/circus-celery.ini

# Build ./conf/circus-events.ini.
cat >> /etc/circus/conf.d/circus-events.ini <<EOF
[watcher:taiga-events]
working_dir = $(pwd)/src/taiga-events
cmd = coffee
args = index.coffee
uid = taiga
numprocesses = 1
autostart = true
send_hup = true
stdout_stream.class = FileStream
stdout_stream.filename = $(pwd)/log/taiga-events.stdout.log
stdout_stream.max_bytes = 10485760
stdout_stream.backup_count = 12
stderr_stream.class = FileStream
stderr_stream.filename = $(pwd)/log/taiga-events.stderr.log
stderr_stream.max_bytes = 10485760
stderr_stream.backup_count = 12
EOF
ln -s /etc/circus/conf.d/circus-events.ini ./conf/circus-events.ini

# Build ./conf/nginx.conf.
cat >> /etc/nginx/conf.d/taiga.conf <<EOF
server {
    listen 80 default_server;
    server_name _;

    large_client_header_buffers 4 32k;
    client_max_body_size 50M;
    charset utf-8;

    access_log $(pwd)/log/nginx.access.log;
    error_log $(pwd)/log/nginx.error.log;

    # Frontend
    location / {
        root $(pwd)/src/taiga-front-dist/dist/;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend
    location /api {
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8001/api;
        proxy_redirect off;
    }

    # Django admin access (/admin/)
    location /admin {
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8001\$request_uri;
        proxy_redirect off;
    }

    # Static files
    location /static {
        alias $(pwd)/src/taiga-back/static;
    }

    # Media files
    location /media {
        alias $(pwd)/src/taiga-back/media;
    }

    # Taiga-events
    location /events {
        proxy_pass http://127.0.0.1:8888/events;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
EOF
ln -s /etc/nginx/conf.d/taiga.conf ./conf/nginx.conf

grep -n '' ./conf/*
