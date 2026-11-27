#!/usr/bin/env bash
# Uploads the files in site/ that differ from the server, over SSH.
#
# The cPanel account has a jailed shell without rsync, so this compares MD5
# hashes and streams only the changed files through tar. Files on the server
# that the package does not contain are left alone (.well-known, .user.ini);
# retired files are removed by hand.
#
# Needs SSH_KEY, SSH_HOST, SSH_PORT, SSH_USER, SSH_TARGET; optional
# SSH_KNOWN_HOSTS and DRY_RUN=true.
set -euo pipefail

install -d -m 700 ~/.ssh
trap 'rm -f ~/.ssh/deploy_key' EXIT
printf '%s\n' "$SSH_KEY" > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key
if [ -n "${SSH_KNOWN_HOSTS:-}" ]; then
  printf '%s\n' "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
else
  ssh-keyscan -p "$SSH_PORT" -t ed25519,rsa "$SSH_HOST" 2>/dev/null | grep -v '^#' > ~/.ssh/known_hosts || true
  if [ ! -s ~/.ssh/known_hosts ]; then
    echo "::error::$SSH_HOST did not answer on port $SSH_PORT."
    exit 1
  fi
  echo "::warning::Host key not pinned. Save this as the DEPLOY_SSH_KNOWN_HOSTS secret: $(head -n1 ~/.ssh/known_hosts)"
fi

remote() {
  ssh -p "$SSH_PORT" -i ~/.ssh/deploy_key -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=yes -o BatchMode=yes "$SSH_USER@$SSH_HOST" "$@"
}

# The host sometimes times out for a while; wait and try again before giving up.
for wait in 15 45 90 0; do
  if remote true; then break; fi
  if [ "$wait" -eq 0 ]; then
    echo "::error::Could not sign in to $SSH_HOST on port $SSH_PORT. If it timed out, re-run the failed jobs."
    exit 1
  fi
  echo "SSH sign-in failed; trying again in ${wait}s."
  sleep "$wait"
done
remote "command -v tar >/dev/null && command -v md5sum >/dev/null && cd '$SSH_TARGET'" \
  || { echo "::error::The server shell lacks tar or md5sum, or $SSH_TARGET is missing."; exit 1; }

work=$(mktemp -d)
(cd site && find . -type f | LC_ALL=C sort > "$work/files")
(cd site && tr '\n' '\0' < "$work/files" | xargs -0 md5sum) | LC_ALL=C sort > "$work/local.md5"
# Missing files make md5sum complain; they simply count as changed.
tr '\n' '\0' < "$work/files" \
  | remote "cd '$SSH_TARGET' && xargs -0 md5sum 2>/dev/null; true" \
  | LC_ALL=C sort > "$work/remote.md5"
LC_ALL=C comm -23 "$work/local.md5" "$work/remote.md5" > "$work/changed.md5"
cut -c35- "$work/changed.md5" > "$work/changed"

count=$(wc -l < "$work/changed")
echo "$count of $(wc -l < "$work/files") files differ from the server:"
sed 's/^/  /' "$work/changed"
if [ "$count" -eq 0 ] || [ "${DRY_RUN:-}" = true ]; then exit 0; fi

tar -C site -czf - --mode='u=rwX,go=rX' --owner=0 --group=0 \
    --verbatim-files-from -T "$work/changed" \
  | remote "cd '$SSH_TARGET' && tar -xzf - --no-same-owner"

# Check the server now holds exactly what was sent.
tr '\n' '\0' < "$work/changed" \
  | remote "cd '$SSH_TARGET' && xargs -0 md5sum" | LC_ALL=C sort > "$work/after.md5"
if ! cmp -s "$work/changed.md5" "$work/after.md5"; then
  echo "::error::Some files on the server still differ after the upload."
  exit 1
fi
echo "Uploaded $count files."
