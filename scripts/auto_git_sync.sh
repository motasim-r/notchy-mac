#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
POLL_SECONDS="${POLL_SECONDS:-4}"
IDLE_SECONDS="${IDLE_SECONDS:-8}"
COMMIT_PREFIX="${COMMIT_PREFIX:-chore(autocommit)}"
LOG_FILE="${LOG_FILE:-$HOME/Library/Logs/Notchy/autocommit.log}"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local msg="$1"
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" | tee -a "$LOG_FILE" >/dev/null
}

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Not a git repository: $REPO_DIR" >&2
  exit 1
fi

LOCK_DIR="${TMPDIR:-/tmp}/notchy_autocommit_lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "auto-commit already running for this user; exiting"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1 || true' EXIT

cd "$REPO_DIR"

if ! git config --get user.name >/dev/null 2>&1; then
  log "git user.name is not configured for repo; set it with: git -C '$REPO_DIR' config user.name 'Your Name'"
fi
if ! git config --get user.email >/dev/null 2>&1; then
  log "git user.email is not configured for repo; set it with: git -C '$REPO_DIR' config user.email 'you@example.com'"
fi

last_snapshot=""
last_change_epoch=0

log "auto-commit daemon started (poll=${POLL_SECONDS}s, idle=${IDLE_SECONDS}s, repo=$REPO_DIR)"

while true; do
  snapshot="$(git status --porcelain=v1 --untracked=normal || true)"

  if [[ -z "$snapshot" ]]; then
    last_snapshot=""
    last_change_epoch=0
    sleep "$POLL_SECONDS"
    continue
  fi

  now_epoch="$(date +%s)"

  if [[ "$snapshot" != "$last_snapshot" ]]; then
    last_snapshot="$snapshot"
    last_change_epoch="$now_epoch"
    sleep "$POLL_SECONDS"
    continue
  fi

  if (( now_epoch - last_change_epoch < IDLE_SECONDS )); then
    sleep "$POLL_SECONDS"
    continue
  fi

  git add -A
  if git diff --cached --quiet; then
    sleep "$POLL_SECONDS"
    continue
  fi

  changed_count="$(git diff --cached --name-only | wc -l | tr -d ' ')"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  commit_msg="$COMMIT_PREFIX: $changed_count file(s) at $timestamp"

  if git commit -m "$commit_msg" >/dev/null 2>&1; then
    log "committed: $commit_msg"
  else
    log "commit failed; check git identity and repository state"
    sleep "$POLL_SECONDS"
    continue
  fi

  branch="$(git branch --show-current)"
  if git remote get-url origin >/dev/null 2>&1; then
    if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      if git push >/dev/null 2>&1; then
        log "pushed to upstream branch"
      else
        log "push failed; check network/auth"
      fi
    else
      if git push -u origin "$branch" >/dev/null 2>&1; then
        log "pushed and set upstream: origin/$branch"
      else
        log "push failed (no upstream); check origin and permissions"
      fi
    fi
  else
    log "origin remote not configured; commit saved locally"
  fi

  last_snapshot=""
  last_change_epoch=0
  sleep "$POLL_SECONDS"
done
