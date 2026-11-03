# my-first-repo

Учебный репозиторий для знакомства с Git и GitHub: ветки, коммиты и pull request'ы.

## Как предложить изменение

1. Создайте ветку от `main`: `git switch -c имя-ветки`
2. Внесите правки и сделайте коммит: `git add .` и `git commit -m "Короткое описание"`
3. Отправьте ветку на GitHub: `git push -u origin имя-ветки`
4. Откройте pull request: `gh pr create`

---

## drive_sync — всё на Google Диск

Python-CLI, который по команде кладёт на Google Диск (в папку `DriveSync`):

| Команда | Что делает | Куда на Диске |
|---|---|---|
| `files <пути>` | файлы и папки с компьютера (рекурсивно) | `DriveSync/<имя папки>/…` |
| `gmail` | письма (`.eml`) и вложения по поиску Gmail | `DriveSync/Gmail/<тема>/` |
| `web <url>` | страница или JSON из API | `DriveSync/Web/` |
| `note <заголовок> [текст]` | заметка/результат работы Claude (`.md`, текст или stdin) | `DriveSync/Notes/` |

Повторная загрузка файла с тем же именем в ту же папку **обновляет** его, а не дублирует.

### Настройка Google Cloud (один раз)
1. [console.cloud.google.com](https://console.cloud.google.com) → создать проект.
2. «APIs & Services» → включить **Google Drive API** и **Gmail API**.
3. «OAuth consent screen» → External, добавить себя в Test users.
4. «Credentials» → Create → **OAuth client ID** → Desktop app → скачать JSON как `credentials.json` в корень проекта.
5. При первом запуске откроется браузер для входа; токен сохранится в `token.json`.

`credentials.json` и `token.json` в `.gitignore` — не коммитьте их.

### Запуск
```bash
pip install -r requirements.txt
python -m drive_sync files ~/Documents/report.pdf ~/Projects
python -m drive_sync gmail --query "has:attachment newer_than:30d" --limit 100
python -m drive_sync web https://api.github.com/repos/python/cpython
echo "Итоги исследования…" | python -m drive_sync note "Итоги"
```
Корневую папку Диска можно сменить: `--folder "Мой архив"`.

Права: `drive.file` (приложение видит только созданные им файлы) и `gmail.readonly` (письма только читаются).

### Тесты
```bash
pip install pytest && pytest
```
