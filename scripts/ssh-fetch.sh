#!/usr/bin/env bash
# Copies the server's versions of the files in a built package into a local
# folder over SSH, for the drift check to read. The host's bot check turns
# automated web requests away, but SSH reaches the files directly.
#
# Usage: ssh-fetch.sh <package site folder> <output folder>
# Needs SSH_KEY, SSH_HOST, SSH_PORT, SSH_USER, SSH_TARGET; optional
# SSH_KNOWN_HOSTS.
set -euo pipefail
package=$1
out=$2

install -d -m 700 ~/.ssh
trap 'rm -f ~/.ssh/deploy_key' EXIT
printf '%s\n' "$SSH_KEY" > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key
if [ -n "${SSH_KNOWN_HOSTS:-}" ]; then
  printf '%s\n' "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
else
  ssh-keyscan -p "$SSH_PORT" -t ed25519,rsa "$SSH_HOST" 2>/dev/null | grep -v '^#' > ~/.ssh/known_hosts || true
fi

remote() {
  ssh -p "$SSH_PORT" -i ~/.ssh/deploy_key -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=yes -o BatchMode=yes "$SSH_USER@$SSH_HOST" "$@"
}

for wait in 15 45 90 0; do
  if remote true; then break; fi
  if [ "$wait" -eq 0 ]; then
    echo "::error::Could not sign in to $SSH_HOST on port $SSH_PORT. If it timed out, re-run the failed jobs."
    exit 1
  fi
  echo "SSH sign-in failed; trying again in ${wait}s."
  sleep "$wait"
done

mkdir -p "$out"
# Files missing on the server are skipped; the drift check reports them.
(cd "$package" && find . -type f) \
  | remote "cd '$SSH_TARGET' && while IFS= read -r f; do [ -f \"\$f\" ] && printf '%s\n' \"\$f\"; done | tar -cf - -T -" \
  | tar -xf - -C "$out"
echo "Fetched $(find "$out" -type f | wc -l) files from the server."
