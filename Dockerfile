# Use an official Python runtime as a parent image.
FROM ubuntu
MAINTAINER keqiongpan@163.com

# Set environment variable default values.
ENV TAIGA_SCHEME http
ENV TAIGA_DOMAIN yourdomain.com
ENV TAIGA_EMAIL system@taiga.io
ENV TAIGA_SECRET taiga
ENV TAIGA_PASSWORD taiga

# Expose nginx ports.
EXPOSE 80/tcp

# Set the working directory to root-directory.
WORKDIR /

# Update apt source to http://mirrors.aliyun.com/ubuntu/.
ENV DEBIAN_APTSOURCE http://mirrors.aliyun.com/ubuntu/
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
RUN sed -i "s#\\(http\\|https\\)://[^/]*/ubuntu/\\?#${DEBIAN_APTSOURCE}#g" /etc/apt/sources.list

# Install Basic Tools.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y sudo inetutils-tools telnet ftp vsftpd openssh-client openssh-server vim

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
RUN apt-get install -y postfix mailutils

# The component taiga-back uses postgresql (>= 9.4) as database.
RUN apt-get install -y postgresql postgresql-contrib
RUN apt-get install -y postgresql-doc postgresql-server-dev-10

# Python (3.5) and virtualenvwrapper must be installed along with a few third-party libraries.
RUN apt-get install -y python3 python3-pip python-dev python3-dev python-pip virtualenvwrapper
RUN apt-get install -y libxml2-dev libxslt-dev
RUN apt-get install -y libssl-dev libffi-dev

# Install nodejs.
RUN apt-get install -y nodejs npm
RUN npm install -g coffeescript

# Create a user named taiga, and give it root permissions.
RUN useradd -ms /bin/bash taiga
RUN adduser taiga sudo

# Create the taiga folders.
USER taiga
RUN mkdir -p /home/taiga/taiga/bin /home/taiga/taiga/conf /home/taiga/taiga/log /home/taiga/taiga/src
WORKDIR /home/taiga/taiga/src

# Download taiga-back sources.
RUN git clone https://github.com/taigaio/taiga-back.git taiga-back
RUN cd ./taiga-back && git checkout stable

# Download taiga-front-dist sources.
RUN git clone https://github.com/taigaio/taiga-front-dist.git taiga-front-dist
RUN cd ./taiga-front-dist && git checkout stable

# Download taiga-events sources.
RUN git clone https://github.com/taigaio/taiga-events.git taiga-events
RUN cd ./taiga-events && npm install

# Setup taiga-back.
USER root
RUN su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && mkvirtualenv -p /usr/bin/python3 taiga"'
RUN su - taiga -c '/bin/bash -ic "cd /home/taiga/taiga/src/taiga-back && workon taiga && pip install -r requirements.txt && pip install psycopg2-binary"'

# Grant to taiga.
RUN chmod 777 /etc/circus/conf.d
RUN chmod 777 /etc/nginx/conf.d
RUN rm -f /etc/nginx/sites-enabled/default
RUN sed -i 's/^[[:space:]]*bind[[:space:]]*.*$/bind 127.0.0.1/g' /etc/redis/redis.conf

# Copy taiga predefine files.
USER taiga
WORKDIR /home/taiga/taiga
COPY ./taiga ./

# Sets entry-point to bash.
USER root
WORKDIR /home/taiga/taiga
CMD ./bin/startup.sh && bash
