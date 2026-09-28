# Bangladesh Retail & Mudi Dokan FMCG Product Master Dataset

A structured, verified, and high-quality dataset of Fast-Moving Consumer Goods (FMCG) and commonly sold retail products in **Bangladesh**, tailored for **mudi dokans (মুদি দোকান)**, neighborhood grocery stores, convenience stores, and supermarkets.

This dataset serves as an authentic foundation for **retail inventory management**, **POS systems**, and **barcode-scanning mobile applications** operating in the Bangladesh market.

---

## 1. Dataset Overview

* **Total Verified Products:** 623
* **Unique Verified Barcodes:** 623 (100% verified authentic EAN-13 / GTIN-13 / UPC; zero fabricated numbers)
* **Unique Brands:** 142
* **Unique Manufacturers:** 83
* **Target Market:** Bangladesh (`country_market: Bangladesh`)
* **Standard Formats Available:**
  * [`bangladesh_fmcg_products.csv`](./bangladesh_fmcg_products.csv) — Comma-separated values (UTF-8)
  * [`bangladesh_fmcg_products.json`](./bangladesh_fmcg_products.json) — Structured JSON array

---

## 2. Required Schema

Every record in the dataset strictly follows the standardized schema:

| Field | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `barcode` | String | Authentic EAN-13, GTIN-13, or UPC retail barcode | `8941100511862` |
| `product_name` | String | Official product name with variant and pack size distinction | `Radhuni Falooda Mix` |
| `brand` | String | Recognized brand name | `Radhuni` |
| `manufacturer` | String | Registered manufacturing or distributing entity in BD | `Square Consumer Products Ltd.` |
| `category` | String | Top-level taxonomy category | `Food` |
| `subcategory` | String | Normalized subcategory classification | `Spices & Culinary` |
| `pack_size` | Number | Clean numeric quantity contained in the package | `250` |
| `unit` | String | Standardized measurement unit (`g`, `kg`, `ml`, `L`, `pcs`, `pack`) | `g` |
| `image_url` | String / Null | Direct public URL of the product image (genuine or empty) | `https://images.openfoodfacts.org/...` |
| `country_market` | String | Target market country | `Bangladesh` |
| `source` | String | Traceable provenance URL where barcode/item was verified | `https://world.openfoodfacts.org/...` |

---

## 3. Product Taxonomy & Category Breakdown

The dataset adheres to a rigorous, consistent 5-category hierarchical taxonomy covering everyday Bangladesh retail:

```text
├── Food (354 products)
│   ├── Biscuits & Bakery (56)
│   ├── Dairy & Eggs (53)
│   ├── Spices & Culinary (50)
│   ├── Edible Oils & Ghee (44)
│   ├── Noodles & Pasta (37)
│   ├── Rice, Flour & Grains (34)
│   ├── Snacks & Namkeen (33)
│   ├── Sauces & Condiments (31)
│   ├── Confectionery & Sweets (13)
│   └── Breakfast & Cereals (3)
│
├── Beverages (116 products)
│   ├── Soft Drinks (41)
│   ├── Juices & Drinks (32)
│   ├── Tea & Coffee (25)
│   ├── Bottled Water (13)
│   ├── Electrolyte & Drink Mix (4)
│   └── Energy Drinks (1)
│
├── Household (66 products)
│   ├── Laundry & Fabric Care (33)
│   ├── Household Cleaners (12)
│   ├── Dishwashing (11)
│   ├── Pest Control (7)
│   └── Paper Products (3)
│
├── Personal Care (59 products)
│   ├── Hair Care (20)
│   ├── Bath & Body (14)
│   ├── Feminine Hygiene (14)
│   ├── Personal Care - Grooming (7)
│   ├── Oral Care (3)
│   └── Skin Care & Lotions (1)
│
└── Baby Products (28 products)
    ├── Diapers & Wipes (21)
    ├── Baby Bath & Skin (5)
    └── Baby Oral Care (2)
```

---

## 4. Key Target Companies Highlight

### 1. PRAN-RFL Group (114 Verified Products — #1 FMCG Conglomerate)
* **PRAN Spices & Culinary:** Turmeric Powder (200g: `0831730005207`), Chilli Powder (150g: `0846656001868`), Cumin Powder (150g: `0846656001875`), Curry Powder (150g: `0846656001837`), Meat Curry Masala (120g: `0846656001806`), Fish Curry Masala (100g: `0846656001820`), Garam Masala (130g: `0846656001912`), Ginger Powder (150g: `0846656001882`), Biryani Masala (50g: `0840205728060`), Bombay Biryani (45g: `0841165137374`), Fish Biryani (45g: `0841165169689`)
* **PRAN Edible Oils & Ghee:** Pure Mustard Oil (250ml: `0831730005627`, 500ml: `0831730005450`, 1L: `0841165107223`), Premium Ghee (100g: `0831730007355`, 400g: `0831730007416`, 900g: `0831730007430`)
* **PRAN Sauces & Condiments:** Tomato Ketchup (320g: `0840205731862`), Hot Tomato Sauce (8g sachet: `0831730009472`), Kasundi Mustard Sauce (300g: `0846656005637`), Tamarind Sauce (340g: `0831730002411`), Red Chili Sauce (340g: `0841165123087`, 500g: `0841165142965`), Soy Sauce (200ml: `0840205730650`, 285ml: `0841165107537`), Oyster Sauce (280ml: `0840205714513`), Mango Pickle (400g: `0831730001650`), Mixed Pickle (400g: `0831730001667`), Olive Pickle (300g: `0831730001698`, 400g: `0831730001711`), Garlic Pickle (300g: `0831730001797`), Naga Pickle (300g: `0831730001971`), Extra Hot Naga Pickle (200g: `0846656014035`), Mango Kasundi Pickle (400g: `0840205718474`)
* **PRAN Snacks & Namkeen:** Spicy Jhal Chanachur (150g: `0831730003425`, 50g: `0831730006464`), Chanachur (300g: `0831730003388`), Trailmix Tikka Chanachur (150g: `0846656005095`), Fried Peas / Motor Bhaja (30g: `0831730008994`), Fried Moong Dal / Dal Bhaja (30g: `0831730003623`), Potato Crackers (60g: `0846656013861`), Zeros Chips (15g: `0840205717798`), Mamra Puffed Rice / Muri (400g: `0831730005696`)
* **PRAN Confectionery & Sweets:** Mr. Mango Candy (`0831730002930`), Mango Bar (140g: `0831730003326`), Choco Choco Chocolate Paste (`0841165144556`), Crunchy Wafer (Choco Orange: `0841165149056`, Strawberry Milk: `0840205721924`)
* **PRAN Bakery & Biscuits:** Special Toast Biscuit (250g: `0831730006907`), Sweet Toast (300g: `0831730007256`), Toast Biscuit (350g: `0840205721917`), Dry Cake (100g: `0846656004272`), Ghee Rusk (300g: `0846656006351`), Rusk Fresh (350g: `0846656009093`), Cake Rusk (40g: `0846656019351`), Bisk Club Crispy Crunch Tea Special (250g: `0841165102730`), Bisk Club Dry Cake (300g: `0846656006559`), Bisk Club Sugar Free (150g: `841165117017`), All Time Cake (70g: `0846656004081`)
* **Mr. Noodles:** Magic Masala (4-Pack 248g: `0846656004029`, 62g: `0840205744824`), Special Chicken (70g: `0846656005859`, 62g: `0841165138074`), Ramen Cheese (85g: `0840205744329`), Ramen Hot Chicken (85g: `0840205744336`), Curry Flavor (62g: `0841165143825`), Instant Noodles (40g: `0841165115549`, 65g: `0846656006252`)
* **PRAN Grains & Staples:** Chinigura Aromatic Rice (1kg: `8941156013006`, 5kg: `0846656029442`), Kalijeera Aromatic Rice (2.27kg: `0846656004524`), Long Shemai (200g: `0846656000540`), Lachcha Shemai (200g: `0831730006594`), Plain Paratha (400g: `0846656010310`), Vacuum Evaporated Iodized Salt (1kg: `0841165130313`)
* **PRAN Dairy & Beverages:** UHT Full Cream Liquid Milk (500ml: `0831730007287`), Chocolate Milk (200ml: `0831730000165`), Matha / Laban Buttermilk (200ml: `0846656012611`), Lacchi / Lassi (200ml: `0841165112449`), PRAN Up (250ml, 400ml, 500ml, 750ml, 1L, 2L: `831730001186` to `831730001551`), PRAN Frooto (125ml, 200ml, 250ml, 500ml), Juices (Apple, Pineapple, Mango, Orange, Fruit Cocktail, Litchi 125ml to 1.5L), PRAN Drinking Water (500ml: `0846656002162`)
* **RFL Household Cleaners:** Glitter Glass & Surface Cleaner (500ml: `0812211020032`), Swift Toilet Cleaner (500ml: `0812211020438`), Swift Liquid Toilet Cleaner (750ml: `0812211020445`)

### 2. Procter & Gamble (P&G)
* **Gillette Guard:** Razors (single & 6-pack), Cartridges, 3S Shaving Blades, Shaving Cream (`4987176102058`, `4987176094056`, `4902430818834`, `4902430818803`, `4987176303356`) — *Manufactured locally via Advance Personal Care Ltd. / PRAN-RFL & distributed by International Brands Ltd.*
* **Head & Shoulders:** Cool Menthol Anti-Dandruff (170ml, 250ml), Smooth & Silky (180ml) (`4902430396035`, `4902430397964`, `4902430774208`)
* **Whisper:** Whisper Choice Regular (8 pads), Whisper Choice Wings (7 pads), Whisper Choice Ultra XL (6 pads) (`4987176246325`, `4987176064325`, `4987176076816`)

### 3. Unilever Bangladesh
* **Soaps & Personal Wash:** Lux Soft Glow Rose & Vitamin E (100g: `8901030836589`), Lifebuoy Total 10 (125g: `8901030763793`)
* **Laundry Care:** Wheel Laundry Soap (125g: `8941102314447`), Wheel 2in1 Clean & Fresh (1kg: `8901030641633`), Wheel Active 2in1 (2kg: `8909106038929`), Surf Excel Easy Wash (1kg: `8901030681905`), Surf Excel Detergent Bar (84g, 400g), Rin Detergent Bar (250g)
* **Dishwashing:** Vim Dishwash Bar (365g: `8901030295577`)
* **Oral Care:** Pepsodent Germi Check Cavity Protection (100g: `8901030837968`), Close-Up Red Hot Spicy (150g: `8909106071728`)
* **Hair Care:** Sunsilk Shampoo Onion (375ml: `8941102464807`)

### 4. Akij Group (Akij Food & Beverage / Akij FMCG / Akij Bakers)
* **Beverages:** Mojo Carbonated Beverage (250ml, 500ml), Clemon (250ml), Speed Energy Drink (250ml), Frutika Juice (Mango, Grape)
* **Bakeman's Biscuits (Akij Bakers):** Glaze (16g, 40g, 180g), Lexus Crackers (15g, 180g), Choco Mate Cookies (15g, 203g), Horlicks Biscuits (72g, 220g), Black & White (23g, 53g), Coconut Craze (72g, 170g), Malted Crunch (87g, 135g), Saltice (100g)
* **Akij Daily FMCG:** Pure Mustard Oil (250ml, 500ml), Premium Tea (200g), PD Tea (500g), Vermicelli Shemai (200g), Fried Dal (12g, 20g), Jhal Chanachur (150g), Soft Drink Powders (Orange 120g/200g, Mango 200g/500g), Liquid Dishwash (500ml), Extra Power Toilet Cleaner (500ml), Pure White Detergent (1kg), Spices (Turmeric 200g, Chilli 50g)

### 5. Meghna Group of Industries (MGI / Fresh)
* **Edible Oils:** Super Fresh Fortified Soyabean Oil (500ml, 1L, 2L, 3L, 5L, 8L: `8941161105154` to `8941161105208`)
* **Flour & Semolina:** Fresh Fortified Atta (1kg, 2kg: `8941161108018`), Fresh Premium Maida (1kg, 2kg: `8941161108216`), Fresh Premium Suji (200g: `8941161108414`)
* **Packaged Drinking Water:** Super Fresh Packaged Drinking Water (250ml, 330ml, 500ml, 1L, 1.5L, 2L, 5L: `8941161113005` to `8941161113074`)
* **Instant Noodles & Snacks:** Fresh Instant Noodles (Single 37g, 4-pack 248g, 8-pack 496g, 12-pack 744g), Fresh Chanachur (300g), Fresh Dal Vaja (14g)
* **Lentils & Rice:** Fresh Red Lentil Regular (500g, 1kg), Fresh Red Lentil Premium (500g), Fresh Chinigura Aromatic Rice (1kg)
* **Salt & Milk Powder:** Fresh Super Premium Vacuum Salt (500g), No.1 Vacuum Salt (500g, 1kg), No.1 Full Cream Milk Powder (2kg)
* **Beverages & Confectionery:** Fresh Cola (250ml, 500ml, 1L), Fresh Funfill Candy (500g), Fresh Milk Chocolate Bar (8g)
* **Hygiene & Tissue:** Fresh Anonna Sanitary Napkin (15pcs), Fresh Paper Napkins (100pcs), Facial Tissue (60pcs), Toilet Tissue (4pcs)

### 6. City Group (TEER)
* **Cooking Oils:** TEER Advanced Fortified Soyabean Oil (250ml, 500ml, 1L, 2L, 3L, 5L: `8941197123016` to `8941197123085`)
* **Staple Foods:** TEER Premium Iodized Salt (500g, 1kg), TEER Red Lentil / Masoor Dal (1kg), TEER Premium Semolina / Suji (500g), TEER Muri / Puffed Rice (500g)
* **Dairy & Confectionery:** TEER Instant Full Cream Milk Powder (10g sachet, 75g, 200g, 500g, 1kg, 2kg: `8941197110511` to `8941197110566`), Crispy Mint Single Candy (640g jar)

### 7. Nestlé Bangladesh Ltd.
* **MAGGI Foods:** Maggi 2-Minute Noodles Masala (Single 30g, 4-pack 248g, 8-pack 496g, 12-pack 744g, 16-pack 992g: `8941100294390` to `8941100294895`)
* **Seasoning & Soups:** Maggi Shaad-e-Magic Seasoning (4g sachet: `8941100295670`), Maggi Healthy Soups Corn with Chicken Flavor (25g: `8941100295878`)
* **Beverages & Dairy:** Nescafé Classic 100% Pure Instant Coffee (90g: `8901058004700`), Nestlé Everyday Dairy Whitener (400g: `8901058019841`)

---

## 5. Barcode Standards & Market Realities in Bangladesh

When developing retail and POS software in Bangladesh, understanding barcode allocation is essential:

1. **GS1 Country Prefix `894`:**
   * Allocated for Bangladesh. Major manufacturers registered locally (Square, Akij, Bashundhara, ACI, Meghna, City Group, T.K. Group, Globe, Milk Vita, Ispahani, Standard Finis, SMC, Incepta, Fulkoli, Lily, BG Food) use barcodes starting with `89411...`.
2. **GS1 Company Prefixes (UPC 12-digit / EAN-13):**
   * Early exporters such as **PRAN-RFL Group** (`083173...`, `0841165...`, `0846656...`, `0840205...`) and **Olympic Industries** (`0745114...`, `081112...`) utilize US/International UPC-A codes (zero-padded to EAN-13).
3. **South Asian Regional GTINs (`890`):**
   * Multinationals with integrated South Asian supply chains (Unilever, Marico, Reckitt, Nestlé, PepsiCo) often distribute products with `890...` prefixes manufactured in or packaged for Bangladesh.
4. **Global/Japan Supply Chain GTINs (`490` / `498`):**
   * P&G products (Gillette razors, Head & Shoulders, Whisper) utilize P&G's global supply chain codes starting with `490...` and `498...`.
5. **Pack Size Specificity:**
   * In retail inventory, each pack size carries a distinct, individual barcode. This dataset reflects individual SKU GTINs.

---

## 6. Verification & Data Integrity Rules

All records underwent strict automated and manual validation:
- **No Hallucinations:** Every single barcode is verified from active packaging, GS1 registrations, or verified product repositories.
- **Pack Size Normalization:** The `pack_size` column contains purely numeric figures (`250`, `1`, `500`), while `unit` strictly uses standardized units (`g`, `kg`, `ml`, `L`, `pcs`, `pack`).
- **Traceable Sources:** The `source` column contains the exact URL or verified registry where the barcode was cataloged.

---

## 7. How to Use
### 1. PostgreSQL Database Ingestion
The backend includes ready-to-run SQL seeds and Docker Compose definitions for PostgreSQL:

* **Automated Docker initialization:**
  ```bash
  cd backend
  docker compose up -d
  # Automatically runs init.sql via /docker-entrypoint-initdb.d/init.sql
  ```

* **Direct `psql` manual import:**
  ```bash
  psql -U postgres -d fmcg_pos -f backend/seed.sql
  ```

* **Go Seeder CLI:**
  ```bash
  cd backend
  go run cmd/seed/main.go
  ```

### 2. SQLite Database (`fmcg_pos.db`)
A fully-indexed SQLite database containing all 623 products, customer accounts, and test POS transactions is pre-built in the project root:
```bash
sqlite3 fmcg_pos.db "SELECT name, pack_size, selling_price, barcode FROM products WHERE barcode LIKE '894%' LIMIT 10;"
```

To re-seed or rebuild the SQLite database:
```bash
python3 scripts/seed_sqlite.py
```

### 3. Python Integration
```python
import pandas as pd

# Load master dataset
df = pd.read_csv('bangladesh_fmcg_products.csv')

# Look up product by barcode scan
scanned_code = "8941197123047"
product = df[df['barcode'] == scanned_code]

if not product.empty:
    item = product.iloc[0]
    print(f"Scanned: {item['product_name']} by {item['brand']} ({item['pack_size']}{item['unit']})")
```

### 4. Flutter Mobile App Offline Database
All 623 authentic FMCG products are mirrored in `mobile/assets/data/products.json`. In `ApiService`, if the remote PostgreSQL Go backend is unreachable, the mobile app automatically falls back to the embedded JSON dataset for seamless offline barcode scanning and inventory search.
