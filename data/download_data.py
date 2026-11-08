"""
Descarga los datos crudos en data/raw/.

1. Home Credit Default Risk (Kaggle). Requisitos:
   - Cuenta en kaggle.com y token de API en ~/.kaggle/kaggle.json
   - Haber aceptado las reglas de la competencia en
     https://www.kaggle.com/competitions/home-credit-default-risk/rules
2. CFPB Consumer Complaint Database (pública, sin registro).
   Ojo: el zip pesa cerca de 1 GB.

Uso (desde la raíz del repo):
    python data/download_data.py
"""
import subprocess
import urllib.request
import zipfile
from pathlib import Path

RAW = Path("data/raw")
RAW.mkdir(parents=True, exist_ok=True)

HOME_CREDIT_FILES = [
    "application_train.csv",
    "bureau.csv",
    "previous_application.csv",
    "installments_payments.csv",
]
CFPB_URL = "https://files.consumerfinance.gov/ccdb/complaints.csv.zip"


def download_home_credit() -> None:
    if all((RAW / f).exists() for f in HOME_CREDIT_FILES):
        print("Home Credit: ya descargado.")
        return
    zip_path = RAW / "home-credit-default-risk.zip"
    if not zip_path.exists():
        print("Home Credit: descargando desde Kaggle…")
        subprocess.run(
            ["kaggle", "competitions", "download",
             "-c", "home-credit-default-risk", "-p", str(RAW)],
            check=True,
        )
    with zipfile.ZipFile(zip_path) as z:
        for f in HOME_CREDIT_FILES:
            print(f"  extrayendo {f}")
            z.extract(f, RAW)


def _progress(blocks: int, block_size: int, total: int) -> None:
    if total > 0:
        pct = min(100, blocks * block_size * 100 // total)
        print(f"\r  {pct}%", end="", flush=True)


def download_cfpb() -> None:
    csv_path = RAW / "complaints.csv"
    if csv_path.exists():
        print("CFPB: ya descargado.")
        return
    zip_path = RAW / "complaints.csv.zip"
    if not zip_path.exists():
        print("CFPB: descargando (~1 GB)…")
        urllib.request.urlretrieve(CFPB_URL, zip_path, _progress)
        print()
    with zipfile.ZipFile(zip_path) as z:
        print("  extrayendo complaints.csv")
        z.extract("complaints.csv", RAW)


if __name__ == "__main__":
    download_home_credit()
    download_cfpb()
    print("Listo. Siguiente paso: python src/build_db.py")
