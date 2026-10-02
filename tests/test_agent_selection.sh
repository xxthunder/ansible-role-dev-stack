#!/usr/bin/env bash
# Unit test for the agent-selection logic in templates/zshenv.j2.
#
# The logic is pure shell, so it can be exercised here with real ssh-agent
# processes -- no host, no container. Run under zsh, which is what the host uses
# and what `devpod ssh --stdio` invokes non-interactively.
#
#   ./tests/test_agent_selection.sh
set -uo pipefail

TEMPLATE="$(dirname "$0")/../templates/zshenv.j2"
SOCK_NAME="openssh_agent"
fails=0

WORK="$(mktemp -d)"
trap 'pkill -f "ssh-agent -a $WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

# Render the Jinja variable the logic depends on.
RENDERED="$WORK/zshenv"
sed "s|{{ dev_stack_ssh_agent_sock }}|$SOCK_NAME|g" "$TEMPLATE" > "$RENDERED"

# Evaluate the rendered file under zsh with a fake HOME/XDG_RUNTIME_DIR, and
# print the SSH_AUTH_SOCK it settles on.
resolve() {
  local incoming="$1"
  env -i HOME="$WORK/home" XDG_RUNTIME_DIR="$WORK/run" PATH="$PATH" \
      ${incoming:+SSH_AUTH_SOCK="$incoming"} \
      zsh -c "source '$RENDERED'; print -r -- \"\${SSH_AUTH_SOCK:-}\""
}

check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    echo "  ok   - $name"
  else
    echo "  FAIL - $name"
    echo "         want: $want"
    echo "         got:  $got"
    fails=$((fails + 1))
  fi
}

mkdir -p "$WORK/home/.ssh" "$WORK/run"
PERSISTENT="$WORK/run/$SOCK_NAME"

echo "== agent selection =="

# --- A. a live forwarded agent is left alone --------------------------------
ssh-agent -a "$WORK/forwarded.sock" >/dev/null 2>&1
check "A: a reachable forwarded agent is not overridden" \
      "$(resolve "$WORK/forwarded.sock")" "$WORK/forwarded.sock"

# --- B. dead forwarded socket falls through to the persistent agent ---------
# Kill the agent but leave the socket FILE behind -- the exact state observed in
# a stale forwarded socket, where existence checks pass and only a liveness check catches it.
pkill -f "ssh-agent -a $WORK/forwarded.sock" >/dev/null 2>&1
touch "$WORK/forwarded.sock"
ssh-agent -a "$PERSISTENT" >/dev/null 2>&1
check "B: dead forwarded socket falls back to the persistent agent" \
      "$(resolve "$WORK/forwarded.sock")" "$PERSISTENT"

# --- C. no agent named at all (the no-forwarding session) -------------------
check "C: unset SSH_AUTH_SOCK selects the persistent agent" \
      "$(resolve "")" "$PERSISTENT"

# --- D. reachable but EMPTY forwarded agent is left alone -------------------
# ssh-agent starts with no identities, so this pins the exit-1 rule: an agent
# that answers must not be abandoned just because it holds no keys yet.
ssh-agent -a "$WORK/empty.sock" >/dev/null 2>&1
check "D: a reachable-but-empty agent is not abandoned" \
      "$(resolve "$WORK/empty.sock")" "$WORK/empty.sock"

# --- E. nothing alive anywhere degrades quietly -----------------------------
pkill -f "ssh-agent -a $WORK" >/dev/null 2>&1
rm -f "$PERSISTENT"
resolve "" >/dev/null 2>&1; rc=$?
check "E: no agent anywhere exits cleanly" "$rc" "0"

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; fi
exit "$fails"
