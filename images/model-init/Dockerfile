FROM alpine:3.22

RUN apk add --no-cache bash curl
COPY init-models.sh /usr/local/bin/init-models.sh
RUN chmod +x /usr/local/bin/init-models.sh

ENTRYPOINT ["/usr/local/bin/init-models.sh"]

