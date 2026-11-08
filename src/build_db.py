"""
Construye la base de datos DuckDB (data/banco.duckdb) ejecutando los
scripts SQL en orden. Uso (desde la raíz del repo):
    python src/build_db.py
"""
import time
from pathlib import Path

import duckdb

DB_PATH = Path("data/banco.duckdb")
SQL_FILES = [Path("sql/01_raw.sql"), Path("sql/02_core.sql")]


def main() -> None:
    con = duckdb.connect(str(DB_PATH))
    for sql_file in SQL_FILES:
        t0 = time.time()
        print(f"Ejecutando {sql_file} …", end=" ", flush=True)
        con.execute(sql_file.read_text(encoding="utf-8"))
        print(f"{time.time() - t0:.1f} s")

    print("\nFilas por tabla (schema core):")
    tablas = con.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema = 'core' ORDER BY table_name"
    ).fetchall()
    for (tabla,) in tablas:
        n = con.execute(f"SELECT count(*) FROM core.{tabla}").fetchone()[0]
        print(f"  {tabla:<22}{n:>12,}")
    con.close()


if __name__ == "__main__":
    main()
