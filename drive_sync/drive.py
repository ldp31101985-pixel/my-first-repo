"""Работа с Google Диском: папки и загрузка файлов."""
import mimetypes

from googleapiclient.http import MediaInMemoryUpload

FOLDER_MIME = "application/vnd.google-apps.folder"


def _escape(name: str) -> str:
    return name.replace("\\", "\\\\").replace("'", "\\'")


def ensure_folder(svc, name: str, parent: str | None = None) -> str:
    """Возвращает id папки, создавая её при отсутствии."""
    q = f"name = '{_escape(name)}' and mimeType = '{FOLDER_MIME}' and trashed = false"
    q += f" and '{parent or 'root'}' in parents"
    found = svc.files().list(q=q, fields="files(id)", pageSize=1).execute().get("files", [])
    if found:
        return found[0]["id"]
    meta = {"name": name, "mimeType": FOLDER_MIME}
    if parent:
        meta["parents"] = [parent]
    return svc.files().create(body=meta, fields="id").execute()["id"]


def ensure_path(svc, path: str) -> str:
    """'Backup/Gmail/2026' -> id вложенной папки."""
    parent = None
    for part in filter(None, path.split("/")):
        parent = ensure_folder(svc, part, parent)
    return parent or "root"


def upload_bytes(svc, data: bytes, name: str, folder_id: str, mime: str | None = None) -> str:
    """Загружает данные; если файл с таким именем уже есть в папке — обновляет его."""
    mime = mime or mimetypes.guess_type(name)[0] or "application/octet-stream"
    media = MediaInMemoryUpload(data, mimetype=mime, resumable=len(data) > 5 * 1024 * 1024)
    q = f"name = '{_escape(name)}' and '{folder_id}' in parents and trashed = false"
    found = svc.files().list(q=q, fields="files(id)", pageSize=1).execute().get("files", [])
    if found:
        return svc.files().update(fileId=found[0]["id"], media_body=media, fields="id").execute()["id"]
    meta = {"name": name, "parents": [folder_id]}
    return svc.files().create(body=meta, media_body=media, fields="id").execute()["id"]
