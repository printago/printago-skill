# Printago API Endpoints

199 endpoints. All paths are /v1/ unless noted. [body] = request body required.

## API_Keys
POST   /api-keys [body] - Create an API key
PATCH  /api-keys/{id} [body] - Update an API key
DELETE /api-keys/{id} - Delete an API key
GET    /api-keys - Get all API keys
GET    /api-keys/{id} - Get API key by ID

## Cost_Catalog
POST   /cost-components [body] - Create new cost component
PATCH  /cost-components/{id} [body] - Update cost component
DELETE /cost-components/{id} - Delete cost component
GET    /cost-components - Get all cost components
GET    /cost-components/{id} - Get cost component by ID

## Entitlements
GET    /entitlements - Get all entitlements
GET    /entitlements/{id} - Get entitlement by ID
GET    /entitlements/check/{entitlement} - Check if store has specific entitlement

## Etsy
POST   /integrations/etsy/sync-orders - Sync Etsy orders
GET    /integrations/etsy/listing/{listingId} - Get Etsy listing
GET    /integrations/etsy/status - Get Etsy status
GET    /integrations/etsy/usage - Get Etsy usage stats

## Files
POST   /storage/signed-upload-urls [body] - Get signed upload URLs
POST   /storage/signed-urls [body] - Get signed download URLs

## Folders
POST   /folders [body] - Create a new folder
PATCH  /folders/move [body] - Move folders to a new parent
PATCH  /folders/rename [body] - Rename a folder
DELETE /folders/delete [body] - Delete folders
GET    /folders - Get all folders
GET    /folders/{id} - Get folder by ID
GET    /folders/by-type/{type} - Get folders by type
GET    /folders/parts - Get part folders
GET    /folders/skus - Get SKU folders

## Integrations
GET    /integrations - Get all integrations for a store
GET    /integrations/{id} - Get a specific integration by ID

## Linked_Parts
POST   /linked-parts [body] - Create a new linked part
PATCH  /linked-parts/{id} [body] - Update a linked part
DELETE /linked-parts/{id} - Delete a linked part
GET    /linked-parts - Get all linked parts for a store
GET    /linked-parts/{id} - Get a specific linked part by ID

## Material_Groups
POST   /materials/group-members [body] - Add group member
POST   /materials/groups [body] - Create group
PATCH  /materials/groups/{id} [body] - Update group
DELETE /materials/group-members [body] - Remove group members
DELETE /materials/groups [body] - Delete multiple groups
DELETE /materials/groups/{id} - Delete group
GET    /materials/group-members - Get all group members
GET    /materials/group-members/{id} - Get group member by ID
GET    /materials/group-members/group/{groupId} - Get group members
GET    /materials/groups - Get all groups
GET    /materials/groups/{id} - Get group by ID

## Material_Instances
POST   /materials/instances [body] - Create material instance
PUT    /materials/instances/{id} [body] - Update material instance
DELETE /materials/instances/{id} - Delete material instance
GET    /materials/instances - Get all material instances
GET    /materials/instances/{id} - Get instance by ID

## Material_Variants
POST   /materials/variants [body] - Create variant
POST   /materials/variants/batch [body] - Batch create variants
PATCH  /materials/variants/{id} [body] - Update variant
DELETE /materials/variants [body] - Delete multiple variants
DELETE /materials/variants/{id} - Delete variant
GET    /materials/{materialId}/variants - Get variants by material
GET    /materials/variants - Get all variants
GET    /materials/variants/{id} - Get variant by ID

## Materials
POST   /materials [body] - Create material
PATCH  /materials/{id} [body] - Update material
DELETE /materials [body] - Delete materials
DELETE /materials/{id} - Delete material
GET    /materials - Get all materials
GET    /materials/{id} - Get material by ID

## orders
POST   /orders [body] - Create a new order
POST   /orders/{orderId}/items [body] - Add items to an order
POST   /orders/customers [body] - Create a new customer
POST   /orders/ignored-skus/check [body] - Check if SKUs are ignored
POST   /orders/print-orders [body] - Print/cancel orders to reflect current order state
PUT    /orders/{orderId} [body] - Update an order
PUT    /orders/items/{itemId} [body] - Update an order item
PATCH  /orders/{orderId}/items/batch [body] - Batch update order items
PATCH  /orders/ignored-skus [body] - Update ignored SKUs list
DELETE /orders/{orderId} - Delete an order
DELETE /orders/items/{itemId} - Delete an order item
GET    /orders - Get all orders
GET    /orders/{orderId} - Get order with full details
GET    /orders/{orderId}/items - Get items for a specific order
GET    /orders/{orderId}/only - Get order without related data
GET    /orders/customers - Get all customers
GET    /orders/customers/{customerId} - Get customer by ID
GET    /orders/full - Get complete order data
GET    /orders/ignored-skus - Get ignored SKUs list
GET    /orders/items - Get all order items
GET    /orders/items/{itemId} - Get a specific order item

## Part_Builds
GET    /part-build-steps - Get all part build steps for a store
GET    /part-build-steps/{id} - Get a specific part build step by ID
GET    /part-builds - Get all part builds for a store
GET    /part-builds/{id} - Get a specific part build by ID

## Parts
POST   /parts [body] - Create a new part
POST   /parts/{id}/split-plates - Split multi-plate 3MF file
POST   /parts/{partId}/estimate - Trigger part estimation
POST   /parts/create-skus [body] - Create SKUs from parts
POST   /v2/parts/search [body] - Parts search with advanced filtering
PATCH  /parts/{id} [body] - Update a part
DELETE /parts [body] - Delete multiple parts
DELETE /parts/{id} - Delete a part
GET    /parts - Get all parts
GET    /parts/{id} - Get part by ID
GET    /parts/{partId}/metadata - Get part metadata
GET    /v2/parts - Get parts with filtering support

## Print_Jobs
PATCH  /print-jobs/{id} [body] - Update print job
PATCH  /print-jobs/{id}/reorder [body] - Reorder a job
PATCH  /print-jobs/bulk-reorder [body] - Bulk reorder jobs
PATCH  /print-jobs/cancel [body] - Cancel print jobs
PATCH  /print-jobs/clear [body] - Clear finished jobs
PATCH  /print-jobs/move-to-queue-front [body] - Prioritize jobs
PATCH  /print-jobs/pause [body] - Pause print jobs
PATCH  /print-jobs/resume [body] - Resume paused jobs
PATCH  /print-jobs/retry [body] - Retry failed jobs
GET    /print-jobs - Get all print jobs
GET    /print-jobs/{id} - Get print job
GET    /print-jobs/{id}/matching-details - Get job matching details
GET    /print-jobs/stats/completed-count - Get completed job count

## Printer_Slots
GET    /materials/printer-slots - Get all printer slots

## Printers
POST   /printer-commands/send [body] - Send command to printers
PATCH  /printers [body] - Bulk update printers
PATCH  /printers/{id} [body] - Update a printer
PATCH  /printers/{id}/rename [body] - Rename a printer
PATCH  /printers/confirm-ready [body] - Confirm printer ready
PATCH  /printers/continous-print [body] - Set Fabmatic
PATCH  /printers/enabled [body] - Set printer enabled status
PATCH  /printers/multi [body] - Multi-update printers
PATCH  /printers/set-config [body] - Set provider config
DELETE /printers [body] - Delete multiple printers
DELETE /printers/{id} - Delete a printer
GET    /printers - Get all printers
GET    /printers/{id} - Get printer by ID

## Printing
POST   /v2/builds [body] - Create and queue prints

## Profiles
POST   /profiles [body] - Create a new profile
POST   /profiles/import [body] - Import profiles from a file
POST   /profiles/preview [body] - Preview profiles from a file
PATCH  /profiles/{id} [body] - Update a profile
DELETE /profiles [body] - Delete multiple profiles
DELETE /profiles/{id} - Delete a profile
GET    /profiles - Get all slicer profiles
GET    /profiles/{id} - Get a specific profile
GET    /profiles/{id}/view - Get profile with inheritance details
GET    /profiles/compatible/{id} - Get profiles compatible with a printer
GET    /profiles/compatible/{machineModel}/{nozzleDiameter} - Get profiles by machine model and nozzle size
GET    /profiles/my-printer-models - Get printer models used in your store
GET    /profiles/printer-models - Get all available printer models
GET    /profiles/supported - Get supported printer models

## Settings
PATCH  /settings/store [body] - Update store settings
GET    /settings/slicers - Get available slicer versions
GET    /settings/store - Get store settings

## SKU_Builds
GET    /sku-builds - Get all SKU builds for a store
GET    /sku-builds/{id} - Get a specific SKU build by ID

## SKU_Costs
POST   /sku-costs [body] - Create a new SKU cost
PATCH  /sku-costs/{id} [body] - Update a SKU cost
DELETE /sku-costs/{id} - Delete a SKU cost
DELETE /sku-costs/by-sku/{skuId} - Delete all costs for a specific SKU
GET    /sku-costs - Get all SKU costs for a store
GET    /sku-costs/{id} - Get a specific SKU cost by ID
GET    /sku-costs/breakdown/{skuId} - Get cost breakdown for a specific SKU
GET    /sku-costs/by-sku/{skuId} - Get all costs for a specific SKU

## Sku_Variants
POST   /sku-variants [body] - Create a new SKU variant
POST   /sku-variants/bindings [body] - Create a new variant binding
POST   /sku-variants/bindings/reorder [body] - Reorder a variant binding
POST   /sku-variants/prop-values [body] - Create multiple property values
POST   /sku-variants/props [body] - Create a new variant property
POST   /sku-variants/props/reorder [body] - Reorder a variant property
POST   /sku-variants/values [body] - Create a new variant value
POST   /sku-variants/values/reorder [body] - Reorder a variant value
PATCH  /sku-variants/{id} [body] - Update a SKU variant
PATCH  /sku-variants/bindings/{id} [body] - Update a variant binding
PATCH  /sku-variants/prop-values [body] - Update multiple property values
PATCH  /sku-variants/props/{id} [body] - Update a variant property
PATCH  /sku-variants/values/{id} [body] - Update a variant value
DELETE /sku-variants/{id} - Delete a SKU variant
DELETE /sku-variants/bindings/{id} - Delete a variant binding
DELETE /sku-variants/prop-values [body] - Delete multiple property values
DELETE /sku-variants/props/{id} - Delete a variant property
DELETE /sku-variants/values/{id} - Delete a variant value
GET    /sku-variants - Get all SKU variants for a store
GET    /sku-variants/{groupId}/values - Get variant values for a specific group
GET    /sku-variants/{id} - Get a specific SKU variant by ID
GET    /sku-variants/bindings - Get all variant bindings for a store
GET    /sku-variants/bindings/{id} - Get a specific variant binding by ID
GET    /sku-variants/prop-values - Get all property values for a store
GET    /sku-variants/prop-values/{id} - Get a specific property value by ID
GET    /sku-variants/props - Get all variant properties for a store
GET    /sku-variants/props/{id} - Get a specific variant property by ID
GET    /sku-variants/sku-match/{skuString} - Match a SKU string with variants
GET    /sku-variants/values - Get all variant values for a store
GET    /sku-variants/values/{id} - Get a specific variant value by ID

## SKUs
POST   /skus [body] - Create a new SKU
POST   /skus/delete-many [body] - Delete multiple SKUs
PATCH  /skus/{id} [body] - Update a SKU
DELETE /skus/{id} - Delete a SKU
GET    /skus - List all SKUs
GET    /skus/{id} - Get a specific SKU

## Stores
GET    /stores - Get all stores for current user

## Subscriptions
GET    /addon-subscriptions - Get all addon subscriptions
GET    /addon-subscriptions/{addonType} - Get addon subscription by type
GET    /addons - Get all available addons
GET    /addons/{addonType} - Get addon by type with tiers
GET    /subscriptions - Get current subscription

