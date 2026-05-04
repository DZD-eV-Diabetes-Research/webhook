FROM alpine:3.21 AS downloader
RUN wget -qO /tmp/webhook.tar.gz \
      https://github.com/adnanh/webhook/releases/latest/download/webhook-linux-amd64.tar.gz && \
    tar xzf /tmp/webhook.tar.gz -C /tmp/ && \
    cp /tmp/webhook-linux-amd64/webhook /usr/local/bin/webhook && \
    chmod +x /usr/local/bin/webhook

FROM docker:cli
COPY --from=downloader /usr/local/bin/webhook /usr/local/bin/webhook
