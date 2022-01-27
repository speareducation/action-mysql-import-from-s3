FROM alpine:3.11

RUN set -xe && \
	apk add bash openssh python3 curl git mysql-client pv jq

RUN set -xe && \
	pip3 install awscli

COPY entrypoint.sh /entrypoint.sh
COPY post-entrypoint.sh /post-entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
