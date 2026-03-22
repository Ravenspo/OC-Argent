import json
import os
import sys
import re

POLICY_FILE = "/path/to/openclaw/workspace/argent/intents/global_policy.json"

def load_policy():
    if not os.path.exists(POLICY_FILE):
        return None
    with open(POLICY_FILE, 'r') as f:
        return json.load(f)

def evaluate_intent(tool_name, arguments_str):
    policy = load_policy()
    if not policy:
        return False, "Policy file missing. Failsafe activated: DENY."

    try:
        args = json.loads(arguments_str) if arguments_str else {}
    except json.JSONDecodeError:
        args = {}

    global_rules = policy.get("policies", {}).get("global", {})
    fs_rules = policy.get("policies", {}).get("file_system", {})
    comm_rules = policy.get("policies", {}).get("communication", {})

    # 1. Restricted Commands
    if tool_name == "exec":
        command = args.get("command", "")
        for restricted in global_rules.get("restricted_commands", []):
            # Wildcard matching for things like "curl * | bash"
            if "*" in restricted:
                base_cmd = restricted.split("*")[0].strip()
                pipe_cmd = restricted.split("*")[1].strip()
                if base_cmd in command and pipe_cmd in command:
                    return False, f"DENIED: Command matches restricted wildcard pattern '{restricted}'."
            elif restricted in command:
                return False, f"DENIED: Command contains strictly prohibited pattern '{restricted}'."

    # 2. Communication / Message Tool
    if tool_name == "message" or tool_name == "sessions_send":
        message_text = args.get("message", "")
        lower_msg = message_text.lower()
        
        # Basic heuristic check for secrets
        if "api_key" in lower_msg or "password" in lower_msg or "token=" in lower_msg:
            return False, "DENIED: Message appears to contain prohibited secrets or auth tokens."
            
        # Check for Discord IDs (17-19 digits)
        if re.search(r'\b\d{17,19}\b', message_text):
            return False, "DENIED: Message appears to contain a Discord User ID."
            
        # Check for Server/Internal IP addresses (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
        if re.search(r'\b(?:192\.168|10\.|172\.(?:1[6-9]|2[0-9]|3[0-1]))\.\d{1,3}\.\d{1,3}\b', message_text):
            return False, "DENIED: Message appears to contain an internal Server IP Address."
            
        # Check for MAC Addresses (Windows: 00-11-22-33-44-55, Unix: 00:11:22:33:44:55, Cisco: 0011.2233.4455, Raw: 001122334455)
        mac_pattern = r'\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b|\b[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\b'
        if re.search(mac_pattern, message_text):
            return False, "DENIED: Message appears to contain a MAC Address."
            
        return False, f"PENDING: {tool_name} requires explicit user authorization before execution."

    # 3. Gateway Tool
    if tool_name == "gateway":
        return False, "DENIED: Gateway modifications require explicit user authorization."

    # 4. File System Backup Requirements
    if tool_name in ["edit", "write"]:
        target_file = args.get("file_path", "") or args.get("path", "")
        for critical in fs_rules.get("require_backup_before_edit", []):
            if critical in target_file:
                return False, f"PENDING: Editing {critical} requires a verified backup and breadcrumb check."

    # 5. Auto-approve Tools
    if tool_name in global_rules.get("auto_approve_tools", []):
        return True, "APPROVED: Tool is whitelisted for autonomous execution."

    return True, "APPROVED: Operation falls outside restricted policies."

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 firewall.py <tool_name> '<arguments_json>'")
        sys.exit(1)
        
    tool = sys.argv[1]
    args_str = sys.argv[2]
    
    allowed, message = evaluate_intent(tool, args_str)
    print(message)
    if not allowed:
        sys.exit(1)
    sys.exit(0)
