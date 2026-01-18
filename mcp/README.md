# KMP Template MCP Server

A Model Context Protocol (MCP) server that enables AI assistants to generate and validate Kotlin Multiplatform projects from this template.

## Overview

This MCP server provides three tools for working with the KMP template:

| Tool | Description |
|------|-------------|
| `generate` | Create a new KMP project from the template |
| `validate` | Check a project for remaining template references |
| `list_dependencies` | List all dependencies with versions |

## Installation

### Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn

### Setup

1. Install dependencies:
   ```bash
   cd mcp
   npm install
   ```

2. Make the server executable:
   ```bash
   chmod +x index.js
   ```

### Claude Code Configuration

Add the server to your Claude Code MCP configuration:

**Claude Code** (add to `.mcp.json` in your project or `~/.claude.json` globally):
```json
{
  "mcpServers": {
    "kmp-template": {
      "command": "node",
      "args": ["/path/to/template/mcp/index.js"]
    }
  }
}
```

**Alternative using npx** (after publishing to npm):
```json
{
  "mcpServers": {
    "kmp-template": {
      "command": "npx",
      "args": ["@kmp-template/mcp-server"]
    }
  }
}
```

## Tools Reference

### generate

Creates a new Kotlin Multiplatform project from the template.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectName` | string | Yes | Project name (e.g., `MyApp`). Must start with a letter, alphanumeric only. |
| `packageName` | string | Yes | Package name (e.g., `com.example.myapp`). Lowercase, at least 2 dot-separated parts. |
| `outputDir` | string | Yes | Directory where the project will be created. |
| `iosBundleId` | string | No | iOS bundle identifier. Defaults to `packageName` if not specified. |

**Example:**
```
Generate a new KMP project called "WeatherApp" with package "com.example.weather" in ~/Projects/WeatherApp
```

**Validation Rules:**
- `projectName`: Must match `/^[A-Za-z][A-Za-z0-9]*$/`
- `packageName`: Must match `/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/`
- `outputDir`: Must not already exist or must be empty

### validate

Validates a generated project to ensure no template references remain.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectDir` | string | Yes | Path to the project directory to validate. |

**Checks:**
- Scans `.kt`, `.kts`, `.xml`, `.swift`, `.plist`, `.pro`, `.pbxproj` files
- Looks for `com.template` and `TemplateApp` patterns
- Excludes `.git/`, `build/`, and Gradle wrapper comments

**Example:**
```
Validate the project at ~/Projects/WeatherApp for template references
```

### list_dependencies

Lists all dependencies included in the KMP template with their versions.

**Parameters:** None

**Output:**
- Core versions table (Kotlin, AGP, Compose, etc.)
- Complete version catalog from `gradle/libs.versions.toml`

## Error Handling

The server returns structured error responses:

```json
{
  "content": [
    {
      "type": "text",
      "text": "Error: Project name must start with a letter..."
    }
  ],
  "isError": true
}
```

Common errors:
- Invalid project name format
- Invalid package name format
- Target directory already exists and is not empty
- Missing setup.sh script

## Security

The MCP server implements several security measures:

1. **Input Validation**: All inputs are validated against strict regex patterns before any shell execution
2. **Safe Command Execution**: Uses `spawnSync` with explicit argument arrays instead of shell interpolation
3. **No Arbitrary Code Execution**: Commands are constructed programmatically, not from user input

## Development

### Running Locally

```bash
cd mcp
npm start
```

### Testing

The server communicates via stdio using the MCP protocol. For testing:

1. Generate a test project:
   ```bash
   # Use Claude Code with the MCP server configured
   # Or use the MCP CLI tools
   ```

2. Validate manually:
   ```bash
   ../scripts/validate.sh /path/to/generated/project
   ```

## Troubleshooting

### Server Not Starting

1. Check Node.js version: `node --version` (requires 18+)
2. Reinstall dependencies: `rm -rf node_modules && npm install`
3. Check file permissions: `ls -la index.js`

### Generation Fails

1. Ensure the template directory contains `setup.sh`
2. Check that the output directory doesn't exist or is empty
3. Verify package name follows Java naming conventions

### Validation Shows False Positives

The validator filters out known acceptable references:
- Gradle wrapper's "Groovy template" comment
- Build cache files

If you see other false positives, check if they're in excluded directories.

## Architecture

```
mcp/
├── index.js          # MCP server implementation
├── package.json      # Node.js package configuration
├── node_modules/     # Dependencies (not committed)
└── README.md         # This file

scripts/
└── validate.sh       # Standalone validation script
```

The server uses the `@modelcontextprotocol/sdk` package to implement the MCP protocol over stdio.

## License

MIT License - See the root LICENSE file for details.
