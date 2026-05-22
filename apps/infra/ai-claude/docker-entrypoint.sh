#!/bin/bash
set -e

# Seed Claude defaults into the emptyDir volume mount at /root/.claude
# This runs every pod start since emptyDir is cleared on pod restart.
mkdir -p /root/.claude/commands

# Copy commands (overwrite to pick up image updates)
cp -rf /root/.claude-defaults/commands/. /root/.claude/commands/

# Copy settings (overwrite to pick up image updates)
cp -f /root/.claude-defaults/settings.json /root/.claude/settings.json

exec sleep infinity
