# Starship template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with a
Starship starter laid on top. **A job, not a service**: the image's default command runs the
check and exits 0 on success; nothing listens on `$PORT`.

## What it is

A [Starship](https://starship.rs) prompt configuration and a check that it renders:

| path | what |
|---|---|
| `starship.toml` | the prompt: `qode <dir> <git:branch> [status] took <duration> >` — plain-text symbols, no Nerd Font needed |
| `scripts/install.sh` | installs starship at a pinned release (official installer) |
| `scripts/check.sh` | **the job**: config loads without warnings, the prompt renders (ok / failed / slow command), and `starship init bash` drives an interactive bash prompt |

Use it in your own shell: `export STARSHIP_CONFIG=/path/to/starship.toml` plus the
`starship init` line for your shell.

## Run it

**With docker** (what the fleet does):

    docker compose build
    docker compose run --rm app          # the check; exit 0 = prompt renders
    docker compose run --rm app bash -i  # see it in a shell

**Without docker** (needs sh, bash, curl):

    sh scripts/install.sh                # = fleet.conf INSTALL_CMD; starship -> ./.bin
    sh scripts/check.sh

## Origin

Starship's official installer, pinned to release v1.26.0 (scripts/install.sh):

    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --version v1.26.0 --bin-dir <dir>

`starship.toml` is hand-written against the documented config schema
(`"$schema" = 'https://starship.rs/config-schema.json'`).

## Deviations from stock output, and why

- Starship has no project generator; its default config uses Nerd Font glyphs. This
  config uses plain text so the prompt renders identically in any terminal and in CI.
- The image is multi-stage: the installer runs in a throwaway stage, the runtime carries
  only the binary, bash and the config.
## Verified

**The docker image has NOT been built or run yet**: on 2026-10-05 the shared build host's docker disk was full (0-2 GB free for over 8 hours), so `docker compose build` was never attempted. Run `docker compose build && docker compose run --rm app` once before trusting it.

Without docker (2026-10-05, Linux, bash 5.2): `sh scripts/install.sh` installed starship
1.26.0 into `./.bin`, and `sh scripts/check.sh` passed — no config warnings, prompt
renders (`qode <dir> >`), failed-status and duration segments show, and the
`starship init bash` prompt matches.


## Fleet lifecycle

`fleet.conf` drives every script in `bin/` (see `docs/fleet-lifecycle.md`). On the fleet
the docker runtime runs `DOCKER_BUILD_CMD` (`docker compose build`) and, because this is
a job and not a service, stops there: `DOCKER_START_CMD` is empty, the same as
`START_CMD`. Run the job itself with `docker compose run --rm app`.

    ./bin/run                    # docker runtime: builds the image, then stops (no server)
    docker compose run --rm app  # runs the job; exit code 0 = pass
    FLEET_RUNTIME=process ./bin/run   # no docker: runs INSTALL_CMD, then stops at start

`bin/run` ends with the template's own "no START_CMD" message — that is intentional.

## Serving over HTTP

Fleet apps are served at the root of their own hostname
(`https://<hash>.<FLEET_APP_DOMAIN>/`). **This repo has no HTTP surface**: `PORT`,
`HEALTH_PATH` and `START_CMD` are empty and `compose.yaml` publishes nothing. If you add
an HTTP endpoint, listen on `0.0.0.0:$PORT` (read at runtime), serve at `/`, set `PORT`,
`HEALTH_PATH`, `START_CMD` and `DOCKER_START_CMD='docker compose up --remove-orphans'`
in `fleet.conf`, and publish `"${PORT:-N}:${PORT:-N}"` in `compose.yaml`.

`compose.yaml` passes the fleet's variables (`DATABASE_URL`, `REDIS_URL`, `S3_*`,
`SMTP_*` …) through to the container without values; this template reads none of them.
