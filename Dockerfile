FROM spear/pipeline:latest
COPY entrypoint.sh /entrypoint.sh
COPY post-entrypoint.sh /post-entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
