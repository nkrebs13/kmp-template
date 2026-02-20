#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawnSync } from "child_process";
import {
  existsSync,
  mkdirSync,
  cpSync,
  rmSync,
  readFileSync,
  readdirSync,
} from "fs";
import { join, dirname, resolve, normalize } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const TEMPLATE_DIR = dirname(__dirname);

// Read version from package.json
const packageJson = JSON.parse(
  readFileSync(join(__dirname, "package.json"), "utf-8")
);

const server = new Server(
  {
    name: "kmp-template",
    version: packageJson.version,
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "generate",
        description:
          "Generate a new Kotlin Multiplatform project from the template. Creates a fully configured KMP project with the specified name and package.",
        inputSchema: {
          type: "object",
          properties: {
            projectName: {
              type: "string",
              description:
                "Name of the project (e.g., MyAwesomeApp). Must start with a letter and contain only alphanumeric characters.",
            },
            packageName: {
              type: "string",
              description:
                "Package name (e.g., com.company.app). Must be lowercase with at least 2 parts separated by dots.",
            },
            outputDir: {
              type: "string",
              description:
                "Directory where the project will be created. Will be created if it doesn't exist.",
            },
            iosBundleId: {
              type: "string",
              description:
                "iOS bundle identifier. Defaults to packageName if not specified.",
            },
          },
          required: ["projectName", "packageName", "outputDir"],
        },
      },
      {
        name: "validate",
        description:
          "Validate a generated project to ensure no template references remain. Checks all source files for 'com.template', 'TemplateApp', and other template-specific strings.",
        inputSchema: {
          type: "object",
          properties: {
            projectDir: {
              type: "string",
              description: "Path to the project directory to validate.",
            },
          },
          required: ["projectDir"],
        },
      },
      {
        name: "list_dependencies",
        description:
          "List all dependencies included in the KMP template with their versions.",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "generate":
      return handleGenerate(args);
    case "validate":
      return handleValidate(args);
    case "list_dependencies":
      return handleListDependencies();
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

/**
 * Validates that a path is safe and doesn't escape expected boundaries.
 * @param {string} inputPath - The path to validate
 * @param {string} [basePath] - Optional base path that the input must be within
 * @returns {{ isValid: boolean, normalizedPath: string, error?: string }}
 */
function validatePath(inputPath, basePath = null) {
  if (!inputPath || typeof inputPath !== "string") {
    return { isValid: false, normalizedPath: "", error: "Path is required" };
  }

  // Reject null bytes (path truncation attack)
  if (inputPath.includes("\0")) {
    return {
      isValid: false,
      normalizedPath: "",
      error: "Path contains null bytes",
    };
  }

  // Normalize the path to resolve .. and . segments
  const normalizedPath = normalize(resolve(inputPath));

  // If basePath is provided, ensure the normalized path is within it
  if (basePath) {
    const normalizedBase = normalize(resolve(basePath));
    // Check for exact match OR path starts with base + separator
    // This prevents /foo matching /foobar (must be /foo/bar)
    const isWithinBase =
      normalizedPath === normalizedBase ||
      normalizedPath.startsWith(normalizedBase + "/");
    if (!isWithinBase) {
      return {
        isValid: false,
        normalizedPath: "",
        error: "Path escapes the allowed directory",
      };
    }
  }

  return { isValid: true, normalizedPath };
}

/**
 * Creates an error response in MCP format.
 * @param {string} message - Error message
 * @returns {Object} MCP error response
 */
function errorResponse(message) {
  return {
    content: [{ type: "text", text: message }],
    isError: true,
  };
}

async function handleGenerate(args) {
  // Validate args object exists
  if (!args || typeof args !== "object") {
    return errorResponse("Error: Invalid arguments provided");
  }

  const { projectName, packageName, outputDir, iosBundleId } = args;

  // Validate required fields exist and are strings
  if (typeof projectName !== "string" || !projectName) {
    return errorResponse("Error: projectName is required and must be a string");
  }
  if (typeof packageName !== "string" || !packageName) {
    return errorResponse("Error: packageName is required and must be a string");
  }
  if (typeof outputDir !== "string" || !outputDir) {
    return errorResponse("Error: outputDir is required and must be a string");
  }

  // Validate inputs strictly
  if (!/^[A-Za-z]/.test(projectName)) {
    return errorResponse(
      `Error: Project name must start with a letter.\n  Got: "${projectName}"\n  Suggestion: Start with a capital letter like "MyApp" or "WeatherApp"`
    );
  }
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(projectName)) {
    return errorResponse(
      `Error: Project name contains invalid characters.\n  Got: "${projectName}"\n  Only letters and numbers allowed (no spaces, hyphens, or special characters)`
    );
  }

  // Package name validation - allows standard Java package conventions
  if (!/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(packageName)) {
    return errorResponse(
      `Error: Invalid package name format.\n  Got: "${packageName}"\n  Requirements:\n  - Must be lowercase\n  - Must have at least 2 parts separated by dots\n  - Each part must start with a letter\n  Suggestion: Use format like "com.company.appname"`
    );
  }

  // Warn about very long package names
  if (packageName.length > 100) {
    return errorResponse(
      `Error: Package name is very long (${packageName.length} characters).\n  Long package names can cause build issues with file path limits.\n  Suggestion: Use a shorter package name (under 100 characters)`
    );
  }

  // Check for reserved package prefixes (platform/language namespaces)
  const RESERVED_PREFIXES = ['java.', 'javax.', 'android.', 'kotlin.', 'kotlinx.'];
  for (const prefix of RESERVED_PREFIXES) {
    if (packageName.startsWith(prefix)) {
      return errorResponse(
        `Error: Package name cannot start with reserved prefix '${prefix.slice(0, -1)}'. These namespaces are reserved for platform/language libraries.`
      );
    }
  }

  // Check for Java keywords and reserved words in package name parts
  // This list includes:
  // - All Java keywords (JLS 3.9)
  // - Reserved keywords (const, goto)
  // - Literals that cannot be identifiers (true, false, null)
  // - Underscore (reserved since Java 9)
  // - Contextual keywords that should be avoided (var, yield, record, sealed, permits)
  const javaKeywords = new Set([
    // Keywords
    "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
    "class", "const", "continue", "default", "do", "double", "else", "enum",
    "extends", "final", "finally", "float", "for", "goto", "if", "implements",
    "import", "instanceof", "int", "interface", "long", "native", "new",
    "package", "private", "protected", "public", "return", "short", "static",
    "strictfp", "super", "switch", "synchronized", "this", "throw", "throws",
    "transient", "try", "void", "volatile", "while",
    // Literals (not technically keywords but cannot be used as identifiers)
    "true", "false", "null",
    // Reserved identifier (Java 9+)
    "_",
    // Contextual keywords (Java 10+) - technically allowed in some contexts but problematic
    "var", "yield", "record", "sealed", "permits"
  ]);
  const packageParts = packageName.split(".");
  for (const part of packageParts) {
    if (javaKeywords.has(part)) {
      return errorResponse(
        `Error: Package name contains Java keyword or reserved word '${part}'. Java keywords and reserved words cannot be used as package name components. Consider adding a prefix or suffix, e.g., '${part}s' or 'my${part}'.`
      );
    }
  }

  // Validate and normalize outputDir path
  const pathValidation = validatePath(outputDir);
  if (!pathValidation.isValid) {
    return errorResponse(
      `Error: Invalid output directory: ${pathValidation.error}`
    );
  }
  const normalizedOutputDir = pathValidation.normalizedPath;

  // Additional safety: reject paths that look like system directories
  const dangerousPaths = ["/etc", "/usr", "/bin", "/sbin", "/var", "/root"];
  for (const dangerous of dangerousPaths) {
    if (normalizedOutputDir.startsWith(dangerous)) {
      return errorResponse(
        `Error: Cannot create project in system directory: ${normalizedOutputDir}`
      );
    }
  }

  const bundleId = iosBundleId || packageName;

  // Validate bundleId if provided
  // Apple allows: letters (mixed case), numbers, hyphens; each segment starts with a letter
  if (
    iosBundleId &&
    !/^[a-zA-Z][a-zA-Z0-9-]*(\.[a-zA-Z][a-zA-Z0-9-]*)+$/.test(iosBundleId)
  ) {
    return errorResponse(
      `Error: iOS bundle ID must have at least 2 parts separated by dots, each starting with a letter. Can contain letters, numbers, and hyphens. Got: ${iosBundleId}`
    );
  }

  try {
    // Check for uncommitted git changes in output directory (warning in response)
    let gitWarning = "";
    if (existsSync(join(normalizedOutputDir, ".git"))) {
      const gitStatus = spawnSync("git", ["status", "--porcelain"], {
        cwd: normalizedOutputDir,
        encoding: "utf-8",
      });
      if (gitStatus.stdout && gitStatus.stdout.trim()) {
        gitWarning = "\nWARNING: Target directory has uncommitted git changes. Generation will modify files extensively.\n";
      }
    }

    // Check if target directory already exists and has content
    // Using Node.js APIs instead of spawning ls for cross-platform compatibility
    if (existsSync(normalizedOutputDir)) {
      try {
        const files = readdirSync(normalizedOutputDir);
        if (files.length > 0) {
          return errorResponse(
            `Error: Target directory ${normalizedOutputDir} already exists and is not empty.`
          );
        }
      } catch (readErr) {
        return errorResponse(
          `Error: Cannot read target directory: ${readErr.message}`
        );
      }
    }

    // Create target directory
    mkdirSync(normalizedOutputDir, { recursive: true });

    // Copy template to target
    cpSync(TEMPLATE_DIR, normalizedOutputDir, { recursive: true });

    // Remove .git directory
    const gitDir = join(normalizedOutputDir, ".git");
    if (existsSync(gitDir)) {
      rmSync(gitDir, { recursive: true, force: true });
    }

    // Remove mcp directory from generated project
    const mcpDir = join(normalizedOutputDir, "mcp");
    if (existsSync(mcpDir)) {
      rmSync(mcpDir, { recursive: true, force: true });
    }

    // Run setup.sh with inputs using spawn for safety
    const setupScript = join(normalizedOutputDir, "setup.sh");
    if (!existsSync(setupScript)) {
      return errorResponse("Error: setup.sh not found in template directory.");
    }

    // Execute setup.sh with piped inputs using stdin (no shell interpolation)
    // This avoids command injection by passing data via stdin, not shell string
    const inputs = `${projectName}\n${packageName}\n${bundleId}\ny\n`;
    const result = spawnSync("bash", ["./setup.sh"], {
      cwd: normalizedOutputDir,
      input: inputs,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });

    if (result.status !== 0) {
      return errorResponse(
        `Error running setup.sh: ${result.stderr || result.stdout}`
      );
    }

    // Validate the generated project
    const validationResult = validateProject(normalizedOutputDir);

    let responseText = `Successfully generated project "${projectName}" at ${normalizedOutputDir}\n`;
    if (gitWarning) {
      responseText += gitWarning;
    }
    responseText += `\n`;
    responseText += `Configuration:\n`;
    responseText += `  - Project Name: ${projectName}\n`;
    responseText += `  - Package Name: ${packageName}\n`;
    responseText += `  - iOS Bundle ID: ${bundleId}\n\n`;

    if (validationResult.isValid) {
      responseText += `Validation: PASSED - No template references found.\n\n`;
    } else {
      responseText += `Validation: WARNING - Found ${validationResult.references.length} template references:\n`;
      validationResult.references.forEach((ref) => {
        responseText += `  - ${ref}\n`;
      });
      responseText += `\n`;
    }

    responseText += `Next steps:\n`;
    responseText += `  1. cd ${normalizedOutputDir}\n`;
    responseText += `  2. Create local.properties with: sdk.dir=/path/to/android/sdk\n`;
    responseText += `  3. ./gradlew :androidApp:assembleDebug\n`;
    responseText += `  4. Open iosApp/iosApp.xcodeproj in Xcode for iOS\n`;

    return {
      content: [
        {
          type: "text",
          text: responseText,
        },
      ],
    };
  } catch (error) {
    return errorResponse(`Error generating project: ${error.message}`);
  }
}

/**
 * Validates a project directory for remaining template references.
 * @param {string} projectDir - Path to the project directory (must be pre-validated)
 * @returns {{ isValid: boolean, references: string[], error?: string }}
 */
function validateProject(projectDir) {
  const references = [];

  // Search for template references using grep with explicit args (no shell)
  // Use com\.template\. (with trailing dot) to avoid matching packages like "com.mytemplate.app"
  const result = spawnSync(
    "grep",
    [
      "-ri",
      "-E",
      "com\\.template\\.|com\\.template[^a-z0-9]|com\\.template$|TemplateApp",
      projectDir,
      "--include=*.kt",
      "--include=*.kts",
      "--include=*.xml",
      "--include=*.swift",
      "--include=*.plist",
      "--include=*.pro",
      "--include=*.pbxproj",
      "--exclude-dir=.git",
      "--exclude-dir=build",
    ],
    { encoding: "utf-8" }
  );

  // grep exit codes: 0 = matches found, 1 = no matches, 2+ = error
  if (result.status === 2 || result.error) {
    const errorMsg = result.error?.message || result.stderr || "Unknown error";
    return {
      isValid: false,
      references: [],
      error: `Failed to validate project: ${errorMsg}`,
    };
  }

  if (result.stdout && result.stdout.trim()) {
    const lines = result.stdout.trim().split("\n");
    lines.forEach((line) => {
      // Filter out gradlew Groovy template reference
      if (!line.includes("generated from the Groovy template")) {
        references.push(line);
      }
    });
  }

  return {
    isValid: references.length === 0,
    references,
  };
}

async function handleValidate(args) {
  // Validate args object exists
  if (!args || typeof args !== "object") {
    return errorResponse("Error: Invalid arguments provided");
  }

  const { projectDir } = args;

  // Validate projectDir exists and is a string
  if (typeof projectDir !== "string" || !projectDir) {
    return errorResponse("Error: projectDir is required and must be a string");
  }

  // Validate and normalize the path
  const pathValidation = validatePath(projectDir);
  if (!pathValidation.isValid) {
    return errorResponse(
      `Error: Invalid project directory: ${pathValidation.error}`
    );
  }
  const normalizedProjectDir = pathValidation.normalizedPath;

  if (!existsSync(normalizedProjectDir)) {
    return errorResponse(
      `Error: Project directory does not exist: ${normalizedProjectDir}`
    );
  }

  const result = validateProject(normalizedProjectDir);

  // Check for validation errors
  if (result.error) {
    return errorResponse(result.error);
  }

  let responseText = `Validation Results for: ${normalizedProjectDir}\n\n`;

  if (result.isValid) {
    responseText += `Status: PASSED\n`;
    responseText += `No template references found in source files.\n`;
  } else {
    responseText += `Status: FAILED\n`;
    responseText += `Found ${result.references.length} template reference(s):\n\n`;
    result.references.forEach((ref, index) => {
      responseText += `${index + 1}. ${ref}\n`;
    });
    responseText += `\nThese references should be manually reviewed and updated.`;
  }

  return {
    content: [
      {
        type: "text",
        text: responseText,
      },
    ],
  };
}

async function handleListDependencies() {
  try {
    const versionCatalogPath = join(
      TEMPLATE_DIR,
      "gradle",
      "libs.versions.toml"
    );
    if (!existsSync(versionCatalogPath)) {
      return errorResponse(
        "Error: Version catalog not found at gradle/libs.versions.toml"
      );
    }

    const content = readFileSync(versionCatalogPath, "utf-8");

    // Parse versions section
    const versionsMatch = content.match(/\[versions\]([\s\S]*?)(?=\[|$)/);
    const versions = {};
    if (versionsMatch) {
      const lines = versionsMatch[1].split("\n");
      lines.forEach((line) => {
        const match = line.match(/^(\w+)\s*=\s*"([^"]+)"/);
        if (match) {
          versions[match[1]] = match[2];
        }
      });
    }

    let responseText = `# KMP Template Dependencies\n\n`;
    responseText += `## Core Versions\n`;
    responseText += `| Component | Version |\n`;
    responseText += `|-----------|----------|\n`;

    const coreKeys = [
      "kotlin",
      "agp",
      "compose",
    ];
    coreKeys.forEach((key) => {
      if (versions[key]) {
        responseText += `| ${key} | ${versions[key]} |\n`;
      }
    });

    responseText += `\n## All Versions\n`;
    Object.keys(versions)
      .sort()
      .forEach((key) => {
        responseText += `- ${key}: ${versions[key]}\n`;
      });

    return {
      content: [
        {
          type: "text",
          text: responseText,
        },
      ],
    };
  } catch (error) {
    return errorResponse(`Error reading dependencies: ${error.message}`);
  }
}

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("KMP Template MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error starting MCP server:", error);
  process.exit(1);
});
