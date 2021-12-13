FROM spear/pipeline:latest
COPY import.sh /import.sh

ENTRYPOINT ["/import.sh"]
