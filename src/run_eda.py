"""
Ejecuta las consultas de sql/03_eda.sql y muestra los resultados.
Uso (desde la raíz del repo):
    python src/run_eda.py                 # todas las consultas
    python src/run_eda.py reclamos        # solo las que contienen "reclamos"
"""
import re
import sys
from pathlib import Path

import duckdb
import pandas as pd

DB_PATH = "data/banco.duckdb"
EDA_FILE = Path("sql/03_eda.sql")


def load_queries(path: Path) -> dict[str, str]:
    """Separa el archivo en consultas usando los marcadores '-- name: …'."""
    partes = re.split(r"^-- name:\s*(\w+)\s*$", path.read_text(encoding="utf-8"),
                      flags=re.MULTILINE)
    # partes = [encabezado, nombre1, sql1, nombre2, sql2, …]
    return {partes[i]: partes[i + 1].strip() for i in range(1, len(partes), 2)}


def main() -> None:
    filtro = sys.argv[1] if len(sys.argv) > 1 else ""
    pd.set_option("display.width", 140)
    pd.set_option("display.max_colwidth", 60)
    con = duckdb.connect(DB_PATH, read_only=True)
    for nombre, sql in load_queries(EDA_FILE).items():
        if filtro not in nombre:
            continue
        print(f"\n=== {nombre} ===")
        print(con.execute(sql).df().to_string(index=False))
    con.close()


if __name__ == "__main__":
    main()
