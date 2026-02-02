---
name: printago
description: Interact with the Printago 3D printing management API. Use for parts, printers, print jobs, materials, SKUs, builds, orders, or profiles. Make HTTP requests directly using curl.
---

# Printago API

REST API for 3D print farm management. Default: `https://api.printago.io`

Set `PRINTAGO_API_URL` to target different environments:
```bash
export PRINTAGO_API_URL=http://localhost:3001  # Local dev
export PRINTAGO_API_URL=https://api.printago.io # Production (default)
```

## Making API Requests

**Scripts:** `scripts/` (relative to this skill directory)

| Script | Purpose |
|--------|---------|
| `api.sh` / `api.ps1` | API requests with auth |
| `upload.sh` / `upload.ps1` | Upload file, returns path |
| `schema.sh` / `schema.ps1` | Fetch type/path schemas (no auth) |

**Bash (macOS/Linux/WSL):**
```bash
api.sh GET /v1/parts
api.sh POST /v1/parts '{"name":"Test","type":"stl",...}'
upload.sh model.stl
schema.sh types Part
```

**PowerShell (Windows):**
```powershell
./api.ps1 GET /v1/parts
./api.ps1 POST /v1/parts '{"name":"Test","type":"stl",...}'
./upload.ps1 model.stl
./schema.ps1 types Part
```

## Authentication

Credentials are loaded from (in order):
1. Environment variables: `PRINTAGO_API_KEY`, `PRINTAGO_STORE_ID`
2. System keychain (recommended for security)

**Store in keychain:**

```bash
# macOS
security add-generic-password -s "Printago" -a "apiKey" -w "your-api-key"
security add-generic-password -s "Printago" -a "storeId" -w "your-store-id"

# Linux (requires libsecret)
secret-tool store --label="Printago API Key" service Printago key apiKey
secret-tool store --label="Printago Store ID" service Printago key storeId
```

```powershell
# Windows
cmdkey /generic:Printago_apiKey /user:apiKey /pass:your-api-key
cmdkey /generic:Printago_storeId /user:storeId /pass:your-store-id
```

## Query Parameters (GET list endpoints)

| Param | Example | Description |
|-------|---------|-------------|
| `{field}.{op}` | `name.contains=benchy` | Filter by field (see operators) |
| `sort` | `sort=createdAt:desc` | Sort (field:asc or field:desc) |
| `limit` | `limit=10` | Limit results |
| `fields` | `fields=id,name,createdAt` | Select fields |
| `include` | `include=parts,materials` | Include relations |

### Filter Operators

- **String**: `eq`, `ne`, `contains`, `startsWith`, `endsWith`
- **Number/Date**: `gt`, `gte`, `lt`, `lte`, `between`
- **Array**: `in`, `notIn` (e.g., `status.in=active,pending`)
- **Null**: `isNull` (e.g., `deletedAt.isNull=true`)

Multiple filters use AND: `?name.contains=test&status.eq=active`

## File Uploads & Part Creation

```bash
# Step 1: Upload file (returns path)
upload.sh model.stl
# → prints: uploads/abc123/model.stl

# Step 2: Create part with the path
api.sh POST /v1/parts '{"name":"My Model","description":"","type":"stl","fileUris":["uploads/abc123/model.stl"],"parameters":[],"printTags":{},"overriddenProcessProfileId":null}'

# Step 3 (optional): Queue for printing
api.sh POST /v2/builds '{"parts":[{"partId":"<id>","quantity":1}]}'
```

**Notes:**
- `type`: stl | 3mf | gcode3mf | gcode | step | scad
- `description` and `overriddenProcessProfileId` are required fields

## Data Types

All entities have: `id` (cuid2), `storeId`, `createdAt`, `updatedAt`

> For complete field lists with exact types, use `schema.sh types {TypeName}`

### Part
3D model file for printing.
- `name`, `description`, `folderId` (FK → Folder)
- `type`: scad | stl | step | 3mf | gcode3mf | gcode
- `fileUris[]`, `fileHashes[]`, `thumbnailUri`
- `printTags` (object for printer matching), `userTags[]` (user labels)
- `materials[]` ({index, color, type}), `slicingEstimate` ({estimatedPrintTimeSeconds, totalWeightGrams})
- **Referenced by**: LinkedPart.partId, PrintJob.partId

### Printer
Physical 3D printer.
- `name`, `deviceId`, `nozzleDiameter`, `tags[]`
- `provider`: Bambu | Klipper | OctoPrint | Prusa
- `enabled` (bool), `confirmedReady` (bool), `continuousPrint` (bool)
- `isOnline` (bool), `isAvailable` (bool)
- `printingJobId` (FK → PrintJob, current job)
- **Referenced by**: PrintJob.assignedPrinterId

### PrintJob
A print task in the queue.
- `partId` (FK → Part), `partName`, `skuId` (FK → SKU), `skuName`, `label`
- `orderId` (FK → Order), `orderItemId` (FK → OrderItem), `linkedPartId` (FK → LinkedPart)
- `status`: pending | assigned | slicing | printing | paused | completed | failed | cancelled
- `priority`: 100 (normal) | 1000 (low)
- `queueOrder` (int, lower = earlier), `quantityIndex`, `quantityTotal`
- `assignedPrinterId` (FK → Printer), `assignmentStartedAt`, `assignmentCompletedAt`
- `printingStartedAt`, `printingCompletedAt`, `cancelledAt`
- `thumbnailUri`, `hidden` (bool)

### SKU
Product definition linked to parts. Supports variant options for customization.
- `sku` (identifier string), `title`, `description`, `folderId` (FK → Folder)
- `externalId`, `externalProvider`: shopify | etsy
- `totalCogs` (number, cost of goods sold)
- **Referenced by**: LinkedPart.skuId, OrderItem.skuId

### LinkedPart
Links a Part to a SKU with quantity and configuration.
- `skuId` (FK → SKU), `partId` (FK → Part)
- `quantity` (number), `label` (string)
- `parameters[]` (PartParameterOverride[])
- `materialAssignments` (Record<number, LinkedPartMaterialSpecification[]>)
- `parameterBindings` (Record<string, string>, maps parameter names to SkuOptionProperty IDs)
- **Referenced by**: PrintJob.linkedPartId

### Order
Customer order.
- `orderNumber`, `customerId` (FK → Customer), `note`
- `status`: open | closed
- `source`: manual | shopify | etsy
- `externalId`, `externalUrl`, `integrationId` (FK → Integration)
- `deadline`, `processedAt`, `cancelledAt` (dates)
- **Referenced by**: OrderItem.orderId, PrintJob.orderId

### OrderItem
Line item in an order.
- `orderId` (FK → Order), `skuId` (FK → SKU), `quantity`
- `externalSku` (used to match SKU during reconcile)
- `processedStatus`: unprocessed | processed
- `ignored` (bool), `processedAt` (date)
- **Referenced by**: PrintJob.orderItemId

### Customer
- `name`, `email`, `phone`
- `countryCode`, `provinceCode`, `zipCode`
- `externalId`, `source`

### Material
Filament type (e.g., PLA, PETG).
- `name`, `brand`, `type` (string like "PLA", "PETG", "ABS")
- `identifier` (8-char code), `tags[]`
- `starred` (bool), `pricePer1000g` (number)
- **Referenced by**: MaterialVariant.materialId

### MaterialVariant
Specific color variant of a material.
- `materialId` (FK → Material), `name`, `tags[]`
- `color` (hex with alpha, e.g. #FF0000FF)

### Profile
Slicer profile for print settings.
- `name`, `type`: process | filament | machine
- `source`: manual | bambu-account

### Build (POST /v2/builds)
Request to queue parts for printing.
- `parts[]`: {partId, quantity, tags, priority, position, materialAssignments}
- `skus[]`: {skuId, quantity, tags, priority, position, selectedOptions}

## Entity Relationships

```
SKU ──1:N──> LinkedPart ──N:1──> Part

Order ──1:N──> OrderItem ──N:1──> SKU
                  │
                  └──> PrintJob(s) via /v1/orders/reconcile
```

## Additional Resources

- [SKU-VARIANTS.md](SKU-VARIANTS.md) - SKU variant/customization system
- [WORKFLOWS.md](WORKFLOWS.md) - Common workflows, printing orders, API hints
- [ENDPOINTS.md](ENDPOINTS.md) - Full endpoint list
