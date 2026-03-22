# OC-Argent

A clean, drop-in architecture template designed to run ArgentOS-style persistent memory, runtime governance, and dynamic model routing natively inside the OpenClaw ecosystem.

This repository provides a framework for power users who want the advanced architectural patterns of an AI operating system without abandoning the messaging integrations and raw flexibility of OpenClaw.

## Features

1. **Hierarchical Adaptive Memory (HAM):** Replaces the flat, single-file memory dump with a tiered directory structure. It separates core identity, indexed topical facts, and raw logs, allowing OpenClaw's native `sqlite-vec` engine to dynamically load only semantically relevant context, saving massive amounts of API tokens.
2. **Intent Firewall (Runtime Governance):** A Python-based policy engine and JSON configuration file that audits and intercepts an agent's tool calls *before* execution. It blocks destructive shell commands, enforces required backups before file edits, and prevents API key leaks in chat.
3. **Dynamic Model Router:** An automated routing script that evaluates prompt complexity using a free local LLM (like Ollama) and dynamically assigns subagent tasks to either a heavy cloud model (Gemini/Claude) or a free local model. It tracks daily API spend and automatically fails over to local models if a strict budget limit is reached.

## Deployment & Setup

1. Clone this repository into a dedicated folder inside your OpenClaw workspace (e.g., `~/.openclaw/workspace/argent/`).
2. Update the `intents/global_policy.json` file with your specific file paths, protected files, and restricted shell commands.
3. Update `routing/model_router.py` with your specific local Ollama IP address and your preferred cloud models.
4. Update `memory/core.md` with your system's core identity, rules of engagement, and prompt formatting requirements.
5. In your main OpenClaw agent prompt, explicitly mandate that the agent must evaluate its intentions against the `firewall.py` script before executing any state-changing tools (like `exec`, `edit`, `write`, or `gateway`).
