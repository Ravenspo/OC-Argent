import json
import os
import sys
import urllib.request
import re
import subprocess
from datetime import datetime

ROUTER_DIR = "/path/to/openclaw/workspace/argent/routing"
METRICS_FILE = os.path.join(ROUTER_DIR, "metrics.json")
DAILY_BUDGET_LIMIT = 5.00
ALERT_THRESHOLD = 4.75

COST_ESTIMATES = {
    "google/gemini-3.1-pro-preview": 0.05,
    "anthropic/claude-haiku-4-5-20251001": 0.01,
    "ollama_llama32": 0.00,
    "http://YOUR_LOCAL_GPU_IP:11434/api/generate": 0.00
}

def load_metrics():
    today = datetime.now().strftime("%Y-%m-%d")
    default_metrics = {"date": today, "daily_spend": 0.0, "tasks_routed": 0}
    if not os.path.exists(METRICS_FILE):
        return default_metrics
    try:
        with open(METRICS_FILE, 'r') as f:
            metrics = json.load(f)
            if metrics.get("date") != today:
                return default_metrics
            return metrics
    except json.JSONDecodeError:
        return default_metrics

def save_metrics(metrics):
    with open(METRICS_FILE, 'w') as f:
        json.dump(metrics, f, indent=2)

def check_ollama_complexity(task_description):
    """
    Calls the local Ollama LLM to evaluate prompt complexity.
    Returns True for complex tasks, False for simple ones.
    """
    url = "http://YOUR_LOCAL_OLLAMA_IP:11434/api/generate"
    prompt = (
        "Rate the complexity of the following task from 1 to 10. "
        "1 means simple data entry, writing basic documentation, summarization, or simple questions. "
        "10 means deep architectural research, advanced coding, or heavy logical synthesis. "
        "Reply with ONLY a number from 1 to 10.\\n\\nTask: " + task_description
    )
    data = {
        "model": "llama3.2:latest",
        "prompt": prompt,
        "stream": False
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})
        resp = urllib.request.urlopen(req, timeout=5)
        result = json.loads(resp.read().decode('utf-8'))
        text = result.get("response", "").strip()
        
        match = re.search(r'\d+', text)
        if match:
            score = int(match.group())
            return score >= 7  # 7 or higher routes to Cloud (Gemini)
        return False
    except Exception as e:
        return False  # Fail open: route to free local model on error

def analyze_complexity(task_description):
    task_lower = task_description.lower()
    vision_keywords = ["image", "photo", "screenshot", "video", "visual", "ocr", "analyze picture"]
    for kw in vision_keywords:
        if kw in task_lower:
            return 'vision', False

    # Use Ollama LLM to score complexity instead of dumb keywords
    is_complex = check_ollama_complexity(task_description)
    return 'text', is_complex

def route_task(task_description):
    metrics = load_metrics()
    task_type, is_complex = analyze_complexity(task_description)
    budget_exceeded = metrics["daily_spend"] >= DAILY_BUDGET_LIMIT
    
    if task_type == 'vision':
        selected_model = "http://YOUR_LOCAL_GPU_IP:11434/api/generate"
    elif is_complex and not budget_exceeded:
        selected_model = "google/gemini-3.1-pro-preview"
    else:
        selected_model = "ollama_llama32"
        
    previous_spend = metrics["daily_spend"]
    metrics["daily_spend"] += COST_ESTIMATES.get(selected_model, 0.0)
    metrics["tasks_routed"] += 1
    save_metrics(metrics)
    
    # Trigger alert if we cross the threshold
    if previous_spend < ALERT_THRESHOLD and metrics["daily_spend"] >= ALERT_THRESHOLD:
        alert_msg = f"⚠️ **Budget Alert:** The Dynamic Model Router has reached ${metrics['daily_spend']:.2f}. Approaching the ${DAILY_BUDGET_LIMIT:.2f} daily limit."
        try:
            # Send message via OpenClaw CLI to Steve's Discord
            subprocess.Popen([
                "openclaw", "message", "send", 
                "--channel", "discord", 
                "--to", "YOUR_DISCORD_ID", 
                "--message", alert_msg
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
    
    return selected_model, metrics["daily_spend"]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 model_router.py '<task_description>'")
        sys.exit(1)
    task = sys.argv[1]
    model, spend = route_task(task)
    print(model)
