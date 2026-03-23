#!/bin/bash
set -e

echo "========================================================"
echo "    OC-Argent Architecture Installation - Version 1     "
echo "========================================================"
echo "This script will deploy the Hierarchical Adaptive Memory (HAM),"
echo "Intent Firewall, and Dynamic Model Router into your OpenClaw workspace."
echo "Your original files will NOT be modified or deleted."
echo "========================================================"

# 1. Version Check
if ! command -v openclaw &> /dev/null; then
    echo "ERROR: OpenClaw CLI not found. Please install OpenClaw first."
    exit 1
fi

OC_VERSION=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "Detected OpenClaw version: $OC_VERSION"

# 2. Safe Sandbox Creation
WORKSPACE_DIR="$HOME/.openclaw/workspace"
ARGENT_DIR="$WORKSPACE_DIR/argent"

if [ -d "$ARGENT_DIR" ]; then
    echo "WARNING: $ARGENT_DIR already exists."
    read -p "Do you want to overwrite the existing OC-Argent installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
    rm -rf "$ARGENT_DIR"
fi

echo "Creating OC-Argent directory structure..."
mkdir -p "$ARGENT_DIR"/{memory/facts,memory/logs,intents,routing,scripts}

# 3. Asset Deployment
echo "Downloading core OC-Argent assets from GitHub..."
REPO_RAW_URL="https://raw.githubusercontent.com/Ravenspo/OC-Argent/main"

curl -sL "$REPO_RAW_URL/intents/global_policy.json" -o "$ARGENT_DIR/intents/global_policy.json"
curl -sL "$REPO_RAW_URL/scripts/firewall.py" -o "$ARGENT_DIR/scripts/firewall.py"
curl -sL "$REPO_RAW_URL/routing/model_router.py" -o "$ARGENT_DIR/routing/model_router.py"
curl -sL "$REPO_RAW_URL/routing/metrics.json" -o "$ARGENT_DIR/routing/metrics.json"
curl -sL "$REPO_RAW_URL/scripts/migrate_memory.py" -o "$ARGENT_DIR/scripts/migrate_memory.py"
curl -sL "$REPO_RAW_URL/memory/facts/README.md" -o "$ARGENT_DIR/memory/facts/README.md"

# Dynamically patch paths in downloaded scripts before execution
echo "Configuring paths for current user environment..."
sed -i "s|/path/to/openclaw/workspace|$WORKSPACE_DIR|g" "$ARGENT_DIR/scripts/firewall.py"
sed -i "s|/path/to/openclaw/workspace|$WORKSPACE_DIR|g" "$ARGENT_DIR/routing/model_router.py"
sed -i "s|/path/to/openclaw/workspace|$WORKSPACE_DIR|g" "$ARGENT_DIR/scripts/migrate_memory.py"

# 4. Non-Destructive Migration
echo "Migrating and chunking existing memory files..."
if [ -f "$ARGENT_DIR/scripts/migrate_memory.py" ]; then
    python3 "$ARGENT_DIR/scripts/migrate_memory.py"
else
    echo "ERROR: Failed to download migration script."
    exit 1
fi

echo "========================================================"
echo "OC-Argent Installation Complete!"
echo "========================================================"
echo "Next Steps:"
echo "1. Edit $ARGENT_DIR/intents/global_policy.json to configure your firewall rules."
echo "2. Edit $ARGENT_DIR/routing/model_router.py to set your local Ollama IP address and Discord ID."
echo "3. Add the Intent Firewall mandate to your main OpenClaw agent prompt."
echo "========================================================"
