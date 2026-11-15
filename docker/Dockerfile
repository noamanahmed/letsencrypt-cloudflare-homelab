FROM alpine:latest

RUN apk add --no-cache bash certbot certbot-dns-cloudflare curl bind-tools openssl

WORKDIR /app

COPY bin /app/bin
COPY lib /app/lib
COPY hooks /app/hooks

RUN chmod +x /app/bin/lecf /app/lib/*.sh \
    && ln -s /app/bin/lecf /usr/local/bin/lecf

ENTRYPOINT ["/app/bin/lecf"]
CMD ["run", "nginx"]
