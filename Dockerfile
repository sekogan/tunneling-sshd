FROM alpine:3.7

RUN apk add --update --no-cache openssh

COPY sshd_config /
COPY entrypoint.sh /

EXPOSE 22
CMD ["/bin/sh", "/entrypoint.sh"]
