# Changelog - OC-Argent

## [v1.1.0] - 2026-03-22
### Added
- **Dynamic Model Router:** Added a `$4.75` alerting threshold that actively fires a Discord warning before the hard daily budget limit is reached.
- **Intent Firewall:** Added robust Regex filtering to prevent the accidental leakage of Discord User IDs, internal Server IP Addresses (192.168.x.x, 10.x.x.x, 172.16.x.x), and MAC Addresses in chat messages.

## [v1.0.0] - 2026-03-21
### Added
- Initial public release.
- **Hierarchical Adaptive Memory (HAM):** Tiered markdown structure integrating with native OpenClaw `sqlite-vec` memory engine.
- **Intent Firewall:** Runtime governance policy engine (`global_policy.json` and `firewall.py`) for auditing tool execution and enforcing backups on critical files.
- **Dynamic Model Router:** Automated, budget-aware routing script separating tasks into complex (cloud) or simple (local) execution queues via an `ollama` heuristic scoring system.
