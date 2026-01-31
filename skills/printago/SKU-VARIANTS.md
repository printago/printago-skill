# SKU Variant System

**API script:** `scripts/api.sh` — examples use `api.sh METHOD /endpoint`

The variant system enables SKU customization with options like color, size, or personalization text. It maps customer selections to material assignments, parameter overrides, or plate quantities.

## Architecture Overview

```
SkuOption (global)
    │
    ├──1:N──> SkuOptionValue (e.g., "Red", "Blue")
    │
    └──1:N──> SkuOptionBinding ──N:1──> SKU
                    │
                    ├──1:N──> SkuOptionValueFilter (limits available values per SKU)
                    │
                    └──1:N──> SkuOptionProperty (bound to 1-3 bindings)
                                    │
                                    └──1:N──> SkuOptionPropertyValue
                                              (keyed by optionValueId(s))
```

## Types

### SkuOption
A variant option category (e.g., "Color", "Size"). Global across the store.
- `name` (string)
- `isPersonalization` (bool, true if customer provides custom input)
- **Referenced by**: SkuOptionValue.optionId, SkuOptionProperty.optionId, SkuOptionBinding.optionId, SkuOptionValueFilter.optionId

### SkuOptionValue
A specific value for a SkuOption (e.g., "Red", "Large").
- `name` (string)
- `optionId` (FK → SkuOption, nullable)
- `skuSuffixes` (string[], optional SKU suffix patterns for matching external SKUs)
- `order` (number, display order)
- **Referenced by**: SkuOptionPropertyValue.optionValueId, SkuOptionPropertyValue.optionValueId2, SkuOptionPropertyValue.optionValueId3, SkuOptionValueFilter.optionValueId

### SkuOptionBinding
Links a SkuOption to a specific SKU. Enables SKU-specific option configuration.
- `optionId` (FK → SkuOption), `skuId` (FK → SKU)
- `order` (number, display order)
- `filterMode`: inclusion | exclusion | null (controls which values are available)
- **Referenced by**: SkuOptionProperty.bindingId, SkuOptionProperty.bindingId2, SkuOptionProperty.bindingId3, SkuOptionValueFilter.bindingId

### SkuOptionValueFilter
Filters which SkuOptionValues are available for a SKU based on filterMode.
- `bindingId` (FK → SkuOptionBinding), `skuId` (FK → SKU), `optionId` (FK → SkuOption), `optionValueId` (FK → SkuOptionValue)

When `filterMode=inclusion`: only values in the filter list are available.
When `filterMode=exclusion`: all values except those in the filter list are available.

### SkuOptionProperty
Defines a property that can be set based on option selection. Can depend on 1-3 option bindings (compound properties).
- `optionId` (FK → SkuOption)
- `bindingId` (FK → SkuOptionBinding, nullable, primary source binding)
- `bindingId2` (FK → SkuOptionBinding, nullable, 2nd source for compound)
- `bindingId3` (FK → SkuOptionBinding, nullable, 3rd source for compound)
- `name` (string)
- `type`: text | material | plate_quantities
- `order` (number)
- **Referenced by**: SkuOptionPropertyValue.propertyId, LinkedPart.parameterBindings values, LinkedPart.plateQuantitiesBinding

### SkuOptionPropertyValue
The actual value for a property given specific option value selections.
- `propertyId` (FK → SkuOptionProperty)
- `optionValueId` (FK → SkuOptionValue, value from bindingId's option)
- `optionValueId2` (FK → SkuOptionValue, nullable, value from bindingId2's option)
- `optionValueId3` (FK → SkuOptionValue, nullable, value from bindingId3's option)
- `textValue` (string, nullable)
- `materialValue` (SingleMaterialSpecification[], nullable)
- `plateQuantitiesValue` (Record<string, number>, nullable)

## Property Types

| Type | Purpose | Value Field |
|------|---------|-------------|
| `text` | Override part parameters with text | `textValue` |
| `material` | Set material/color for print | `materialValue` |
| `plate_quantities` | Set quantities per plate | `plateQuantitiesValue` |

## Workflow: Setting Up Variants

```bash
# 1. Create global SkuOption (e.g., "Material Color")
api.sh POST /v1/sku-options '{"name":"Material Color","isPersonalization":false}'

# 2. Create SkuOptionValues (e.g., "Red", "Blue", "Green")
api.sh POST /v1/sku-option-values '{"optionId":"<optionId>","name":"Red","order":0}'

# 3. Create SkuOptionBinding to link option to a specific SKU
api.sh POST /v1/sku-option-bindings '{"optionId":"<optionId>","skuId":"<skuId>","order":0,"filterMode":null}'

# 4. (Optional) Filter values with SkuOptionValueFilter
api.sh POST /v1/sku-option-value-filters '{"bindingId":"<bindingId>","skuId":"<skuId>","optionId":"<optionId>","optionValueId":"<valueId>"}'

# 5. Create SkuOptionProperty to define what data the option controls
api.sh POST /v1/sku-option-properties '{"optionId":"<optionId>","bindingId":"<bindingId>","name":"Color","type":"material","order":0}'

# 6. Create SkuOptionPropertyValues to map option values → actual data
api.sh POST /v1/sku-option-property-values '{"propertyId":"<propertyId>","optionValueId":"<redValueId>","materialValue":[{"type":"PLA","color":"#FF0000FF"}]}'

# 7. In LinkedPart, set parameterBindings to map Part parameters to property IDs
api.sh PATCH /v1/linked-parts/<id> '{"parameterBindings":{"color_param":"<propertyId>"}}'
```

## Compound Properties

Properties can depend on multiple options (e.g., Size + Color → specific material).

Example: A property that depends on both "Size" and "Color" options:
- `bindingId` → Size option binding
- `bindingId2` → Color option binding
- Property values are keyed by both `optionValueId` (size) and `optionValueId2` (color)

This creates a matrix of values:
| Size | Color | Material Value |
|------|-------|----------------|
| Small | Red | Red PLA, 50g |
| Small | Blue | Blue PLA, 50g |
| Large | Red | Red PLA, 100g |
| Large | Blue | Blue PLA, 100g |

## LinkedPart Integration

LinkedPart fields that connect to the variant system:

- `parameterBindings`: Maps part parameter names to SkuOptionProperty IDs
  - When an order comes in, the selected option value's property value overrides the part parameter

- `plateQuantitiesBinding`: SkuOptionProperty ID for plate quantities
  - Controls how many of each plate to print based on selected option

- `materialAssignments`: Direct material assignment (not variant-based)
  - Use when material is fixed, not selectable by customer

## Order Processing Flow

1. Order comes in with `selectedOptions` (array of optionValueIds)
2. System looks up SkuOptionPropertyValues matching selected values
3. For each LinkedPart:
   - Apply `parameterBindings` → override part parameters with textValue
   - Apply material from `materialValue`
   - Apply quantities from `plateQuantitiesValue`
4. Create PrintJobs with resolved parameters and materials
