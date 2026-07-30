#!/usr/bin/env bash
# Reproducible install of Postiz (https://github.com/gitroomhq/postiz-app)
# using the project's official Docker Compose stack.
#
# Requirements: docker (with the compose plugin), git, openssl, curl.
# After it finishes, Postiz is available at http://localhost:4007
set -euo pipefail

INSTALL_DIR="${POSTIZ_DIR:-$HOME/postiz-app}"

# 1. Get the source (the official docker-compose.yaml lives in the repo root).
if [ ! -d "$INSTALL_DIR" ]; then
  git clone --depth 1 https://github.com/gitroomhq/postiz-app.git "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"

# 2. Give the install a real JWT secret instead of the placeholder,
#    without touching the upstream compose file.
JWT_SECRET=$(openssl rand -hex 32)
cat > docker-compose.override.yaml <<EOF
services:
  postiz:
    environment:
      JWT_SECRET: '$JWT_SECRET'
EOF

# 3. If this machine routes outbound TLS through an intercepting proxy
#    (e.g. a sandboxed agent environment with a CA at /root/.ccr/ca-bundle.crt),
#    mount that CA into the container so the boot-time
#    "pnpm dlx prisma db push" can reach registry.npmjs.org.
CA_BUNDLE="${AGENT_CA_BUNDLE:-/root/.ccr/ca-bundle.crt}"
if sudo test -f "$CA_BUNDLE" 2>/dev/null || [ -f "$CA_BUNDLE" ]; then
  CA_COPY="$INSTALL_DIR/agent-ca.crt"
  sudo cp "$CA_BUNDLE" "$CA_COPY" 2>/dev/null || cp "$CA_BUNDLE" "$CA_COPY"
  sudo chmod 644 "$CA_COPY" 2>/dev/null || chmod 644 "$CA_COPY"
  cat >> docker-compose.override.yaml <<EOF
      NODE_EXTRA_CA_CERTS: /etc/ssl/certs/agent-ca.pem
    volumes:
      - $CA_COPY:/etc/ssl/certs/agent-ca.pem:ro
EOF
fi

# 4. Bring up the full stack: postiz + postgres + redis + temporal (+ monitoring).
docker compose up -d

# 5. Wait for the app to answer.
echo "Waiting for Postiz on http://localhost:4007 ..."
for _ in $(seq 1 120); do
  if curl -sf -o /dev/null http://localhost:4007; then
    echo "Postiz is up: http://localhost:4007 (register at /auth)"
    exit 0
  fi
  sleep 5
done
echo "Timed out waiting for Postiz; check: docker logs postiz" >&2
exit 1
