#!/bin/bash
set -e

echo "========================================================"
echo "    OC-Argent Architecture Uninstallation - Version 1    "
echo "========================================================"
echo "This script will completely remove the Hierarchical Adaptive Memory (HAM),"
echo "Intent Firewall, and Dynamic Model Router from your OpenClaw workspace."
echo "Your original OpenClaw root files will NOT be affected."
echo "========================================================"

WORKSPACE_DIR="$HOME/.openclaw/workspace"
ARGENT_DIR="$WORKSPACE_DIR/argent"

if [ ! -d "$ARGENT_DIR" ]; then
    echo "ERROR: OC-Argent installation not found at $ARGENT_DIR."
    exit 1
fi

echo ""
echo "WARNING: This will permanently delete the following directory and all its contents:"
echo "-> $ARGENT_DIR"
echo ""
read -p "Are you sure you want to proceed with uninstallation? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation aborted."
    exit 0
fi

echo "Removing OC-Argent sandbox directory..."
rm -rf "$ARGENT_DIR"

echo "========================================================"
echo "OC-Argent Uninstallation Complete!"
echo "========================================================"
echo "ACTION REQUIRED: You must manually remove the Intent Firewall mandate"
echo "from your main OpenClaw agent prompt (or from your workspace/core.md if"
echo "you injected it there) to complete the removal."
echo "To open your configuration editor, run:"
echo "openclaw config edit agents.defaults.prompt"
echo "========================================================"
