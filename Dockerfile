FROM spear/pipeline:latest
COPY entrypoint.sh /entrypoint.sh
COPY cleanup.sh /cleanup.sh

ENTRYPOINT ["/entrypoint.sh"]
