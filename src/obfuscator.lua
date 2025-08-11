-- Creator: Arif Rahman
-- Copyright (c) 2025 Arif Rahman. All rights reserved.

-- Load required modules for string transformation
local translator = require("src.translator")
local byteTransformer = require("src.byte")
local hexTransformer = require("src.hex")

-- Parses Lua code to identify strings and comments, invoking a callback for each
-- @param luaCode The input Lua code to parse
-- @param callback Function to process identified strings or comments
local function parseStringsAndComments(luaCode, callback)
    local tokens = {}
    -- Identify single-line and multi-line comments
    for startPos, openBracket, equals, closeBracket in luaCode:gmatch("()%-%-(%-*%[?)(=*)(%[?)") do
        table.insert(tokens, {
            startPos = startPos,
            terminator = openBracket == "[" and closeBracket == "[" and "]" .. equals .. "]" or "\n",
        })
    end
    -- Identify multi-line strings
    for startPos, equals in luaCode:gmatch("()%[(=*)%[[%[=]*") do
        table.insert(tokens, { isString = true, startPos = startPos, terminator = "]" .. equals .. "]" })
    end
    -- Identify single/double-quoted strings
    for startPos, quote in luaCode:gmatch("()(['\"])") do
        table.insert(tokens, { isString = true, startPos = startPos, quote = quote })
    end
    -- Sort tokens by starting position
    table.sort(tokens, function(a, b)
        return a.startPos < b.startPos
    end)
    
    local endPos = 0
    for _, token in ipairs(tokens) do
        local startPos, found, char = token.startPos
        if startPos > endPos then
            if token.terminator == "\n" then
                -- Find end of single-line comment
                endPos = luaCode:find("\n", startPos + 1, true) or #luaCode
                while luaCode:sub(endPos, endPos):match("%s") do
                    endPos = endPos - 1
                end
            elseif token.terminator then
                -- Find end of multi-line comment or string
                found, endPos = luaCode:find(token.terminator, startPos + 1, true)
                assert(found, "Invalid Lua code: Unclosed terminator")
            else
                -- Find end of quoted string
                endPos = startPos
                repeat
                    found, endPos, char = luaCode:find("(\\?.)", endPos + 1)
                    assert(found, "Invalid Lua code: Unclosed string")
                until char == token.quote
            end
            -- Extract content and remove leading comment markers/spaces
            local content = luaCode:sub(startPos, endPos):gsub("^%-*%s*", "")
            if token.terminator ~= "\n" then
                -- Evaluate non-comment content (strings) to their Lua value
                content = assert((loadstring or load)("return " .. content))()
            end
            callback(token.isString and "string" or "comment", content, startPos, endPos)
        end
    end
end

-- Converts a string to its escaped byte representation
-- @param inputString The string to convert
-- @return A string with escaped byte values
local function stringToEscapedBytes(inputString)
    if inputString == "" then
        return "''"
    end
    return "'" .. inputString:gsub(".", function(char)
        return "\\" .. char:byte()
    end):gsub(" ", "") .. "'"
end

-- Replaces dot notation with bracket notation in Lua code
-- @param luaCode The input Lua code
-- @return Transformed code with bracket notation
local function convertDotToBracket(luaCode)
    luaCode = luaCode:gsub("%s*%.%s*", ".")
    luaCode = luaCode:gsub("([%w_]+)%.([%w_]+)", '%1["%2"]')
    luaCode = luaCode:gsub("%]%.([%w_]+)", ']["%1"]')
    luaCode = luaCode:gsub("([%w_]+)%.%([%w_]+)%(", '%1["%2"](')
    luaCode = luaCode:gsub("%)%.([%w_]+)", ')["%1"]')
    return luaCode
end

-- Converts method-style function declarations to assignment-style
-- @param luaCode The input Lua code
-- @return Transformed code with assignment-style functions
local function convertToAssignmentFunctions(luaCode)
    return luaCode:gsub("function%s*([%w_]+%[.-%])%s*%(", "%1 = function(")
end

-- Converts a string to a table of byte values prefixed with an identifier
-- @param inputString The string to convert
-- @param identifier The identifier to prepend
-- @return A string representation of the byte table
local function stringToByteTable(inputString, identifier)
    if inputString == "" then
        return "''"
    end
    return identifier .. "{" .. table.concat({inputString:byte(1, -1)}, ",") .. "}"
end

-- Obfuscates Lua code by transforming strings and applying transformations
-- @param luaCode The input Lua code to obfuscate
-- @param preset The transformation preset (1 for byte, 2 for hex)
-- @return The obfuscated code or nil/0 on error with error data
local function obfuscateLuaCode(luaCode, preset)
    -- Validate Lua code
    local test, err = load("\t" .. luaCode)
    if not test then
        err = err or "Unknown error"
        print("Failed to read file: " .. err)
        return
    end

    -- Generate 64 unique 6-character identifiers (uppercase letters)
    local identifiers = {}
    repeat
        local newId = ""
        local isUnique = true
        for _ = 1, 6 do
            newId = newId .. string.char(math.random(65, 90))
        end
        for _, id in ipairs(identifiers) do
            if id == newId then
                isUnique = false
                break
            end
        end
        if isUnique and not luaCode:match(newId) then
            identifiers[#identifiers + 1] = newId
        end
    until #identifiers == 64

    -- Convert strings to escaped byte representation
    local function convertStringsToBinary(inputCode)
        local currentPos = 1
        local fragments = {}
        parseStringsAndComments(inputCode, function(object, value, startPos, endPos)
            if object == "string" then
                table.insert(fragments, inputCode:sub(currentPos, startPos - 1))
                table.insert(fragments, stringToEscapedBytes(value))
                currentPos = endPos + 1
            end
        end)
        table.insert(fragments, inputCode:sub(currentPos))
        return table.concat(fragments)
    end

    local transformers = {byteTransformer, hexTransformer}
    local transformCount = 0
    local transformedStrings = {}

    -- Transform strings using the specified preset
    local function transformString(inputString)
        if inputString == "" then
            return "''"
        end
        inputString = assert((load or loadstring)('return "' .. inputString .. '"'))()
        if not transformedStrings[inputString] then
            transformCount = transformCount + 1
            transformedStrings[inputString] = identifiers[1] .. transformers[preset](inputString, transformCount, identifiers[2])
        end
        return transformedStrings[inputString]
    end

    -- Apply transformations to the code
    luaCode = convertStringsToBinary(luaCode)
    luaCode = convertDotToBracket(luaCode)
    luaCode = convertToAssignmentFunctions(luaCode)
    luaCode = luaCode:gsub("'(.-)'", transformString)
    luaCode = luaCode:gsub('"(.-)"', transformString)
    luaCode = luaCode:gsub("([%w_%]]+)%s*" .. identifiers[1] .. "{(.-)}", "%1(" .. identifiers[1] .. "{%2})")

    -- Modify the translator with the preset and transform its strings
    translator = translator:gsub("c%[9%] = 1", "c[9] = " .. preset)
    translator = translator:gsub('"(.-)"', function(str)
        str = load('return "' .. str .. '"')()
        return stringToByteTable(str, identifiers[11])
    end)
    for i, id in ipairs(identifiers) do
        translator = translator:gsub("c" .. '%[' .. i .. '%]', id)
    end

    -- Wrap code in an IIFE (Immediately Invoked Function Expression)
    luaCode = "(function()\n\t" .. luaCode:gsub("\n", "\n\t") .. "\nend)"

    -- Prepare and validate the final code
    local finalData = "local " .. identifiers[1] .. ", " .. identifiers[2] .. ", " .. identifiers[3] .. "\nreturn " .. luaCode
    test, err = load(finalData)
    if not test then
        err = err or "Unknown error"
        print("Failed to encrypt script: " .. err)
        return 0, finalData
    end

    -- Insert code into translator and dump as bytecode
    luaCode = luaCode:gsub("\n", "\n\t")
    luaCode = translator:gsub("%-%- content", luaCode)
    luaCode = string.dump(load(luaCode), true)

    return luaCode
end

-- Command-line interface for obfuscation
if arg and #arg >= 1 then
    local inputFile = arg[1]
    local preset = arg[2]

    -- Determine preset (1 for byte, 2 for hex)
    if not preset or preset == "" or preset == "--b" then
        preset = 1
    elseif preset == "--h" then
        preset = 2
    else
        print("Preset not found!")
        return
    end

    -- Validate input file extension
    if not inputFile:match("%.lua$") then
        print("Please select *.lua file")
        return
    end

    -- Read input file
    local fileHandle, err = io.open(inputFile, "rb")
    if not fileHandle then
        err = err or "Unknown error"
        print(err)
        return
    end
    local content = fileHandle:read("*a")
    fileHandle:close()

    -- Define output paths
    local outputPath = inputFile:gsub("%.lua$", "") .. ".enc.lua"
    local errorPath = inputFile:gsub("%.lua$", "") .. ".err.lua"

    -- Obfuscate the code
    local obfuscatedCode, errorData = obfuscateLuaCode(content, preset)
    if not obfuscatedCode then
        return
    elseif obfuscatedCode == 0 then
        io.open(errorPath, "w"):write(errorData):close()
        print("⚠️ Encryption Failed")
        print("📁 The file has been saved on: " .. errorPath)
        print("📎 Please check again and correct any errors.")
        return
    end

    -- Calculate and format file size
    local size = #obfuscatedCode
    if size < 1024 then
        size = size .. " B"
    elseif size < 1048576 then
        size = string.format("%.2f Kb", size / 1024)
    else
        size = string.format("%.2f Mb", size / 1048576)
    end

    -- Write obfuscated code to file
    io.open(outputPath, "w"):write(obfuscatedCode):close()
    print("🎉 Encryption successful")
    print("📁 The file has been saved on: " .. outputPath)
    print("📄 Size: " .. size)
end