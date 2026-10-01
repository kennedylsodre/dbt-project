# Download de Datasets via Kaggle CLI

## Pré-requisitos

- Python instalado
- Poetry instalado
- Conta no Kaggle
- API Token gerado

## 1. Instalar a CLI

```bash
poetry add kaggle
```

Verifique a instalação:

```bash
poetry run kaggle --version
```

---

## 2. Gerar um API Token

1. Acesse: https://www.kaggle.com/settings
2. Vá até a seção **API**.
3. Clique em **Generate New Token**.

Será exibido um token semelhante a:

```text
KGAT_xxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 3. Configurar autenticação

### Opção A (Recomendada)

Utilize autenticação via navegador:

```bash
poetry run kaggle auth login
```

---

### Opção B

Crie o arquivo:

```text
C:\Users\<SEU_USUARIO>\.kaggle\access_token
```

Conteúdo:

```text
KGAT_xxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### Opção C

Defina a variável de ambiente para a sessão atual do PowerShell:

```powershell
$env:KAGGLE_API_TOKEN="KGAT_xxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

## 4. Pesquisar datasets

```bash
poetry run kaggle datasets list -s olist
```

---

## 5. Baixar um dataset

```bash
poetry run kaggle datasets download \
    -d olistbr/brazilian-ecommerce \
    -p data/raw \
    --unzip
```

No Windows (uma única linha):

```bash
poetry run kaggle datasets download -d olistbr/brazilian-ecommerce -p data --unzip
```

---

## Estrutura esperada

```text
data/
    ├── olist_customers_dataset.csv
    ├── olist_geolocation_dataset.csv
    ├── olist_order_items_dataset.csv
    ├── olist_order_payments_dataset.csv
    ├── olist_order_reviews_dataset.csv
    ├── olist_orders_dataset.csv
    ├── olist_products_dataset.csv
    ├── olist_sellers_dataset.csv
    ├── product_category_name_translation.csv
    └── ...
```