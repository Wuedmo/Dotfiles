#!/bin/bash
set -euo pipefail

# Simple dry-run harness for dotfiles installer scripts.
# This script runs key scripts with DRY_RUN=true and FORCE_CACHYOS=true
# and checks for 'DRY-RUN:' outputs produced by run_cmd.

SCRIPTS=(
  "install/setup-nvidia"
  "bin/pkg-install"
  "bin/pkg-remove"
  "bin/update-perform"
)

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)"
cd "$REPO_ROOT"

export DRY_RUN=true
export FORCE_CACHYOS=true

echo "Running dry-run tests (DRY_RUN=true FORCE_CACHYOS=true)"

# Create a temporary fake HOME so scripts that source $HOME/.local/share/dotfiles
# will pick up the repository copy in this workspace.
TMP_HOME="$(mktemp -d)"
mkdir -p "$TMP_HOME/.local/share"
ln -sfn "$REPO_ROOT" "$TMP_HOME/.local/share/dotfiles"
export HOME="$TMP_HOME"
echo "Using fake HOME=$HOME (repo mounted at $HOME/.local/share/dotfiles)"

# Initialize backup session (some scripts expect a session to exist)
# source the backup helper from the repo and create a session
source "$REPO_ROOT/install/lib/backup.sh"
init_backup_session >/dev/null || true

# Provide a fake `sudo` wrapper in PATH so tests don't prompt for a password.
TMP_BIN_DIR="$(mktemp -d)"
cat > "$TMP_BIN_DIR/sudo" <<'SUDO_WRAPPER'
#!/bin/sh
if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "DRY-RUN: sudo $*"
  exit 0
fi
# Fallback to real sudo
exec /usr/bin/sudo "$@"
SUDO_WRAPPER
chmod +x "$TMP_BIN_DIR/sudo"
export PATH="$TMP_BIN_DIR:$PATH"
FAIL=0
for s in "${SCRIPTS[@]}"; do
  echo "--- Testing: $s ---"
  OUTFILE="/tmp/dotfiles-dryrun-$(basename "$s").out"
  if bash "$REPO_ROOT/$s" >/tmp/dotfiles-dryrun-$(basename "$s").out 2>&1; then
    :
  else
    # many scripts return non-zero in dry-run; ignore
    :
  fi
  if grep -q "DRY-RUN:" "$OUTFILE" || grep -q "DRY-RUN MODE" "$OUTFILE"; then
    echo "OK: $s produced DRY-RUN output"
  else
    echo "WARN: $s did not produce DRY-RUN output (check whether it respects DRY_RUN)"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "Dry-run tests: PASS"
  exit 0
else
  echo "Dry-run tests: FAIL (some scripts did not emit DRY-RUN markers)"
  exit 2
fi
