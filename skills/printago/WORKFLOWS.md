# API Workflows & Discovery

**Scripts:** `scripts/` (relative to this skill directory)
- `api.sh METHOD /endpoint [body]` — authenticated API requests
- `schema.sh types|paths [name]` — fetch schemas (no auth)

## Schema Introspection (No Auth Required)

When you need detailed field information beyond what's in SKILL.md, use the schema script to get full JSON schemas.

### When to use schema introspection
- You need to know all available fields for filtering/sorting
- You need exact field types, constraints, or enum values
- You need to construct a complex request body

### Type Schemas
```bash
schema.sh types                    # List all available type names
schema.sh types Part               # Full schema for Part
schema.sh types PrintJob           # Full schema for PrintJob
schema.sh types SkuOptionProperty  # Full schema for SkuOptionProperty
```

### Path Schemas
```bash
schema.sh paths                    # List all API paths
schema.sh paths v1/parts           # Schema for /v1/parts endpoint
schema.sh paths v2/builds          # Schema for /v2/builds endpoint
```

Path schemas include: summary, parameters, requestBody schema, and response schema for each HTTP method.

## API Hints System

Hints provide actionable next steps for each API endpoint. Use them to discover what actions are available for resources.

### Get Hints (No Auth Required)
```bash
# Get all route hints
curl "https://api.printago.io/v1/hints"

# Get hints for a specific endpoint
curl "https://api.printago.io/v1/hints/path/v1/parts"
curl "https://api.printago.io/v1/hints/path/v1/printers"
```

### Include Hints in API Responses
Add `hints=true` to any GET request to include hints in the response:

```bash
api.sh GET "/v1/parts?meta=true&hints=true"
```

Response includes a `hints` array:
```json
{
  "data": [...],
  "meta": { "total": 10, "limit": 100, "offset": 0 },
  "hints": [
    {
      "action": "queue_print",
      "description": "Queue a part for printing",
      "method": "POST",
      "path": "/v2/builds",
      "bodySchema": { "example": { "parts": [{ "partId": "{id}" }] } }
    },
    {
      "action": "create_sku",
      "description": "Create a SKU product from a part",
      "method": "POST",
      "path": "/v1/parts/create-skus",
      "bodySchema": { "example": [{ "partId": "{id}", "skuName": "Product Name" }] }
    }
  ]
}
```

### Hint Structure

| Field | Description |
|-------|-------------|
| `action` | Action identifier (e.g., `queue_print`, `create_sku`) |
| `description` | Human-readable description |
| `method` | HTTP method (GET, POST, PATCH, DELETE) |
| `path` | API endpoint path. `{id}` = resource ID from response |
| `bodySchema` | Example request body (for POST/PATCH) |
| `condition` | When this action applies (e.g., "when printer is printing") |

## Common Workflows

### Print a Part
```bash
api.sh GET /v1/parts
api.sh POST /v2/builds '{"parts":[{"partId":"<id>","quantity":1}]}'
```

### Create SKU from Part
```bash
api.sh GET /v1/parts
api.sh POST /v1/parts/create-skus '[{"partId":"<id>","skuName":"Product Name"}]'
```

### Print Orders

**Use `/v1/orders/print` to create print jobs for orders.** This is the correct way to print orders - do NOT manually create builds for order items.

This automatically:
- Matches order items to SKUs (by `externalSku` field)
- Creates the correct number of print jobs based on quantity
- Handles SKU variants and options
- Cancels excess jobs if order quantity decreased
- Marks order items as processed

```bash
# 1. Get open orders
api.sh GET "/v1/orders?status.in=pending,confirmed,processing"

# 2. Get order items for a specific order
api.sh GET "/v1/orders/<orderId>/items"
# Or get all order items:
api.sh GET "/v1/orders/items"

# 3. Call to create print jobs (pass SKU IDs that need printing)
api.sh POST /v1/orders/print '{"skuIds":["<skuId1>","<skuId2>"]}'

# Or specific orders only:
api.sh POST /v1/orders/print '{"skuIds":["<skuId>"],"orderIds":["<orderId>"]}'

# With priority and printer tags:
api.sh POST /v1/orders/print '{
  "skuIds":["<skuId>"],
  "priority":"high",
  "position":"front",
  "printerTags":{"color":"red"}
}'
```

### Order Items

Order items are line items within an order. Each links to a SKU.

```bash
# Get all order items
api.sh GET "/v1/orders/items"

# Get items for a specific order
api.sh GET "/v1/orders/<orderId>/items"

# Get a specific order item
api.sh GET "/v1/orders/items/<itemId>"

# Filter order items
api.sh GET "/v1/orders/items?skuId.eq=<skuId>"
api.sh GET "/v1/orders/items?processedStatus.eq=pending"
```

Key fields on OrderItem:
- `orderId` - Parent order
- `skuId` - Associated SKU (may be null if not matched)
- `externalSku` - SKU identifier from external system (used for matching)
- `quantity` - Number ordered
- `processedStatus` - `unprocessed` | `processed`
- `ignored` - boolean, if true the item is skipped when printing orders

### Control a Printer
```bash
api.sh GET /v1/printers
api.sh PATCH /v1/print-jobs/pause '{"printJobId":"<jobId>"}'
api.sh PATCH /v1/print-jobs/resume '{"printJobId":"<jobId>"}'
api.sh PATCH /v1/print-jobs/cancel '{"ids":["<jobId>"]}'
```

### Set Up SKU Variants
See [SKU-VARIANTS.md](SKU-VARIANTS.md) for the complete workflow.

## Bulk Operations

```bash
api.sh PATCH /v1/print-jobs/cancel '{"ids":["<id1>","<id2>","<id3>"]}'
api.sh PATCH /v1/printers/bulk '{"ids":["<id1>","<id2>"],"data":{"enabled":true}}'
api.sh POST /v1/parts/create-skus '[{"partId":"<id1>","skuName":"Product 1"},{"partId":"<id2>","skuName":"Product 2"}]'
```
