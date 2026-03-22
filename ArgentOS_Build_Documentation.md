# ArgentOS Architecture Integration - OpenClaw Build Documentation

This document outlines the custom architecture integrated into the Your Organization OpenClaw environment on March 20, 2026. The architecture replicates the core functionalities of the open-source ArgentOS platform, utilizing a fully local, sandboxed directory structure.

## Directory Structure
All components are sandboxed within `/path/to/openclaw/workspace/argent/` to prevent clutter in the root workspace.

- `/argent/memory/` - Hierarchical Adaptive Memory (HAM) storage.
- `/argent/intents/` - Runtime Governance policy definitions.
- `/argent/routing/` - Dynamic Model Router and cost tracking.
- `/argent/scripts/` - Python execution engines for the firewall and router.

---

## Phase 1: Hierarchical Adaptive Memory (HAM)
Replaces the flat `MEMORY.md` log with a three-tier system, allowing the native OpenClaw `sqlite-vec` engine (via local Ollama `llama3.2:latest` embeddings) to load context dynamically and efficiently.

1. **The Slug (`/argent/memory/core.md`):** High-priority identity, rules, and current state. Loaded into every prompt. Includes User persona rules and the Intent Firewall mandate.
2. **The Index (`/argent/memory/facts/`):** Topical markdown files (e.g., `tools_minecraft_server.md`, `memory_infrastructure.md`). Indexed by the vector engine. Only pulled into the context window when semantically relevant.
3. **The Raw Data (`/argent/memory/logs/`):** Raw transcripts, daily dumps, and meeting notes. Actively kept out of the context window unless explicitly queried.

---

## Phase 2: Intent Firewall (Runtime Governance)
A proactive security layer that intercepts and audits agent tool calls before execution.

- **Policy File (`/argent/intents/global_policy.json`):** Defines whitelisted tools, restricted shell commands (e.g., `rm -rf`, `curl * | bash`), and critical files requiring backups before edits.
- **Execution Engine (`/argent/scripts/firewall.py`):** A Python script that evaluates the tool name and arguments against the JSON policy. Returns `APPROVED` or `DENIED`.
- **Enforcement:** The core mandate is injected into `core.md`, forcing the agent to evaluate its own intent against the policy script before executing state-changing operations (`write`, `edit`, `exec`, `gateway`).

---

## Phase 3: Dynamic Model Router
An automated routing script designed to manage daily API budgets and optimize model selection based on task complexity.

- **Router Script (`/argent/routing/model_router.py`):** Evaluates prompts to determine if they require heavy cloud reasoning (Gemini 3.1 Pro) or can be handled locally for free (Ollama). Detects vision tasks and forces them to the local desktop GPU.
- **Metrics Tracker (`/argent/routing/metrics.json`):** Enforces a strict $5.00 daily budget. Tracks spend and task counts. If the budget is exceeded, the router initiates a hard cutoff, forcing all remaining tasks to the local Ollama server.
