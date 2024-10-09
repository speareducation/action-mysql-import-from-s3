FROM alpine:latest

RUN set -xe && \
	apk add bash openssh python3 curl git mysql-client pv jq aws-cli

COPY entrypoint.sh /entrypoint.sh
COPY post-entrypoint.sh /post-entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
