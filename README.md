# **Lua Obfuscator**  
*A tool for obfuscating/encrypting Lua source code to protect intellectual property*

---

## Prerequisites
- Lua interpreter (version must match between obfuscation and execution)

---

## **Installation**  

### **Option 1: Clone the Repository**  
```bash
git clone https://github.com/rchakim/lua-obfuscator.git
cd lua-obfuscator
```  

### **Option 2: Download as ZIP**  
Download the latest release from GitHub and extract it.  

---

## **Usage**  
Run the obfuscator via the **Command Line Interface (CLI)**:  

```bash
lua cli.lua <input_file.lua> [preset]
```  

### **Parameters**  
| Argument | Description |  
|----------|-------------|  
| `input_file.lua` | Path to the Lua file you want to obfuscate |  
| `preset` *(optional)* | Obfuscation method (default: byte transformation) |  

### **Available Presets**  
- `--b` → **Byte transformation** *(default, preset 1)*  
- `--h` → **Hex transformation** *(preset 2)*  

### **Example**  
```bash
lua cli.lua script.lua --h
```  
→ Generates: `script.enc.lua`  

---

## **Important Notes**  

### **1. Version Compatibility**  
- The obfuscated script **must** be executed using the **same Lua version** used for obfuscation.  

### **2. Output Files**  
| Result | Output File |  
|--------|-------------|  
| Success | `<input>.enc.lua` |  
| Failure | `<input>.err.lua` (contains error details) |  

### **3. Transformations Applied**  
- **String Conversion** → Escaped byte representation  
- **Dot Notation** → Converted to bracket notation (`obj.method` → `obj["method"]`)  
- **Method-Style Functions** → Changed to assignment-style (`function obj:method()` → `obj.method = function()`)  
- **Preset-Based String Encoding** (Byte or Hex)  

### **4. Error Handling**  
- Syntax validation before obfuscation.  
- Clear error messages if the process fails.  

---

### **Why Use This Obfuscator?**  
- Protects intellectual property by making code harder to reverse-engineer.  
- Lightweight transformations without breaking functionality.  
- Supports multiple encoding methods.  

---
