#!/usr/bin/env python3
"""Unprivileged AMP initialization. Invoked by systemd as User=amp."""
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile

ROOT = Path("/opt/cubecoders/amp3/data")
SEED = Path("/opt/cubecoders/amp3/seed")


def read_regular(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "r", encoding="utf-8") as source:
        info = os.fstat(source.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
            raise RuntimeError(f"{path.name} must be a single-link regular file")
        return source.read()


def atomic_text(path, text):
    fd, tmp = tempfile.mkstemp(prefix="." + path.name + ".", dir=ROOT)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as output:
            os.fchmod(output.fileno(), 0o640)
            output.write(text)
            output.flush()
            os.fsync(output.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def section(document, name):
    keys = [k for k in document if k.casefold() == name.casefold()]
    if len(keys) > 1:
        raise RuntimeError(f"Ambiguous settings section: {name}")
    key = keys[0] if keys else name
    value = document.setdefault(key, {})
    if not isinstance(value, dict):
        raise RuntimeError(f"Settings section {name} must be an object")
    return value


def set_key(document, name, value):
    keys = [k for k in document if k.casefold() == name.casefold()]
    if len(keys) > 1:
        raise RuntimeError(f"Ambiguous settings key: {name}")
    document[keys[0] if keys else name] = value


def main():
    if os.geteuid() == 0:
        raise RuntimeError("Seed initialization must run as amp, never root")
    os.umask(0o027)
    # Ignore ownership from the archive. Every destination file is created by amp.
    for source in sorted(SEED.iterdir()):
        if source.is_symlink() or not source.is_dir() or not re.fullmatch(r"[0-9][0-9A-Za-z.+-]*", source.name):
            raise RuntimeError("Invalid packaged seed directory")
        target = ROOT / "versions" / source.name
        if os.path.lexists(target):
            if target.is_symlink() or not target.is_dir():
                raise RuntimeError("Seed target is not a real directory")
            payload = target / "webapi" / "webapi"
            if payload.is_file() and os.access(payload, os.X_OK) and not (target / ".blacklisted").exists():
                continue
            raise RuntimeError(f"Existing seed {source.name} is incomplete or blacklisted; preserve it for manual repair")
        stage = Path(tempfile.mkdtemp(prefix=".seed-", dir=ROOT / "versions"))
        try:
            shutil.copytree(source, stage, dirs_exist_ok=True, symlinks=True)
            # Match the upstream data-root privacy boundary before publication.
            for folder, directories, filenames in os.walk(stage, followlinks=False):
                for entry in [Path(folder)] + [Path(folder) / name for name in directories + filenames]:
                    if not entry.is_symlink():
                        mode = stat.S_IMODE(entry.stat().st_mode)
                        entry.chmod(mode & ~0o007)
            os.rename(stage, target)
        finally:
            if stage.exists():
                shutil.rmtree(stage)

    path = ROOT / "appsettings.json"
    settings = json.loads(read_regular(path)) if os.path.lexists(path) else {}
    if not isinstance(settings, dict):
        raise RuntimeError("appsettings.json must contain an object")
    set_key(section(settings, "Spire"), "DefaultContainerMode", "Native")
    origin = os.environ["AMP3_ORIGIN"].rstrip("/")
    if origin != "https://cdn-downloads.c7rs.com/AMP3":
        updates = section(settings, "Updates")
        existing = next((v for k, v in updates.items() if k.casefold() == "manifesturl"), None)
        if existing not in (None, origin + "/manifest.json"):
            raise RuntimeError("AMP3_ORIGIN conflicts with existing update settings")
        set_key(updates, "ManifestUrl", origin + "/manifest.json")
    atomic_text(path, json.dumps(settings, indent=2) + "\n")

    port = os.environ["PORT"]
    previous_port = read_regular(ROOT / "webport.txt").strip() if os.path.lexists(ROOT / "webport.txt") else "8443"
    atomic_text(ROOT / "webport.txt", port + "\n")
    setup_exists = (ROOT / "setup-token.txt").exists()
    if (not setup_exists and not (ROOT / "spire-identity.json").exists()) or (setup_exists and previous_port != port):
        subprocess.run(["/opt/cubecoders/amp3/amp3-host", "reset-setup"],
                       check=True, stdout=subprocess.DEVNULL)
    print("AMP data initialized; setup-link.txt contains the first-run URL when setup is pending.", flush=True)


if __name__ == "__main__":
    main()
