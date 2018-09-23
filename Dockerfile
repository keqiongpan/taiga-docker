# Use an official Python runtime as a parent image.
FROM ubuntu

# Set the working directory to root-directory.
WORKDIR /

# Update apt sources to http://mirrors.aliyun.com/ubuntu/ .
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
RUN cat /etc/apt/sources.list | \
    sed 's#\(http\|https\)://[^/]*/ubuntu/#http://mirrors.aliyun.com/ubuntu/#g' \
    > /etc/apt/sources.list.aliyun
RUN mv /etc/apt/sources.list.aliyun /etc/apt/sources.list

# Install Basic Tools.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y sudo

# Install tzdata with Asia/Shanghai.
RUN apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
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
