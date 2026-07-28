from dotenv import load_dotenv
from google.cloud import storage
import os
from pathlib import Path

load_dotenv()

PROJECT_ID = os.getenv('PROJECT_ID')
BUCKET_ID = os.getenv('BUCKET_ID')

client = storage.Client(project=PROJECT_ID)

try: 
    print('Verificando se o bucket já existe')
    bucket = client.create_bucket(
        BUCKET_ID,
        location="US"
    )
    print('Bucket não existia e foi criado')
except Exception as e:
    print('Bucket já existia')
    bucket = client.get_bucket(BUCKET_ID)
    print('Bucket setado')


BASE_DIR = Path(__file__).resolve().parents[2]

DATA_DIR = BASE_DIR / "data"

for file in DATA_DIR.iterdir():
    if file.suffix == ".csv":
        blob_name = file.name.replace('_dataset', '')  
        print(f'Fazendo upload do arquivo {file.name} como {blob_name}')
        file_upload = bucket.blob(blob_name)
        file_upload.upload_from_filename(str(file))    
        print(f'Upload do arquivo {blob_name} concluído')