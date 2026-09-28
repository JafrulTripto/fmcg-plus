# FMCG+ Database Architecture & Implementation Plan

## 1. Objective & System Scope
This plan details the full implementation of the **Master FMCG Catalog vs. Store Inventory Architecture** for the FMCG+ Bangladesh Retail POS and Mobile Khata platform.

The system connects three tiers:
1. **PostgreSQL Relational Database:** Normalized multi-tenant store schema and canonical 623-product Bangladesh master catalog.
2. **Go Gin Backend API:** RESTful microservice handling 3-state barcode lookups, POS checkout transactions, and Khata credit ledgers.
3. **Flutter Mobile Application & Web Prototype:** Modern POS terminal with camera barcode scanning, sub-15ms catalog auto-fill, split payments, and customer ledger.

---

## 2. Multi-Tier Relational Database Architecture

### 2.1 The Two-Domain Model
```
┌────────────────────────────────────────────────────────────────────────┐
│               CANONICAL MASTER CATALOG (Shared by all BD Stores)        │
│                                                                        │
│   categories ─── subcategories ─── manufacturers ─── brands            │
│                              │                         │               │
│                              ▼                         ▼               │
│                      master_products (623 Authentic BD SKUs)           │
│                      (barcode, name, pack_size, unit, image_url)       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ References via master_product_id
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               STORE OPERATIONS DOMAIN (Tenant-Specific Dokan)          │
│                                                                        │
│   stores (Multi-Tenant Dokans)                                         │
│     │                                                                  │
│     ├─── store_inventory (cost_price, selling_price, stock, shelf)     │
│     │         │                                                        │
│     │         ├─── transaction_items (snapshotted price & cost)        │
│     │         └─── stock_movements (audit log: RESTOCK, SALE, DAMAGE)  │
│     │                                                                  │
│     ├─── transactions (cash memos, split payments: Cash + bKash + Khata)│
│     │                                                                  │
│     └─── customers ─── khata_entries (immutable debit/credit ledger)   │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Key Database Concepts Employed
1. **Third Normal Form (3NF) Entity Separation:**
   * Categories, subcategories, manufacturers, and brands are normalized into discrete lookup tables with foreign keys and unique constraints.
   * Eliminates redundant string repetition across 623+ records and ensures clean faceted filtering.
2. **Flexible Product Linking:**
   * `store_inventory.master_product_id` is a nullable foreign key.
   * Standard FMCG items link directly to `master_products(id)`.
   * Unbranded local dokan items (e.g. loose eggs, fresh vegetables, regional sweets) have `master_product_id = NULL` with their own `custom_name` and optional local barcode.
3. **Price & Cost Snapshotting (Historical Immutability):**
   * `transaction_items` stores `unit_price_snapshot` and `cost_price_snapshot` at the exact second of checkout.
   * Subsequent price revisions or wholesale inflation never retroactively invalidate past gross profit reports.
4. **Double-Entry Khata Credit Ledger:**
   * Customer debt increases (`debit`) and payments received (`credit`) are tracked in append-only `khata_entries`.
   * Row-level locking (`SELECT ... FOR UPDATE`) prevents race conditions during simultaneous split payments.
5. **High-Performance Indexing:**
   * B-Tree unique indexes on `master_products(barcode)` for instantaneous $O(\log N)$ scanner response.
   * Composite index on `store_inventory(store_id, barcode)` for active inventory lookups.
   * PostgreSQL Trigram GIN index (`pg_trgm`) for fuzzy Bengali/English product search.

---

## 3. High-Velocity Barcode Resolution Pipeline

When the shopkeeper points the camera or handheld barcode scanner at a product:

```
[ Barcode Scanned: e.g. 0831730005450 ]
                   │
                   ▼
       Query Store Inventory
                   │
         ┌─────────┴─────────┐
      FOUND               NOT FOUND
         │                   │
         ▼                   ▼
   [STATE A]         Query Master Catalog
   In Store                  │
   Stocked?        ┌─────────┴─────────┐
  ┌──────┴──────┐FOUND               NOT FOUND
 YES           NO  │                   │
  │             │  ▼                   ▼
Add to       Zero  [STATE B]         [STATE C]
Cart        Stock  In Catalog        Unknown Barcode
Beep        Alert  (PRAN Mustard Oil) (Unregistered)
Sound       Modal  Auto-fill Name,   Prompt Manual
                   Brand, Category,  Entry Form
                   Pack Size, Image.
                   Shopkeeper sets:
                   Cost, Price, Qty.
                   1-Click Add!
```

---

## 4. RESTful API Contract

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/stores/:storeId/scan/:barcode` | 3-state barcode scanner endpoint |
| `GET` | `/api/v1/master-catalog` | Search & paginate global FMCG catalog |
| `GET` | `/api/v1/master-catalog/:barcode` | Get canonical product metadata by barcode |
| `POST` | `/api/v1/stores/:storeId/inventory/onboard` | 1-click onboard product from master catalog |
| `GET` | `/api/v1/stores/:storeId/inventory` | List active store inventory with stock filters |
| `POST` | `/api/v1/stores/:storeId/inventory` | Add custom unbranded store product |
| `POST` | `/api/v1/stores/:storeId/inventory/:id/adjust` | Record stock adjustment with audit log |
| `GET` | `/api/v1/stores/:storeId/customers` | Get customers with balance & overdue status |
| `GET` | `/api/v1/stores/:storeId/customers/:id/khata` | Get customer running ledger |
| `POST` | `/api/v1/stores/:storeId/checkout` | ACID atomic checkout with split payment |
| `GET` | `/api/v1/stores/:storeId/dashboard` | Real-time merchant KPIs & sales analytics |

---

## 5. Execution Steps
1. **Database Migration & Seeding:**
   * Update `backend/init.sql` and `backend/seed.sql` with normalized DDL and full 623-product master catalog + store inventory seeds.
2. **Backend Models & Repository:**
   * Refactor Go structs in `backend/internal/models/models.go`.
   * Update PostgreSQL repository in `backend/internal/repository/`.
   * Add 3-state scan handler and onboard endpoint in `backend/internal/handlers/`.
   * Compile and verify Go backend.
3. **Mobile Client Enhancements:**
   * Update Flutter API service and data models.
   * Enhance `barcode_scanner_view.dart` and `add_product_sheet.dart` to handle State B catalog auto-fill.
4. **Web POS Prototype:**
   * Update `app_data.js` and `index.html` to support the 3-state barcode scanner and master catalog auto-fill.
5. **Automated Verification:**
   * Run end-to-end database, backend, and frontend tests.
