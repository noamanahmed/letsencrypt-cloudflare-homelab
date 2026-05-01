FROM alpine:latest

RUN apk add --no-cache bash certbot certbot-dns-cloudflare curl bind-tools openssl

WORKDIR /app

COPY bin /app/bin
COPY lib /app/lib
COPY hooks /app/hooks

RUN chmod +x /app/bin/lecf /app/lib/*.sh

ENTRYPOINT ["/app/bin/lecf"]
CMD ["run", "nginx"]
