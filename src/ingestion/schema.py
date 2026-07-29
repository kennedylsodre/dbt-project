from google.cloud import bigquery

TABLE_SCHEMAS = {
    "olist_orders": [
        bigquery.SchemaField('order_id', "STRING", mode="REQUIRED"),
        bigquery.SchemaField('customer_id', "STRING", mode="REQUIRED"),
        bigquery.SchemaField('order_status', "STRING"),
        bigquery.SchemaField('order_purchase_timestamp', "STRING"),
        bigquery.SchemaField('order_approved_at', "STRING"),
        bigquery.SchemaField('order_delivered_carrier_date', "STRING"),
        bigquery.SchemaField('order_delivered_customer_date', "STRING"),
        bigquery.SchemaField('order_estimated_delivery_date', "STRING")
    ],
    "olist_products": [
        bigquery.SchemaField('product_id', 'STRING'),
        bigquery.SchemaField('product_category_name', 'STRING'),
        bigquery.SchemaField('product_name_lenght', 'STRING'),
        bigquery.SchemaField('product_description_lenght', 'STRING'),
        bigquery.SchemaField('product_photos_qty', 'STRING'),
        bigquery.SchemaField('product_weight_g', 'STRING'),
        bigquery.SchemaField('product_length_cm', 'STRING'),
        bigquery.SchemaField('product_height_cm', 'STRING'),
        bigquery.SchemaField('product_width_cm', 'STRING'),
    ],
    "olist_sellers": [
        bigquery.SchemaField('seller_id', 'STRING'),
        bigquery.SchemaField('seller_zip_code_prefix', 'STRING'),
        bigquery.SchemaField('seller_city', 'STRING'),
        bigquery.SchemaField('seller_state', 'STRING'),
    ],
    "olist_order_payments": [
        bigquery.SchemaField('order_id','STRING'),
        bigquery.SchemaField('payment_sequential','STRING'),
        bigquery.SchemaField('payment_type','STRING'),
        bigquery.SchemaField('payment_installments','STRING'),
        bigquery.SchemaField('payment_value','STRING'),
    ],
    "olist_order_items":[
        bigquery.SchemaField('order_id','STRING'),
        bigquery.SchemaField('order_item_id','STRING'),
        bigquery.SchemaField('product_id','STRING'),
        bigquery.SchemaField('seller_id','STRING'),
        bigquery.SchemaField('shipping_limit_date','STRING'),
        bigquery.SchemaField('price','STRING'),
        bigquery.SchemaField('freight_value','STRING'),
    ],
    "olist_geolocation": [
        bigquery.SchemaField('geolocation_zip_code_prefix','STRING'),
        bigquery.SchemaField('geolocation_lat','STRING'),
        bigquery.SchemaField('geolocation_lng','STRING'),
        bigquery.SchemaField('geolocation_city','STRING'),
        bigquery.SchemaField('geolocation_state','STRING'),    
    ],
    "olist_customers": [
        bigquery.SchemaField('customer_id','STRING'),
        bigquery.SchemaField('customer_unique_id','STRING'),
        bigquery.SchemaField('customer_zip_code_prefix','STRING'),
        bigquery.SchemaField('customer_city','STRING'),
        bigquery.SchemaField('customer_state','STRING'),
    ],
    'olist_product_category_name_translation':[
        bigquery.SchemaField('string_field_0','STRING'),
        bigquery.SchemaField('string_field_1','STRING'),
    ]
}

