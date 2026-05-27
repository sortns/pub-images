#!/usr/bin/python3.12
"""Synchronize PowerDNS authoritative zones into a recursor forward-zones file."""

import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from datetime import datetime, timezone
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Sync recursor forward-zones from PDNS API")
    parser.add_argument("--env-file", required=True, help="Path to environment-style config file")
    return parser.parse_args()


def utc_timestamp():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log(level, message):
    print(f"{utc_timestamp()} [{level}] {message}")


def read_env_file(path):
    env = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "=" not in stripped:
            raise SystemExit(f"Invalid line in env file {path}: {line!r}")
        key, value = stripped.split("=", 1)
        env[key.strip()] = value.strip()
    return env


def request_json(api_url, api_key, path):
    url = f"{api_url.rstrip('/')}{path}"
    log("INFO", f"Requesting PDNS API: {url}")
    request = urllib.request.Request(
        url=url,
        headers={
            "X-API-Key": api_key,
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            log("INFO", f"PDNS API request succeeded: {url}")
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        log("ERROR", f"PDNS API request failed: {url} HTTP {exc.code} {body}")
        raise SystemExit(f"HTTP {exc.code} for {url}: {body}") from exc


def normalize_zone(name):
    return name.rstrip(".")


def render_forward_zones_yaml(zones, forwarder):
    lines = []
    for zone in zones:
        lines.append(f"- zone: {zone}")
        lines.append("  forwarders:")
        lines.append(f"    - {forwarder}")
    return "\n".join(lines) + ("\n" if lines else "")


def render_nta_lua(zones):
    lines = ["-- Managed automatically by pdns_sync_forward_zones.py"]
    for zone in zones:
        lines.append(
            f'addNTA("{zone}", "forwarded internal authoritative zone")'
        )
    return "\n".join(lines) + "\n"


def file_hash(content):
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def write_if_changed(target, state_file, content):
    target.parent.mkdir(parents=True, exist_ok=True)
    state_file.parent.mkdir(parents=True, exist_ok=True)
    new_hash = file_hash(content)
    old_hash = state_file.read_text(encoding="utf-8").strip() if state_file.exists() else ""
    current_content = target.read_text(encoding="utf-8") if target.exists() else None
    if old_hash == new_hash and current_content == content:
        log("INFO", f"No content change for {target}")
        return False

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=str(target.parent), delete=False) as handle:
        handle.write(content)
        tmp_path = Path(handle.name)
    os.chmod(tmp_path, 0o640)
    tmp_path.replace(target)
    os.chmod(target, 0o640)
    state_file.write_text(new_hash + "\n", encoding="utf-8")
    log("INFO", f"Wrote updated forward-zones file to {target}")
    return True


def apply_ownership(path, owner_name, group_name):
    uid = -1
    gid = -1
    if owner_name:
        import pwd
        uid = pwd.getpwnam(owner_name).pw_uid
    if group_name:
        import grp
        gid = grp.getgrnam(group_name).gr_gid
    if uid != -1 or gid != -1:
        os.chown(path, uid, gid)


def run_command(command):
    log("INFO", f"Executing command: {command}")
    return subprocess.run(
        command,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def main() -> int:
    args = parse_args()
    env = read_env_file(Path(args.env_file))
    log("INFO", f"Loaded sync environment from {args.env_file}")

    api_url = env["PDNS_SYNC_API_URL"]
    api_key = env["PDNS_SYNC_API_KEY"]
    server_id = env.get("PDNS_SYNC_SERVER_ID", "localhost")
    target_file = Path(env["PDNS_SYNC_FORWARD_ZONES_FILE"])
    nta_lua_file = Path(env["PDNS_SYNC_NTA_LUA_FILE"])
    state_file = Path(env["PDNS_SYNC_STATE_FILE"])
    excluded = {
        normalize_zone(item.strip())
        for item in env.get("PDNS_SYNC_EXCLUDE_ZONES", "").split(",")
        if item.strip()
    }
    file_owner = env.get("PDNS_SYNC_FILE_OWNER", "")
    file_group = env.get("PDNS_SYNC_FILE_GROUP", "")
    forwarder = env.get("PDNS_SYNC_FORWARDER", "127.0.0.1:5300")
    reload_command = env.get("PDNS_SYNC_RELOAD_COMMAND", "rec_control reload-zones")
    reload_lua_command = env.get("PDNS_SYNC_RELOAD_LUA_COMMAND", "")
    restart_command = env.get("PDNS_SYNC_RESTART_COMMAND", "")

    zones_payload = request_json(
        api_url,
        api_key,
        f"/servers/{urllib.parse.quote(server_id, safe='')}/zones",
    )
    zones: list[str] = []
    for zone in zones_payload:
        zone_name = normalize_zone(zone["name"])
        kind = zone.get("kind", "")
        if zone_name in excluded:
            continue
        if kind not in {"Native", "Primary", "Master"}:
            continue
        zones.append(zone_name)
    zones = sorted(set(zones))
    log("INFO", f"Collected {len(zones)} authoritative zones from PDNS after exclusions")

    content = render_forward_zones_yaml(zones, forwarder)
    nta_content = render_nta_lua(zones)
    nta_state_file = state_file.with_name(state_file.name + ".nta")
    forward_changed = write_if_changed(target_file, state_file, content)
    nta_changed = write_if_changed(nta_lua_file, nta_state_file, nta_content)
    if target_file.exists():
        apply_ownership(str(target_file), file_owner, file_group)
    if nta_lua_file.exists():
        apply_ownership(str(nta_lua_file), file_owner, file_group)
        os.chmod(nta_lua_file, 0o640)
    if state_file.exists():
        apply_ownership(str(state_file), file_owner, file_group)
        os.chmod(state_file, 0o640)
    if nta_state_file.exists():
        apply_ownership(str(nta_state_file), file_owner, file_group)
        os.chmod(nta_state_file, 0o640)
    log("INFO", f"Discovered {len(zones)} authoritative zones")

    if not forward_changed and not nta_changed:
        log("INFO", "No forward-zones or NTA changes detected")
        return 0

    if forward_changed:
        log("INFO", f"Updated {target_file}")
    if nta_changed:
        log("INFO", f"Updated {nta_lua_file}")

    if forward_changed:
        reload_result = run_command(reload_command)
        if reload_result.stdout:
            print(reload_result.stdout.rstrip())
        if reload_result.returncode != 0:
            if restart_command:
                log("WARNING", "reload-zones failed, restarting recursor")
                restart_result = run_command(restart_command)
                if restart_result.stdout:
                    print(restart_result.stdout.rstrip())
                if restart_result.returncode == 0:
                    log("INFO", "Recursor restart completed successfully")
                else:
                    log("ERROR", f"Recursor restart failed with exit code {restart_result.returncode}")
                return restart_result.returncode
            log("ERROR", f"reload-zones failed with exit code {reload_result.returncode}")
            return reload_result.returncode

    if nta_changed and reload_lua_command:
        reload_lua_result = run_command(reload_lua_command)
        if reload_lua_result.stdout:
            print(reload_lua_result.stdout.rstrip())
        if reload_lua_result.returncode == 0:
            log("INFO", "reload-lua-config completed successfully")
            return 0
        if restart_command:
            log("WARNING", "reload-lua-config failed, restarting recursor")
            restart_result = run_command(restart_command)
            if restart_result.stdout:
                print(restart_result.stdout.rstrip())
            if restart_result.returncode == 0:
                log("INFO", "Recursor restart completed successfully")
            else:
                log("ERROR", f"Recursor restart failed with exit code {restart_result.returncode}")
            return restart_result.returncode
        log("ERROR", f"reload-lua-config failed with exit code {reload_lua_result.returncode}")
        return reload_lua_result.returncode

    log("INFO", "Sync completed successfully")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
