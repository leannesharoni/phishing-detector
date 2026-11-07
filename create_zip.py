
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
output = root / "deploy" / "app.zip"

files = [
    "app.py",
    "detector.py",
    "database.py",
    "cache.py",
    "cloud_database.py",
    "requirements-cloud.txt",
    "templates/index.html",
    "templates/history.html",
]

output.parent.mkdir(exist_ok=True)

with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for filename in files:
        path = root / filename

        if not path.is_file():
            raise FileNotFoundError(path)

        archive.write(path, arcname=filename)

with ZipFile(output) as archive:
    for name in archive.namelist():
        print(name)
        assert "\\" not in name

print("ZIP created successfully!")
