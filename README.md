# Lua Obfuscator

A tool for obfuscating/encrypting Lua source code to protect intellectual property.

## Prerequisites

- Node.js installed on your system
- Lua interpreter (version must match between obfuscation and execution)

## Installation

### Option 1: Clone Repository
```bash
git clone https://github.com/rchakim/lua-obfuscator.git
cd lua-obfuscator
```

### Option 2: Download ZIP
1. Download the repository ZIP from GitHub
2. Extract the contents to your preferred location

## Usage

To obfuscate a Lua file:
```bash
lua cli.lua input_file.lua
```

The tool will generate obfuscated output.

## Important Note

**Version Compatibility Warning**: The obfuscated code must be executed using the same Lua version that was used for obfuscation. For example:
- If you obfuscate with Lua 5.2, you must run the obfuscated code with Lua 5.2
- Using a different Lua version may cause execution errors

## Features

- Code encryption to protect intellectual property
- Preserves original functionality while obscuring readability
- CLI interface for easy integration into build processes

This version improves readability, adds more structure, and clarifies the purpose and requirements of the tool.
