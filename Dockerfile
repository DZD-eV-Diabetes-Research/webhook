FROM adnanh/webhook:latest AS webhook-binary
FROM docker:cli
COPY --from=webhook-binary /usr/local/bin/webhook /usr/local/bin/webhook
