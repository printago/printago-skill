---
name: printago
description: >-
  Operate a Printago 3D print farm through the printago CLI (379 API
  endpoints). Use when the user wants to list, inspect, or mutate printers,
  print jobs, orders, parts, materials, SKUs, profiles, builds, maintenance,
  API keys, or integrations (Shopify/Etsy/eBay/TikTok) against their live
  Printago store. Commands: printago <group> <action>.
---

# Printago CLI

Operate a Printago print farm via the `printago` command, a zero-dependency
client wrapping the entire Printago REST API.

This skill drives the `printago` CLI. If `printago` is not found, install it
(it requires Node.js 18+):

```bash
brew install printago/tap/printago    # macOS / Linux
npm install -g @printago/cli          # any platform
```

When piped (non-TTY), every command returns a single-line JSON envelope, so you
can parse stdout directly:
`{ ok, command, method, path, status, meta?, result, next_actions? }`.
Errors are `{ ok:false, error:{message,code,status}, fix, details }`.

## Credentials — do NOT ask the user to paste their API key into chat

Check auth first:

```bash
printago auth status
```

If `authenticated` is false, the key must be set **without exposing it in the
conversation**. Ask the user to run this themselves with the `!` prefix so the
key never enters the transcript:

```
!printago auth login
```

(interactive: prompts for store id + a hidden API key, saved to
`~/.config/printago/credentials.json`, mode 0600). Alternatively they can export
`PRINTAGO_API_KEY` / `PRINTAGO_STORE_ID`. Never echo, log, cat, or pass the key
as a visible CLI argument.

## Discovering commands

The CLI is self-documenting — don't guess command names, list them:

```bash
printago                 # all 38 command groups
printago printers        # commands in a group
printago printers get --help   # method, path, and full request-body fields
printago parts create --help   # shows every body field, type, and which are required
```

`--help` resolves the request-body schema and lists its fields (name, type,
`*`=required). **You almost never need to read the API source or OpenAPI spec to
construct a body — run `--help` first.** For nested object/array field types
(e.g. `EmbeddedPartMaterialAssignments`), get the full JSON schema with
`printago hints schema-types-get <TypeName>`.

Common groups: `printers`, `print-jobs`, `orders`, `order-items`, `parts`,
`materials`, `material-variants`, `skus`, `sku-variants`, `profiles`,
`part-builds`, `maintenance`, `api-keys`, `subscriptions`, `folders`,
`shopify`, `etsy`, `e-bay`, `tik-tok`.

Naming convention: `list`, `get <id>`, `create`, `update <id>`, `delete <id>`,
`search`, plus action-named subcommands (`printers snapshot <id>`,
`print-jobs cancel`, `print-jobs retry`, `orders cancel <orderId>`).

## Discover available actions (hints)

The API self-describes the meaningful actions for each object type. The CLI
surfaces them so you can find the right command for a goal without scanning all
379 endpoints. **No credentials needed** (hints are public).

```bash
printago hints                 # which objects have hints + their CLI group
printago hints printer         # actions for an object, each mapped to a command
printago hints print-jobs
printago printers list --hints # attach hints to a normal response
printago hints schema-types-get Printer   # JSON schema for a data type
```

## Reading data

List and search endpoints return a `{ data, meta }` envelope (the CLI sends
`meta=true` by default), so you get `meta.total` / `meta.count` / `hasMore` for
pagination. `result` is the rows. Opt out with `--no-meta`.

```bash
printago printers list --limit 10
printago orders list --all          # auto-paginate every page
printago print-jobs get <jobId>
```

### Filtering (important)

Filter on the **`list`** command, not `search`. Pass `--filter` as
`{field:{op:value}}` JSON, or `-q field.op=value` directly:

```bash
printago print-jobs list --filter '{"status":{"eq":"printing"}}'
printago print-jobs list -q status.eq=printing
printago print-jobs list -q status.in=printing,paused
printago parts list -q name.contains=bracket --limit 20
```

Operators: `eq, ne, gt, gte, lt, lte, contains, startsWith, endsWith, in, notIn,
isNull, between`. Multiple `-q` conditions AND together.

⚠️ **Do NOT filter via `search`.** The API currently ignores a `filter` sent in
the POST `/search` body and returns *everything*; the CLI prints a `warning`
field when you do this. Logical `and`/`or`/`not` filters aren't expressible as
list query params yet (the CLI errors clearly instead of returning all rows).

## Mutating data

Bodies come from `--data` (inline JSON, `@file.json`, or `-` for stdin). Run the
command with `--help` first — it lists every body field and which are required.

```bash
printago parts create --data @part.json
printago printers update <id> --data '{"name":"Printer 2"}'
printago print-jobs cancel --data '{"printJobIds":["<jobId>"]}'
```

Mutations hit the user's live store. For destructive actions (`delete`,
`delete-many`, `orders batch-delete`, cancel/clear queues) confirm with the user
before running.

## Uploading files

File upload is a signed-URL handshake then a raw PUT of the bytes. The `upload`
command does both and prints the `fileUri` to hand to `parts create`:

```bash
printago upload model.3mf
# -> { "fileUris": ["uploads:<store>/<id>/model.3mf"], ... }
```

## Common workflow: upload a file and queue it for printing

There is no `print-jobs create`; jobs are spawned by a build. The chain is
upload → part → build. When unsure of a body shape, run the command with
`--help`, or `printago hints <entity>` (it encodes this chain).

```bash
# 1. upload the model, capture the returned fileUri
printago upload model.3mf

# 2. create a part referencing it (see `parts create --help` for all fields)
printago parts create --data '{"name":"My Model","type":"3mf","fileUris":["<fileUri>"]}'

# 3. preview, then queue a build (POST /v2/builds lives in `printing`)
printago printing preview --data '{"parts":[{"partId":"<partId>"}]}'
printago printing create  --data '{"parts":[{"partId":"<partId>"}]}'

# 4. let the matcher assign it, or pin a job to a printer
printago print-jobs queue-run
printago print-jobs send-to-printer <jobId> --data '{"printerId":"<printerId>"}'
```

### Diagnose the queue
```bash
printago print-jobs list -q status.eq=printing
printago print-jobs matching-troubleshoot <jobId>   # why isn't it matching a printer?
printago printers snapshot <printerId>               # live camera snapshot
```

### Point at local dev instead of prod
```bash
!printago auth set-base-url http://localhost:3001
# or per-call: printago printers list --base-url http://localhost:3001
```
