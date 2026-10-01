from dotenv import load_dotenv
from google.api_core.exceptions import Conflict
import duckdb
from google.cloud import storage
import os
from pathlib import Path

load_dotenv()
PROJECT_ID = os.getenv('PROJECT_ID')
BUCKET_ID = os.getenv('BUCKET_ID')
client = storage.Client(project=PROJECT_ID)

DATA_DIR = Path.cwd() / 'data'
TMP_DIR = Path.cwd() / 'data' / 'tmp_parquet'
TMP_DIR.mkdir(parents=True, exist_ok=True)


def csv_to_parquet(csv_path: str, parquet_path: str):
    query = f"""
        COPY (
            SELECT * FROM read_csv_auto('{csv_path}', all_varchar=true)
        )
        TO '{parquet_path}'
        (FORMAT PARQUET, COMPRESSION ZSTD)
    """
    return duckdb.sql(query)


print('Verificando se o bucket já existe')
try:
    bucket = client.create_bucket(BUCKET_ID, location="US")
    print('Bucket não existia e foi criado')
except Conflict:
    bucket = client.get_bucket(BUCKET_ID)
    print('Bucket já existia, setado')


for file in os.listdir(DATA_DIR):
    if not file.endswith('.csv'):
        continue

    csv_path = DATA_DIR / file
    parquet_path = TMP_DIR / f"{Path(file).stem}.parquet"
    blob_name = f"{Path(file).stem.replace('_dataset','')}.parquet"

    print(f'Convertendo {file}')
    csv_to_parquet(str(csv_path), str(parquet_path))

    print(f'Fazendo upload como {blob_name}')
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(parquet_path))
    print(f'Upload de {blob_name} concluído')

    os.remove(parquet_path)