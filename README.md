# dzdde/webhook

[![Docker Hub](https://img.shields.io/docker/v/dzdde/webhook?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/dzdde/webhook)

A minimal Docker image combining [adnanh/webhook](https://github.com/adnanh/webhook) with the [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) (including the Compose plugin).

Built for self-hosted setups where a webhook receiver needs to trigger Docker operations — for example, automatically redeploying a container when a new image is pushed to a registry.

```
docker pull dzdde/webhook:latest
```

## Usage

```yaml
services:
  webhook:
    image: dzdde/webhook:latest
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

The webhook endpoint is: `POST /hooks/update-<WEBHOOK_TOKEN>`

Requests where `push_data.tag` does not match `WATCH_TAG` are ignored — useful for watching a specific tag (e.g. `dev` or `beta`) on a multi-tag repository.

### update.sh

```bash
#!/bin/sh
set -e
docker compose -f /compose/docker-compose.yml pull <service> <service>
docker compose -f /compose/docker-compose.yml up -d --no-deps --force-recreate <service> <service>
```

### Environment variables

| Variable | Description |
|---|---|
| `WEBHOOK_TOKEN` | Secret token included in the webhook URL path |
| `WATCH_TAG` | Only trigger on pushes of this image tag |
| `COMPOSE_PROJECT_NAME` | Must match the Compose project name on the host |

## Updating

This image is not rebuilt automatically. To pick up upstream changes, push to `main` — the pipeline will rebuild and push to Docker Hub.
