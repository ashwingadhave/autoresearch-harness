#!/usr/bin/env python3
"""Split a claude -p stream-json transcript (agent.jsonl) into readable pieces.

Writes next to it:
  agent.log         every piece of text the agent wrote, in order
  agent.tools.txt   every tool call, one per line: TOOL  key-argument
  agent.stats.json  turns, tool calls, cost, duration, stop reason
"""
import json, os, sys

src = sys.argv[1]
d = os.path.dirname(src)
texts, tools, stats = [], [], {}
for line in open(src, errors="ignore"):
    line = line.strip()
    if not line: continue
    try: ev = json.loads(line)
    except json.JSONDecodeError: continue
    t = ev.get("type")
    if t == "assistant":
        for block in ev.get("message", {}).get("content", []):
            if block.get("type") == "text" and block.get("text", "").strip():
                texts.append(block["text"].strip())
            elif block.get("type") == "tool_use":
                inp = block.get("input", {})
                key = inp.get("file_path") or inp.get("command") or inp.get("pattern") or inp.get("path") or ""
                tools.append(f"{block.get('name','?'):8s} {str(key)[:160]}")
    elif t == "result":
        stats = {k: ev.get(k) for k in ("num_turns", "duration_ms", "duration_api_ms", "total_cost_usd", "stop_reason", "is_error", "subtype")}
        if ev.get("result") and str(ev["result"]).strip() and (not texts or texts[-1] != ev["result"].strip()):
            texts.append(str(ev["result"]).strip())
stats["tool_calls"] = len(tools)
stats["text_blocks"] = len(texts)
open(os.path.join(d, "agent.log"), "w").write("\n\n".join(texts) + ("\n" if texts else "(agent wrote no text)\n"))
open(os.path.join(d, "agent.tools.txt"), "w").write("\n".join(tools) + "\n")
json.dump(stats, open(os.path.join(d, "agent.stats.json"), "w"), indent=1)
print(f"turns={stats.get('num_turns')} tools={len(tools)} text_blocks={len(texts)} cost=${stats.get('total_cost_usd')}")
