# webhook

A minimal Docker image that combines [adnanh/webhook](https://github.com/adnanh/webhook) with the [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) (including the Compose plugin). Intended for self-hosted setups where a webhook receiver needs to trigger Docker operations — for example, redeploying a container when a new image is pushed to a registry.

The image is built and pushed to `ghcr.io/dzd-ev-diabetes-research/webhook:latest` via GitHub Actions on every push to `main`.

## Usage

Mount the Docker socket and a hook script, then generate `hooks.json` and start the webhook server:

```yaml
services:
  webhook:
    image: ghcr.io/dzd-ev-diabetes-research/webhook:latest
    entrypoint: ["/bin/sh", "-c"]
    command: >
      chmod +x /scripts/update.sh &&
      printf '[{"id":"update-%s","execute-command":"/scripts/update.sh","command-working-directory":"/","include-command-output-in-response":true,"trigger-rule":{"match":{"type":"value","value":"%s","parameter":{"source":"payload","name":"push_data.tag"}}}}]\n'
      "$WEBHOOK_TOKEN" "$WATCH_TAG" > /tmp/hooks.json &&
      exec webhook -hooks /tmp/hooks.json -verbose -port 9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./update.sh:/scripts/update.sh:ro
      - .:/compose:ro
    environment:
      WEBHOOK_TOKEN: "your-secret-token"
      WATCH_TAG: "latest"
      COMPOSE_PROJECT_NAME: "your-project"
```

The webhook will be reachable at `POST /hooks/update-<WEBHOOK_TOKEN>`. Requests where `push_data.tag` does not match `WATCH_TAG` are silently ignored.

A minimal `update.sh`:

```bash
#!/bin/sh
set -e
docker compose -f /compose/docker-compose.yml pull
docker compose -f /compose/docker-compose.yml up -d --no-deps --force-recreate <service> <service>
```

## Updating

This image is not rebuilt automatically. To pick up upstream changes from either base image, update this repository — the pipeline will rebuild and push.
