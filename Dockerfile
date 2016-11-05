FROM crystallang/crystal

MAINTAINER "Blue Apron Engineering <engineering@blueapron.com>"

RUN mkdir -p /opt/saiyan/bin
WORKDIR /opt/saiyan/

ENV PATH /opt/saiyan/bin:$PATH

ARG GIT_COMMIT
ENV GIT_COMMIT $GIT_COMMIT

COPY . /opt/saiyan/

RUN shards install \
    && crystal build -o /opt/saiyan/bin/saiyan --release /opt/saiyan/src/saiyan.cr
