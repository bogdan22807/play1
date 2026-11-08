#!/usr/bin/env python3
"""Ставит номер версии и время сборки в data/build.json — видно в игре внизу «Ещё».
Запускать перед экспортом: python3 tools/stamp_build.py"""
import json, re, subprocess
from datetime import datetime, timezone, timedelta
from pathlib import Path
root = Path(__file__).resolve().parents[1]
version = re.search(r'version/name="([^"]+)"', (root / "export_presets.cfg").read_text()).group(1)
count = subprocess.run(["git", "rev-list", "--count", "HEAD"], cwd=root, capture_output=True, text=True).stdout.strip() or "0"
now = datetime.now(timezone(timedelta(hours=1))).strftime("%d.%m %H:%M")
(root / "data" / "build.json").write_text(json.dumps({"version": version, "build": int(count), "time": now}, ensure_ascii=False) + "\n")
print(version, count, now)
