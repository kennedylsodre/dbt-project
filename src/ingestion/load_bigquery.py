from dotenv import load_dotenv
from google.cloud import bigquery, storage
from pathlib import Path
import os

from schema import TABLE_SCHEMAS

load_dotenv()

PROJECT_ID = os.getenv('PROJECT_ID')
BUCKET_ID = os.getenv('BUCKET_ID')
DATASET_ID = os.getenv('DATASET_ID')

bq_client = bigquery.Client(project=PROJECT_ID)
storage_client = storage.Client(project=PROJECT_ID)

bucket = storage_client.bucket(BUCKET_ID)
blobs = bucket.list_blobs()



try:
    print('Verificando se o dataset já existe')
    dataset = bq_client.create_dataset(DATASET_ID)
    print('Dataset não existia e foi criado')
except Exception:
    print('Dataset já existia')
    dataset = bq_client.get_dataset(DATASET_ID)
    print('Dataset setado')

for blob in blobs:
    if blob.name.endswith('csv'):
        table_name = blob.name.replace('olist','raw').replace('.csv','')
        table_id = f'{PROJECT_ID}.{DATASET_ID}.{table_name}'
        uri = f'gs://{BUCKET_ID}/{blob.name}'

        schema = TABLE_SCHEMAS.get(blob.name.replace('.csv',''))

        job_config = bigquery.LoadJobConfig(
                        source_format=bigquery.SourceFormat.CSV,
                        skip_leading_rows=1,
                        autodetect=False,
                        schema = schema,
                        write_disposition="WRITE_APPEND"
                    )

        print(f'Fazendo upload da tabela {table_id}')
        try:
            load_job = bq_client.load_table_from_uri(uri, table_id,job_config=job_config)
            load_job.result()
        except Exception as e:
            print(f'Upload da tabela {table_id} falhou')
            print(e)