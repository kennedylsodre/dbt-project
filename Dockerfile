# ---------- Estágio 1: instala dependências com Poetry ----------
FROM python:3.13-slim AS builder

ENV POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1

RUN pip install poetry==2.4.1

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

# ---------- Estágio 2: imagem final ----------
FROM python:3.13-slim AS runtime

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

COPY src/ ./src/
COPY data/ ./data/

CMD ["python", "src/ingestion/ingest_file_gcs.py"]