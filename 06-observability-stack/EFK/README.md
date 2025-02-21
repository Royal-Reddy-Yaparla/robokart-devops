# Elasticsearch

Elasticsearch is a distributed, RESTful search and analytics engine designed for scalability, real-time data indexing, and search capabilities. It is commonly used in log analytics, full-text search, and as part of the **EFK Stack (Elasticsearch, Fluentd, Kibana)** for log monitoring.

---

## 1️⃣ Cluster Architecture in Elasticsearch

### **Elasticsearch Cluster Nodes**
An Elasticsearch cluster consists of multiple **nodes**, each serving a specific role:
- **Master Node**: Manages the cluster, including index creation, deletion, and node allocation.
- **Data Nodes**: Store and process data, handling search and aggregation operations.
- **Ingest Nodes**: Perform pre-processing before indexing documents.
- **Coordinating Nodes**: Distribute search and indexing requests across the cluster.

### **Cluster Health & Management**
To check the cluster’s health:
```json
GET /_cluster/health
```
Status can be **green** (all shards allocated), **yellow** (replicas unassigned), or **red** (primary shards unassigned).

To view node details:
```json
GET /_nodes
```

---

## 2️⃣ Indexing in Elasticsearch

### **What is an Index?**
An **index** is a logical namespace that groups related documents in Elasticsearch.

### **Creating an Index**
```json
PUT /products
```

### **Deleting an Index**
```json
DELETE /products
```

### **Listing Indices**
```json
GET /_cat/indices
```

---

## 3️⃣ Shards & Replicas

### **What are Shards?**
Elasticsearch **splits an index into smaller parts** called **shards** for distributed storage.
- **Primary Shards**: Hold original data.
- **Replica Shards**: Copies for redundancy and failover.

### **Configuring Shards & Replicas**
```json
PUT /products
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2
  }
}
```

---

## 4️⃣ Mapping in Elasticsearch

### **Types of Mapping**
- **Dynamic Mapping**: Fields are automatically detected and mapped.
- **Explicit Mapping**: Users define field types manually.

### **Example of Explicit Mapping**
```json
PUT /products/_mapping
{
  "properties": {
    "name": { "type": "text" },
    "price": { "type": "float" },
    "stock": { "type": "integer" }
  }
}
```

---

## 5️⃣ CRUD Operations in Elasticsearch

### **Create (Index a Document)**
```json
POST /products/_doc
{
  "name": "iPhone 13",
  "price": 999.99,
  "stock": 50
}
```

### **Read (Retrieve a Document)**
```json
GET /products/_doc/1
```

### **Update a Document**
**Partial Update:**
```json
POST /products/_update/1
{
  "doc": {
    "stock": 45
  }
}
```
**Full Document Update:**
```json
PUT /products/_doc/1
{
  "name": "iPhone 13",
  "price": 999.99,
  "stock": 40
}
```

### **Delete a Document**
```json
DELETE /products/_doc/1
```

### **Bulk Operations**
```json
POST /products/_bulk
{ "index": { "_id": "1" } }
{ "name": "iPhone 13", "price": 999.99, "stock": 50 }
{ "index": { "_id": "2" } }
{ "name": "Samsung Galaxy S23", "price": 899.99, "stock": 30 }
{ "update": { "_id": "1" } }
{ "doc": { "stock": 45 } }
{ "delete": { "_id": "2" } }
```

---

## 6️⃣ Inverted Index in Elasticsearch
Elasticsearch uses an **Inverted Index** to optimize full-text searches.
- Instead of storing documents sequentially, it creates an index of words.
- Helps in **fast lookups** by mapping words to document locations.

Example:
**Document:** `"Elasticsearch is powerful."`
**Inverted Index:**
```
"Elasticsearch" → [Doc1]
"is" → [Doc1]
"powerful" → [Doc1]
```

---

## 7️⃣ Difference Between `POST` and `PUT`

| Feature | `POST` | `PUT` |
|---------|--------|--------|
| **ID Handling** | Auto-generated | User-defined |
| **Overwrite** | No | Yes (Replaces the entire document) |
| **Creates Multiple Documents?** | Yes | No |

**Example Usage:**
```json
POST /products/_doc
{ "name": "Laptop", "price": 1200 }
```
```json
PUT /products/_doc/1
{ "name": "Laptop", "price": 1200 }
```

---
