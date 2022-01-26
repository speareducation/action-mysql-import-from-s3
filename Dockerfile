FROM alpine:3:11

spear/pipeline:latest

RUN set -xe && \
	apk add bash openssh python3 curl git mysql-client pv jq

RUN set -xe && \
	pip3 install awscli

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
