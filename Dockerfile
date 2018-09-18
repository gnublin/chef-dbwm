FROM debian:stretch
LABEL maintainer="gauthier@openux.org"


# Install prerequisites
# RUN apt-get update && apt-get install -y \
# curl
# CMD /bin/bash
RUN mkdir /app
WORKDIR /app
COPY . .

RUN echo deb http://ftp.debian.org/debian stretch-backports main >> /etc/apt/sources.list
RUN apt update && apt install -y curl git gnupg1 gcc make
RUN apt update && apt install -y libssl-dev libreadline-dev zlib1g-dev
# RUN apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-compat-dev

# Install node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt update && apt install -y nodejs

RUN git clone https://github.com/rbenv/rbenv.git /opt/rbenv
RUN cd /opt/rbenv && src/configure && make -C src
RUN mkdir -p /opt/rbenv/plugins
RUN git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build

RUN apt-get clean

ENV PATH /opt/rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> /root/.bashrc
RUN /opt/rbenv/plugins/ruby-build/install.sh

RUN cat /dev/zero

RUN cd /app && rbenv rehash
RUN cd /app && rbenv install
RUN cd /app && gem install bundler
RUN cd /app && bundle install
RUN cd /app && npm install
RUN cd /app && bundle exec rackup -p 8081
