"""Командная строка: python -m drive_sync <команда>."""
import argparse
import sys
from pathlib import Path

from . import auth, sources
from .drive import ensure_path


def main(argv=None) -> None:
    p = argparse.ArgumentParser(prog="drive_sync", description="Загрузка данных на Google Диск")
    p.add_argument("--folder", default="DriveSync", help="корневая папка на Диске (по умолчанию DriveSync)")
    sub = p.add_subparsers(dest="cmd", required=True)

    f = sub.add_parser("files", help="загрузить файлы/папки с компьютера")
    f.add_argument("paths", nargs="+", type=Path)

    g = sub.add_parser("gmail", help="сохранить письма и вложения из Gmail")
    g.add_argument("--query", default="in:inbox newer_than:7d", help="поисковый запрос Gmail")
    g.add_argument("--limit", type=int, default=50)

    w = sub.add_parser("web", help="скачать URL/API и сохранить")
    w.add_argument("url")
    w.add_argument("--name")

    n = sub.add_parser("note", help="сохранить заметку (текст или stdin)")
    n.add_argument("title")
    n.add_argument("text", nargs="?", help="текст; если не указан — читается stdin")

    args = p.parse_args(argv)
    drive = auth.drive_service()
    root = ensure_path(drive, args.folder)

    if args.cmd == "files":
        total = sum(sources.upload_path(drive, path, root) for path in args.paths)
        print(f"Загружено файлов: {total}")
    elif args.cmd == "gmail":
        n_msgs = sources.backup_gmail(auth.gmail_service(), drive, args.query, args.limit, root)
        print(f"Сохранено писем: {n_msgs}")
    elif args.cmd == "web":
        print("Сохранено:", sources.fetch_url(drive, args.url, root, args.name))
    elif args.cmd == "note":
        text = args.text if args.text is not None else sys.stdin.read()
        print("Сохранено:", sources.save_note(drive, args.title, text, root))


if __name__ == "__main__":
    main()
