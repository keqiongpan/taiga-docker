#!/bin/bash

if [ -f ~/.bashrc ]
  then
    source ~/.bashrc
  fi

if [ -f ~/.profile ]
  then
    source ~/.profile
  fi

WORKDIR=/home/taiga/taiga
INITIALIZE=0
cd "${WORKDIR}"

if [ ! -f ./conf/nginx.conf ]
  then
    INITIALIZE=1
    ./bin/initialize.sh
  fi

# Startup redis with default config.
service redis-server start

# Configure postgresql with the initial user and database.
service postgresql start
if [ $INITIALIZE -ne 0 ]
  then
    sudo -u postgres createuser taiga
    sudo -u postgres createdb taiga -O taiga --encoding='utf-8' --locale=POSIX --template=template0
  fi

# Create a user named taiga, and a virtualhost for RabbitMQ (taiga-events).
service rabbitmq-server start
if [ $INITIALIZE -ne 0 ]
  then
    rabbitmqctl add_user taiga "${TAIGA_PASSWORD}"
    rabbitmqctl add_vhost taiga
    rabbitmqctl set_permissions -p taiga taiga ".*" ".*" ".*"
  fi

# Setup basic data.
if [ $INITIALIZE -ne 0 ]
  then
    su - taiga -c '/bin/bash -ic " \
                   cd /home/taiga/taiga/src/taiga-back && \
                   workon taiga && \
                   python manage.py migrate --noinput && \
                   python manage.py loaddata initial_user && \
                   python manage.py loaddata initial_project_templates && \
                   python manage.py compilemessages && \
                   python manage.py collectstatic --noinput"'
  fi

# # Setup sample data.
# if [ $INITIALIZE -ne 0 ]
#   then
#     su - taiga -c '/bin/bash -ic " \
#                    cd /home/taiga/taiga/src/taiga-back && \
#                    workon taiga && \
#                    python manage.py sample_data"'
#   fi

# Startup mail service.
service postfix start

# Startup taiga-back & taiga-events by circusd.
service circusd start

# Startup taiga-front-dist by nginx.
service nginx start

# Show all services's status.
service --status-all

# Show usage information.
cat <<EOF
================================================================
Startup Finished!!

Docker environment variable:
$(env | grep '^TAIGA_')

Docker available volume paths:
$(cd ./src/taiga-back/static && pwd)
$(cd ./src/taiga-back/media && pwd)
$(cd /var/lib/postgresql && pwd)

Now, you can visit taiga via ${TAIGA_SCHEME}://${TAIGA_DOMAIN}/.
The taiga's administrator account initialize with admin/123123.
================================================================
EOF
