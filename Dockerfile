# Use an official Python runtime as a parent image.
FROM ubuntu

# Set the working directory to root-directory.
WORKDIR /

# Update apt source to http://mirrors.aliyun.com/ubuntu/.
ENV DEBIAN_APTSOURCE http://mirrors.aliyun.com/ubuntu/
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
RUN cat /etc/apt/sources.list | \
    sed "s#\\(http\\|https\\)://[^/]*/ubuntu/\\?#${DEBIAN_APTSOURCE}#g" \
    > /etc/apt/sources.list.aliyun
RUN mv /etc/apt/sources.list.aliyun /etc/apt/sources.list

# Install Basic Tools.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y sudo
RUN apt-get install -y vim

# Install tzdata with Asia/Shanghai.
ENV DEBIAN_TIMEZONE Asia/Shanghai
RUN apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/${DEBIAN_TIMEZONE} /etc/localtime
RUN dpkg-reconfigure -f noninteractive tzdata

# Install Essential packages.
RUN apt-get install -y build-essential binutils-doc autoconf flex bison libjpeg-dev
RUN apt-get install -y libfreetype6-dev zlib1g-dev libzmq3-dev libgdbm-dev libncurses5-dev
RUN apt-get install -y automake libtool libffi-dev curl git tmux gettext
RUN apt-get install -y nginx
RUN apt-get install -y rabbitmq-server redis-server
RUN apt-get install -y circus

# The component taiga-back uses postgresql (>= 9.4) as database.
RUN apt-get install -y postgresql postgresql-contrib
RUN apt-get install -y postgresql-doc postgresql-server-dev-10

# Python (3.5) and virtualenvwrapper must be installed along with a few third-party libraries.
RUN apt-get install -y python3 python3-pip python-dev python3-dev python-pip virtualenvwrapper
RUN apt-get install -y libxml2-dev libxslt-dev
RUN apt-get install -y libssl-dev libffi-dev

# Create a user named taiga, and give it root permissions.
RUN useradd -ms /bin/bash taiga
RUN adduser taiga sudo

# Configure postgresql with the initial user and database.
RUN service postgresql start && \
    sudo -u postgres createuser taiga && \
    sudo -u postgres createdb taiga -O taiga --encoding='utf-8' --locale=POSIX --template=template0

# Create a user named taiga, and a virtualhost for RabbitMQ (taiga-events).
ENV PASSWORD_FOR_EVENTS taiga
RUN service rabbitmq-server start && \
    rabbitmqctl add_user taiga "${PASSWORD_FOR_EVENTS}" && \
    rabbitmqctl add_vhost taiga && \
    rabbitmqctl set_permissions -p taiga taiga ".*" ".*" ".*"

# Create the taiga folders.
USER taiga
RUN mkdir -p /home/taiga/taiga/log /home/taiga/taiga/conf /home/taiga/taiga/src
WORKDIR /home/taiga/taiga/src

# Download taiga-back sources.
RUN git clone https://github.com/taigaio/taiga-back.git taiga-back
RUN cd ./taiga-back && git checkout stable

# Setup taiga-back.
USER root
RUN su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && mkvirtualenv -p /usr/bin/python3 taiga"'
RUN su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && workon taiga && pip install -r requirements.txt && pip install psycopg2-binary"'
RUN service postgresql start && \
    su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && workon taiga && python manage.py migrate --noinput && python manage.py loaddata initial_user && python manage.py loaddata initial_project_templates && python manage.py compilemessages && python manage.py collectstatic --noinput"'

# Setup sample data.
#RUN service postgresql start && \
#    su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && workon taiga && python manage.py sample_data"'

# Sets entry-point to bash.
ENTRYPOINT ["/bin/bash"]
