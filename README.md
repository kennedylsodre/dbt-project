# dbt-olist

Pipeline ELT construído sobre o dataset público [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), com o objetivo de praticar modelagem de dados com dbt no Google BigQuery.

O projeto cobre o fluxo completo: extração dos arquivos CSV, conversão para Parquet, carga em um data lake no Google Cloud Storage, ingestão no BigQuery e transformação em camadas (bronze, silver e gold) seguindo a arquitetura medallion.

**Documentação dos modelos (dbt docs):** [kennedylsodre.github.io/dbt-project](https://kennedylsodre.github.io/dbt-project/)

## Arquitetura

```
Kaggle (CSV)
    |
    v
data/*.csv
    |  docker build + push
    v
Artifact Registry (imagem olist-ingest)
    |  Cloud Run Job executa src/ingestion/ingest_file_gcs.py
    |  (DuckDB: CSV -> Parquet, upload para o GCS)
    v
Google Cloud Storage (Parquet)
    |  Cloud Run Job executa src/ingestion/load_bigquery.py
    |  (GCS -> tabelas raw_* no BigQuery)
    v
BigQuery: raw
    |  dbt
    v
BigQuery: bronze -> silver -> gold
```

| Etapa | Responsável | Descrição |
|---|---|---|
| Extração | Kaggle CLI | Download dos CSVs originais para `data/` |
| Conversão e upload | `ingest_file_gcs.py` (Cloud Run Job) | Converte cada CSV em Parquet (compressão ZSTD) com DuckDB e envia ao bucket |
| Carga | `load_bigquery.py` (Cloud Run Job) | Carrega os Parquet do bucket em tabelas `raw_*` no BigQuery (`WRITE_TRUNCATE`) |
| Transformação | dbt | Tipagem, limpeza, enriquecimento e modelagem dimensional |

## Tecnologias

- **Python 3.13**: scripts de ingestão
- **Poetry**: gerenciamento de dependências, separadas em grupos (`main`, `dbt`, `download`)
- **DuckDB**: conversão de CSV para Parquet
- **Google Cloud Storage**: armazenamento dos arquivos Parquet (data lake)
- **Google BigQuery**: data warehouse
- **dbt (dbt-bigquery 1.12)**: transformação, testes e documentação dos modelos
- **Docker / Docker Compose**: empacotamento dos scripts de ingestão
- **Artifact Registry**: repositório da imagem Docker
- **Cloud Run Jobs**: execução da ingestão na nuvem

## Estrutura do repositório

```
.
├── data/                       # CSVs do Kaggle e instruções de download
├── docs/                       # dbt docs estático publicado no GitHub Pages
├── src/ingestion/
│   ├── ingest_file_gcs.py      # CSV -> Parquet -> GCS
│   ├── load_bigquery.py        # GCS -> BigQuery (raw)
│   └── schema.py               # schemas das tabelas raw
├── dbt_olist/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── bronze/             # views sobre as tabelas raw, com tipagem
│   │   ├── silver/             # tabelas limpas e enriquecidas
│   │   └── gold/               # modelo dimensional e marts analíticos
│   └── tests/                  # testes de dados customizados
├── Dockerfile
├── docker-compose.yml
└── pyproject.toml
```

## Camadas do dbt

### Bronze

Views sobre as tabelas `raw_*`, uma por entidade. Os dados chegam ao BigQuery como `STRING`; nesta camada é feita a conversão para os tipos corretos (timestamp, float, inteiro). Não há regras de negócio.

Modelos: `bronze_orders`, `bronze_customers`, `bronze_geolocation`, `bronze_order_items`, `bronze_order_payments`, `bronze_order_reviews`, `bronze_products`, `bronze_sellers`.

### Silver

Tabelas limpas e enriquecidas:

- padronização de texto (cidade em minúsculas, UF em maiúsculas);
- deduplicação (geolocalização consolidada em uma linha por CEP, reviews por `review_id`);
- enriquecimento com latitude e longitude para clientes e vendedores;
- métricas por pedido em `silver_orders`: tempo de entrega, atraso, valores, quantidade de itens e nota média.

### Gold

Modelo dimensional (star schema) e marts para consumo analítico.

| Tipo | Modelo | Grão |
|---|---|---|
| Dimensão | `dim_customers` | cliente (`customer_unique_id`) |
| Dimensão | `dim_sellers` | vendedor |
| Dimensão | `dim_products` | produto |
| Dimensão | `dim_date` | dia |
| Fato | `fct_orders` | pedido |
| Fato | `fct_order_items` | item de pedido (materialização incremental) |
| Mart | `mart_sales_monthly` | mês x UF x categoria |
| Mart | `mart_seller_performance` | vendedor |
| Mart | `mart_delivery_by_state` | UF x mês |
| Mart | `mart_customer_rfm` | cliente, com segmentação RFM |

`fct_order_items` usa materialização incremental com estratégia `merge`, particionamento por `order_date` e reprocessamento dos últimos 7 dias, para capturar alterações tardias de status e avaliações.

## Configuração

### Pré-requisitos

- Python 3.13 e Poetry
- Projeto no Google Cloud com BigQuery e Cloud Storage habilitados
- Service account com permissões de escrita no BigQuery e no Cloud Storage
- Credenciais da API do Kaggle (para o download dos dados)

### Variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:

```
PROJECT_ID=seu-projeto-gcp
BUCKET_ID=nome-do-bucket
DATASET_ID=olist_raw
```

A chave da service account deve ficar em `secrets/gcp-key.json`. O diretório `secrets/` e o arquivo `.env` não são versionados.

### Perfil do dbt

O projeto usa um perfil chamado `dbt_olist`. Exemplo de `~/.dbt/profiles.yml`:

```yaml
dbt_olist:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      keyfile: /caminho/para/secrets/gcp-key.json
      project: seu-projeto-gcp
      dataset: olist
      location: US
      threads: 4
```

## Ingestão na nuvem

Os dois scripts de ingestão são empacotados em uma única imagem Docker, publicada no Artifact Registry, e executados como Cloud Run Jobs, um para cada etapa. Os CSVs de `data/` são copiados para dentro da imagem no build, e a autenticação no GCP usa a service account associada a cada job.

| Job | Script | Etapa |
|---|---|---|
| `olist-ingest` | `ingest_file_gcs.py` (comando padrão da imagem) | CSV -> Parquet -> GCS |
| `olist-load-bigquery` | `load_bigquery.py` (comando sobrescrito no job) | GCS -> BigQuery |

## Testes

A qualidade dos dados é validada em todas as camadas com testes do dbt. Foram usados dois tipos: testes genéricos, declarados nos arquivos `schema.yml`, e testes singulares, escritos em SQL na pasta `dbt_olist/tests/`.

### Testes genéricos

São os testes nativos do dbt, aplicados a uma coluna e configurados em YAML.

| Teste | O que valida | Onde é usado |
|---|---|---|
| `unique` | A coluna não tem valores repetidos | Chaves primárias (`order_id`, `customer_unique_id`, `product_id`, `seller_id`, `date_day`) |
| `not_null` | A coluna não tem valores nulos | Chaves primárias e estrangeiras, além de campos obrigatórios como valor e data do pedido |
| `relationships` | Todo valor da coluna existe na tabela referenciada (integridade referencial) | Ligações entre pedidos, itens, pagamentos e reviews na bronze, e entre fatos e dimensões na gold |
| `accepted_values` | A coluna só contém valores de uma lista definida | Campos categóricos: status do pedido, tipo de pagamento, nota da avaliação e segmento RFM |

Exemplo:

```yaml
- name: fct_order_items
  columns:
    - name: product_id
      tests:
        - not_null
        - relationships:
            to: ref('dim_products')
            field: product_id
```

### Severidade

Por padrão, um teste que falha interrompe o `dbt build`. Quando uma inconsistência é conhecida e faz parte do próprio dataset, o teste é configurado com `severity: warn`: a falha é registrada como aviso, sem bloquear a execução. É o caso dos CEPs de clientes que não existem na tabela de geolocalização da Olist.

```yaml
- relationships:
    to: ref('bronze_geolocation')
    field: geolocation_zip_code_prefix
    config:
      severity: warn
```

### Testes singulares

São consultas SQL que retornam as linhas que violam uma regra: o teste passa quando a consulta não retorna nenhuma linha. São usados para regras que os testes genéricos não cobrem, como chaves compostas e conciliação de valores entre modelos.

```sql
-- trecho de assert_gold_items_match_orders.sql
-- a soma dos itens (CTE items) deve bater com o total do pedido
select orders.order_id
from {{ ref('fct_orders') }} as orders
inner join items
    on items.order_id = orders.order_id
where abs(orders.order_total_value - items.items_total) > 0.01
```
