import os
import re

BASE_DIR = "/path/to/openclaw/workspace"
ARGENT_DIR = os.path.join(BASE_DIR, "argent", "memory")
FACTS_DIR = os.path.join(ARGENT_DIR, "facts")
LOGS_DIR = os.path.join(ARGENT_DIR, "logs")
SCRIPTS_DIR = os.path.join(BASE_DIR, "argent", "scripts")

os.makedirs(FACTS_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)
os.makedirs(SCRIPTS_DIR, exist_ok=True)

def read_file(filename):
    path = os.path.join(BASE_DIR, filename)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    return ""

def write_file(path, content):
    if not content.strip(): return
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")

print("Starting memory migration to HAM structure...")

# 1. Generate core.md (The Slug)
user_md = read_file("USER.md")
identity_md = read_file("IDENTITY.md")
soul_md = read_file("SOUL.md")

core_content = f"# CORE IDENTITY & USER\n\n{identity_md}\n\n{user_md}\n\n{soul_md}"
write_file(os.path.join(ARGENT_DIR, "core.md"), core_content)
print(f"Created: {os.path.join(ARGENT_DIR, 'core.md')}")

# 2. Extract facts from TOOLS.md
tools_md = read_file("TOOLS.md")
if tools_md:
    tools_sections = re.split(r'\n## ', "\n" + tools_md)
    for section in tools_sections[1:]:
        if not section.strip(): continue
        lines = section.split('\n')
        title = lines[0].strip()
        body = '\n'.join(lines[1:]).strip()
        
        # Sanitize filename
        safe_name = re.sub(r'[^a-z0-9]+', '_', title.lower()).strip('_')
        filename = f"tools_{safe_name}.md"
        write_file(os.path.join(FACTS_DIR, filename), f"# {title}\n\n{body}")
        print(f"Created Fact: {filename}")

# 3. Extract facts from MEMORY.md
memory_md = read_file("MEMORY.md")
if memory_md:
    mem_sections = re.split(r'\n## ', "\n" + memory_md)
    for section in mem_sections[1:]:
        if not section.strip() or section.startswith("MEMORY.md - Long-Term"): continue
        lines = section.split('\n')
        title = lines[0].strip()
        body = '\n'.join(lines[1:]).strip()
        
        safe_name = re.sub(r'[^a-z0-9]+', '_', title.lower()).strip('_')
        filename = f"memory_{safe_name}.md"
        write_file(os.path.join(FACTS_DIR, filename), f"# {title}\n\n{body}")
        print(f"Created Fact: {filename}")

print("Migration complete! Original files remain untouched.")
