# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# A job image, not a server. Stage 1 installs starship with its official installer
# (pinned release, scripts/install.sh); the runtime stage is a slim debian with bash and
# that one binary, running as a non-root user. The default command checks that
# starship.toml renders a prompt (scripts/check.sh) and exits 0 when it does.

FROM debian:bookworm-slim AS install
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY scripts/install.sh /tmp/install.sh
RUN BIN_DIR=/usr/local/bin sh /tmp/install.sh

FROM debian:bookworm-slim AS runtime
ARG BUILD_ID=""
ENV BUILD_ID=$BUILD_ID STARSHIP_CONFIG=/app/starship.toml TERM=xterm-256color
COPY --from=install /usr/local/bin/starship /usr/local/bin/starship
RUN useradd -m -u 10001 -s /bin/bash app \
 && echo 'eval "$(starship init bash)"' >> /home/app/.bashrc
WORKDIR /app
COPY --chown=app:app . .
USER app
CMD ["sh", "scripts/check.sh"]
