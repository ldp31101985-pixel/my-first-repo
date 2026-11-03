"""OAuth-авторизация в Google (Drive + Gmail только для чтения)."""
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/drive.file",  # доступ только к файлам, созданным приложением
    "https://www.googleapis.com/auth/gmail.readonly",
]
CREDENTIALS = Path("credentials.json")  # скачивается из Google Cloud Console
TOKEN = Path("token.json")  # создаётся автоматически после первого входа


def get_credentials() -> Credentials:
    creds = None
    if TOKEN.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN), SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not CREDENTIALS.exists():
                raise SystemExit(
                    "Не найден credentials.json. См. README, раздел «Настройка Google Cloud»."
                )
            flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS), SCOPES)
            creds = flow.run_local_server(port=0)
        TOKEN.write_text(creds.to_json())
        TOKEN.chmod(0o600)
    return creds


def drive_service():
    return build("drive", "v3", credentials=get_credentials())


def gmail_service():
    return build("gmail", "v1", credentials=get_credentials())
