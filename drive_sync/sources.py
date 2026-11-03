"""Источники данных: локальные файлы, Gmail, веб/API, заметки."""
import base64
import json
import re
from datetime import datetime
from email import message_from_bytes
from pathlib import Path

import requests

from .drive import ensure_folder, upload_bytes


def safe_name(text: str, limit: int = 80) -> str:
    return re.sub(r'[\\/:*?"<>|\r\n]+', "_", text).strip()[:limit] or "untitled"


# --- локальные файлы / папки ---------------------------------------------
def upload_path(svc, local: Path, root_id: str) -> int:
    """Рекурсивно загружает файл или папку. Возвращает число файлов."""
    local = local.expanduser()
    if not local.exists():
        raise SystemExit(f"Путь не найден: {local}")
    if local.is_file():
        upload_bytes(svc, local.read_bytes(), local.name, root_id)
        return 1
    count = 0
    base = ensure_folder(svc, local.name, root_id)
    cache = {Path("."): base}
    for p in sorted(local.rglob("*")):
        rel = p.relative_to(local)
        if p.is_dir():
            cache[rel] = ensure_folder(svc, p.name, cache[rel.parent])
        elif p.is_file():
            upload_bytes(svc, p.read_bytes(), p.name, cache[rel.parent])
            count += 1
    return count


# --- Gmail ----------------------------------------------------------------
def backup_gmail(gmail, svc, query: str, limit: int, root_id: str) -> int:
    """Сохраняет письма (.eml) и вложения по поиску Gmail-запроса."""
    gm_folder = ensure_folder(svc, "Gmail", root_id)
    ids, token = [], None
    while len(ids) < limit:
        resp = gmail.users().messages().list(
            userId="me", q=query, maxResults=min(100, limit - len(ids)), pageToken=token
        ).execute()
        ids += [m["id"] for m in resp.get("messages", [])]
        token = resp.get("nextPageToken")
        if not token:
            break
    for mid in ids:
        raw = gmail.users().messages().get(userId="me", id=mid, format="raw").execute()["raw"]
        eml = base64.urlsafe_b64decode(raw)
        msg = message_from_bytes(eml)
        stamp = datetime.now().strftime("%Y%m%d")
        folder = ensure_folder(svc, f"{safe_name(msg.get('Subject', ''), 50)} [{mid[:8]}]", gm_folder)
        upload_bytes(svc, eml, f"message_{stamp}.eml", folder, "message/rfc822")
        for part in msg.walk():
            fname = part.get_filename()
            if fname:
                upload_bytes(svc, part.get_payload(decode=True) or b"", safe_name(fname, 120), folder)
    return len(ids)


# --- веб / API ------------------------------------------------------------
def fetch_url(svc, url: str, root_id: str, name: str | None = None) -> str:
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    ctype = resp.headers.get("content-type", "application/octet-stream").split(";")[0]
    data = resp.content
    if "json" in ctype:  # красиво форматируем JSON
        data = json.dumps(resp.json(), ensure_ascii=False, indent=2).encode()
    ext = ".json" if "json" in ctype else ".html" if "html" in ctype else ".txt" if "text" in ctype else ""
    fname = name or f"{safe_name(url.split('//')[-1], 60)}_{datetime.now():%Y%m%d_%H%M}{ext}"
    folder = ensure_folder(svc, "Web", root_id)
    upload_bytes(svc, data, fname, folder, ctype)
    return fname


# --- заметки / результаты Claude -----------------------------------------
def save_note(svc, title: str, text: str, root_id: str) -> str:
    folder = ensure_folder(svc, "Notes", root_id)
    fname = f"{datetime.now():%Y-%m-%d_%H%M}_{safe_name(title)}.md"
    upload_bytes(svc, f"# {title}\n\n{text}\n".encode(), fname, folder, "text/markdown")
    return fname
