# Riesgo crediticio y reclamos con IA

Plataforma de analítica para un banco minorista que combina dos casos de uso de inteligencia artificial sobre una misma base de datos de clientes:

1. **Scoring de riesgo crediticio:** estimar la probabilidad de impago de una solicitud de crédito y traducirla en decisiones de negocio (punto de corte, tasa de aprobación, pérdida esperada).
2. **Clasificación de reclamos:** asignar automáticamente cada reclamo a su categoría y nivel de urgencia, comparando un modelo clásico, embeddings y un modelo de lenguaje (LLM).

**Stack:** Python · SQL (DuckDB) · pandas · scikit-learn · SHAP · Streamlit

> **Aviso sobre los datos.** El proyecto usa datos públicos: *Home Credit Default Risk* (Kaggle) para crédito y la *Consumer Complaint Database* de la CFPB (EE. UU.) para reclamos. No contiene datos de ninguna entidad financiera peruana. La relación entre reclamos y clientes es simulada para poder trabajar con una sola base de datos.

## Estructura

```
credit-risk-complaints-ai/
├── data/
│   └── download_data.py   # descarga los datos crudos
├── sql/
│   ├── 01_raw.sql         # carga de CSV a la capa raw
│   ├── 02_core.sql        # modelo de datos limpio, en español
│   └── 03_eda.sql         # análisis exploratorio
├── src/
│   ├── build_db.py        # construye data/banco.duckdb
│   └── run_eda.py         # ejecuta y muestra el análisis exploratorio
├── notebooks/
├── app/                   # dashboard (próximamente)
└── requirements.txt
```

## Modelo de datos (schema `core`)

| Tabla | Descripción |
|---|---|
| `clientes` | Datos demográficos y laborales del cliente |
| `solicitudes` | Solicitud de crédito actual y variable objetivo `impago` |
| `buro_creditos` | Créditos del cliente en otras entidades (central de riesgos) |
| `solicitudes_previas` | Solicitudes anteriores en la misma entidad |
| `pagos_cuotas` | Historial de pago de cuotas, con días de atraso |
| `reclamos` | Reclamos de clientes con texto, categoría y respuesta |

## Cómo ejecutarlo

```bash
python -m venv .venv
source .venv/bin/activate          # en Windows: .venv\Scripts\activate
pip install -r requirements.txt

python data/download_data.py       # requiere token de Kaggle (ver el script)
python src/build_db.py             # crea data/banco.duckdb
python src/run_eda.py              # análisis exploratorio
```

## Hoja de ruta

- [x] Semana 1 · Base de datos y análisis exploratorio en SQL
- [ ] Semana 2 · Modelo de scoring (regresión logística y gradient boosting, SHAP, simulación de negocio)
- [ ] Semana 3 · Clasificación de reclamos (TF-IDF, embeddings, LLM) y reclamos en español
- [ ] Semana 4 · Dashboard en Streamlit y despliegue

## Autor

Gabriel Cabrera · [GitHub](https://github.com/tefaltaxabor)
