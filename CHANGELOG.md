# Changelog - OC-Argent

## [v1.2.0] - 2026-03-23
### Added
- **Automated Deployment:** Released `install_oc_argent.sh` (Version 1) for automated, non-destructive sandbox creation and memory migration for existing OpenClaw environments.
- **Clean Uninstallation:** Released `uninstall_oc_argent.sh` to safely purge the architecture and restore default routing.


## [v1.1.0] - 2026-03-22
### Added
- **Dynamic Model Router:** Added a `$4.75` alerting threshold that actively fires a Discord warning before the hard daily budget limit is reached.
- **Intent Firewall:** Added robust Regex filtering to prevent the accidental leakage of Discord User IDs, internal Server IP Addresses (192.168.x.x, 10.x.x.x, 172.16.x.x), and MAC Addresses in chat messages. Explicitly blocks the leaking of API keys, Passwords, and Auth Tokens.

## [v1.0.0] - 2026-03-21
### Added
- Initial public release.
- **Hierarchical Adaptive Memory (HAM):** Tiered markdown structure integrating with native OpenClaw `sqlite-vec` memory engine.
- **Intent Firewall:** Runtime governance policy engine (`global_policy.json` and `firewall.py`) for auditing tool execution and enforcing backups on critical files.
- **Dynamic Model Router:** Automated, budget-aware routing script separating tasks into complex (cloud) or simple (local) execution queues via an `ollama` heuristic scoring system.
