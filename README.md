# Printago Skill for Claude Code

A Claude Code plugin for interacting with the [Printago](https://printago.io) 3D print farm automation platform. Manage parts, printers, print jobs, SKUs, orders, and more directly from Claude.

## Installation

### Via Plugin System (Recommended)

```bash
claude /plugin install printago
```

### Manual Installation

Clone this repo and load it as a plugin:

```bash
git clone https://github.com/printago/printago-skill.git
claude --plugin-dir ./printago-skill
```

Or extract `skills/printago/` to `~/.claude/skills/` for standalone use.

## Setup

### 1. Get API Credentials

1. Log in to [Printago](https://app.printago.io)
2. Go to Addons > API Access
3. Create a new API key and note your Store ID

### 2. Store Credentials

Credentials are loaded from environment variables or system keychain.

**Option A: System Keychain (Recommended)**

```bash
# macOS
security add-generic-password -s "Printago" -a "apiKey" -w "your-api-key"
security add-generic-password -s "Printago" -a "storeId" -w "your-store-id"

# Linux
secret-tool store --label="Printago API Key" service Printago key apiKey
secret-tool store --label="Printago Store ID" service Printago key storeId
```

```powershell
# Windows
cmdkey /generic:Printago_apiKey /user:apiKey /pass:your-api-key
cmdkey /generic:Printago_storeId /user:storeId /pass:your-store-id
```

**Option B: Environment Variables**

```bash
export PRINTAGO_API_KEY=your-api-key
export PRINTAGO_STORE_ID=your-store-id
```

## Usage

Once installed, Claude will automatically use the Printago skill when relevant. You can also invoke it directly:

```
/printago
```

### Example Prompts

- Upload benchy.stl, name it 'Tugboat', create a SKU with 2 copies, and print it in PLA Basic Blue
- Import orders from @orders.csv and queue everything for printing
- Print 10 benchys in PLA Basic Purple
- Copy the color and size options from the Widget SKU to the Gadget SKU
- Which printers are printing right now and what are they working on?
- What do I need to print for my open orders?
- Cancel all pending jobs for the BENCHY SKU

### Scripts

The skill includes helper scripts for common operations:

| Script | Purpose |
|--------|---------|
| `api.sh` / `api.ps1` | Make authenticated API requests |
| `upload.sh` / `upload.ps1` | Upload files to storage |
| `schema.sh` / `schema.ps1` | Fetch API schemas (no auth) |

```bash
# Examples
api.sh GET /v1/parts
api.sh POST /v2/builds '{"parts":[{"partId":"abc","quantity":1}]}'
upload.sh model.stl
schema.sh types Part
```

## Documentation

- [SKILL.md](skills/printago/SKILL.md) - Quick reference
- [TYPES.md](skills/printago/TYPES.md) - Entity definitions
- [SKU-VARIANTS.md](skills/printago/SKU-VARIANTS.md) - SKU variant system
- [WORKFLOWS.md](skills/printago/WORKFLOWS.md) - Common workflows

## Requirements

- Claude Code v1.0.33+
- `curl` and `jq` (for bash scripts)
- Node.js not required

## License

MIT
