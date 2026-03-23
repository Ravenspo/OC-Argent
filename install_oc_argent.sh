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

echo "========================================================"

echo " Configuration: Dynamic Model Router"

echo "========================================================"



read -p "Enter your primary Cloud Model (e.g., google/gemini-3.1-pro-preview) [Default: google/gemini-3.1-pro-preview]: " CLOUD_MODEL

CLOUD_MODEL=${CLOUD_MODEL:-"google/gemini-3.1-pro-preview"}



read -p "Enter your local Ollama Model Alias (e.g., ollama_llama32) [Default: ollama_llama32]: " LOCAL_MODEL

LOCAL_MODEL=${LOCAL_MODEL:-"ollama_llama32"}



read -p "Enter your local Ollama IP Address (e.g., 192.168.1.100) [Default: 127.0.0.1]: " OLLAMA_IP

OLLAMA_IP=${OLLAMA_IP:-"127.0.0.1"}



echo "========================================================"

echo " Configuration: Budget Alerts"

echo "========================================================"

echo "OC-Argent can send a message to a specific channel when you near your daily API budget limit."

echo "Leave the Channel blank to disable budget alerts."



read -p "Enter your Alert Channel (discord, slack, telegram) [Default: none]: " ALERT_CHANNEL

if [ ! -z "$ALERT_CHANNEL" ]; then

    read -p "Enter your User ID for that channel (e.g., 268508859801272320): " ALERT_USER_ID

fi


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
echo "Applying custom routing and alert configurations..."

sed -i "s|google/gemini-3.1-pro-preview|$CLOUD_MODEL|g" "$ARGENT_DIR/routing/model_router.py"

sed -i "s|ollama_llama32|$LOCAL_MODEL|g" "$ARGENT_DIR/routing/model_router.py"

sed -i "s|YOUR_LOCAL_OLLAMA_IP|$OLLAMA_IP|g" "$ARGENT_DIR/routing/model_router.py"



if [ ! -z "$ALERT_CHANNEL" ] && [ ! -z "$ALERT_USER_ID" ]; then

    sed -i "s|--channel\", \"discord\"|--channel\", \"$ALERT_CHANNEL\"|g" "$ARGENT_DIR/routing/model_router.py"

    sed -i "s|YOUR_DISCORD_ID|$ALERT_USER_ID|g" "$ARGENT_DIR/routing/model_router.py"

else

    # Comment out the alert block if they opted out

    sed -i "/# Trigger alert if we cross the threshold/,/return selected_model, metrics/ s/^/# /" "$ARGENT_DIR/routing/model_router.py"

    sed -i "s|# return selected_model, metrics|return selected_model, metrics|g" "$ARGENT_DIR/routing/model_router.py"

fi


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
