# Printago Skill for Claude Code

A Claude Code plugin that lets Claude operate your [Printago](https://printago.io) 3D print farm through the `printago` CLI. Ask in plain language and Claude manages printers, print jobs, orders, parts, materials, SKUs, builds, and more.

## Requirements

This skill drives the [Printago CLI](https://docs.printago.io/docs/api/cli). Install it first (it needs Node.js 18+):

```bash
brew install printago/tap/printago    # macOS / Linux
npm install -g @printago/cli          # any platform
```

Then authenticate once (your API key is entered hidden and stored locally):

```bash
printago auth login
```

## Installation

### Plugin marketplace (recommended)

```
/plugin marketplace add printago/printago-skill
/plugin install printago-skill@printago-skill
```

### With the CLI

If you have the CLI installed, it can install the same skill into your personal skills:

```bash
printago skill install
```

Start a new Claude Code session (or run `/reload-plugins`) to pick it up.

## Usage

Ask Claude in plain language:

- "Show me which printers are idle."
- "Requeue the failed jobs from order 1234."
- "Upload model.3mf and queue it for printing."

Claude runs the `printago` commands and reads the structured JSON results. The skill teaches it the command conventions, how to handle your credentials safely, and the common multi-step workflows.

## Learn more

- [CLI documentation](https://docs.printago.io/docs/api/cli)
- [AI Agents & Skills](https://docs.printago.io/docs/api/ai-agents)
- [Printago API](https://developers.printago.io)
