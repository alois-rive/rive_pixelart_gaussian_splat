#!/usr/bin/env python3
"""Generate one image with Codex's image generation tool, into a known file, with a record.

  codex_image.py --brief art/<a>/sheet.v1.prompt.md --out art/<a>/sheet.v1.png [--image ref.png ...]
  codex_image.py --brief ... --out ... --dry-run          print the command and the full prompt

It runs `codex exec` non-interactively (the agent inside Codex has an image tool),
tells it to copy the one image it makes to --out, and falls back to taking it from
~/.codex/generated_images/<session id>/ when the agent did not copy it. Beside the
image it writes <out>.json (brief, inputs, hashes, session, seconds, reviewed: false)
and <out>.events.jsonl.

A generation is never overwritten: the next attempt is the next version (sheet.v2.png).
Exit 0 ok, 1 ambiguous (several images; look and choose), 2 usage, 3 codex failed.
"""
import argparse
import glob
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import time

APP_CODEX = "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
GENERATED = os.path.expanduser(os.path.join(os.environ.get("CODEX_HOME", "~/.codex"), "generated_images"))

WRAPPER = """You are producing exactly one image file for a 3D asset pipeline.

1. Use your image generation tool once to make the image described in the brief below.{inputs}
2. Copy the generated image with a shell command to this exact path, creating nothing else:
       {out}
3. Do not edit, crop, resize, convert or post-process the image, do not write any other
   file, and do not generate a second image.
4. Reply with the single line: saved {out}

The brief:

{brief}
"""


def die(msg, code=2):
    print("codex_image.py: " + msg, file=sys.stderr)
    sys.exit(code)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return list(struct.unpack(">II", head[16:24]))


def find_codex(explicit):
    for cand in (explicit, os.environ.get("CODEX_BIN"), shutil.which("codex"), APP_CODEX):
        if cand and os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    die("no codex CLI: install it, pass --codex or set CODEX_BIN", 3)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--brief", required=True, help="the brief, a .prompt.md file kept beside the image")
    ap.add_argument("--out", required=True, help="the PNG to write (must not exist)")
    ap.add_argument("--image", action="append", default=[], help="an image to attach (repeatable)")
    ap.add_argument("--codex")
    ap.add_argument("--model")
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    out = os.path.abspath(a.out)
    if not out.endswith(".png"):
        die("--out must be a .png")
    if os.path.exists(out) and not a.dry_run:
        die(f"{a.out} exists: the next attempt is a new version (.v2.png)")
    brief = open(a.brief, encoding="utf-8").read().strip()
    images = [os.path.abspath(i) for i in a.image]
    for i in images:
        if not os.path.isfile(i):
            die(f"no such image {i}")
    inputs = ""
    if images:
        names = ", ".join(os.path.basename(i) for i in images)
        inputs = f"\n   The attached image(s) ({names}) are references: follow the brief about what to keep from them."
    prompt = WRAPPER.format(inputs=inputs, out=out, brief=brief)
    workdir = os.path.dirname(out)
    os.makedirs(workdir, exist_ok=True)
    codex = find_codex(a.codex)
    cmd = [codex, "exec", "--json", "--skip-git-repo-check", "-s", "workspace-write", "-C", workdir,
           "-o", out + ".last.txt"]
    if a.model:
        cmd += ["-m", a.model]
    for i in images:
        cmd += ["-i", i]
    cmd += ["--", prompt]  # `--`: -i takes several values and would swallow the prompt
    if a.dry_run:
        print(" ".join(cmd[:-1]) + " <prompt>\n")
        print(prompt)
        return 0

    version = subprocess.run([codex, "--version"], capture_output=True, text=True).stdout.strip()
    t0 = time.time()
    try:
        run = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=a.timeout)
    except subprocess.TimeoutExpired:
        die(f"codex did not finish in {a.timeout} s", 3)
    took = time.time() - t0
    thread, reply = None, None
    for line in run.stdout.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "thread.started":
            thread = ev.get("thread_id")
        item = ev.get("item") or {}
        if item.get("type") == "agent_message" and item.get("text"):
            reply = item["text"]
    with open(out + ".events.jsonl", "w", encoding="utf-8") as f:
        f.write(run.stdout)
    candidates = sorted(glob.glob(os.path.join(GENERATED, thread or "-", "*.png")), key=os.path.getmtime)
    source = None
    if os.path.exists(out):
        digest = sha256(out)
        source = next((c for c in candidates if sha256(c) == digest), None)
    elif candidates:
        source = candidates[-1]
        shutil.copyfile(source, out)
    else:
        sys.stderr.write(run.stderr[-3000:])
        die(f"no image: codex exited {run.returncode}, session {thread}", 3)
    record = {
        "image": os.path.basename(out), "sha256": sha256(out), "size": png_size(out),
        "brief_file": os.path.relpath(os.path.abspath(a.brief), workdir), "brief": brief,
        "inputs": [{"path": os.path.relpath(i, workdir), "sha256": sha256(i)} for i in images],
        "generator": {"cli": version, "model": a.model, "session": thread, "source": source,
                      "candidates": candidates},
        "seconds": round(took, 1), "created": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "reply": reply, "reviewed": False,
    }
    with open(out + ".json", "w", encoding="utf-8") as f:
        json.dump(record, f, indent=2)
        f.write("\n")
    print(f"{a.out} {'x'.join(map(str, record['size'] or []))} {took:.0f} s session {thread}")
    if len(candidates) > 1:
        print(f"warning: the session made {len(candidates)} images; look at them:\n  " + "\n  ".join(candidates),
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
