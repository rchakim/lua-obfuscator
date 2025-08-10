-- Creator: Arif Rahman
-- Copyright (c) 2025 Arif Rahman. All rights reserved.

-- Loads the translation module for string manipulation
local translator = require("src.translate")

-- Parses Lua code to identify strings and comments, invoking a callback for each
local function parse_strings_and_comments(lua_code, callback)
    local tokens = {}
    -- Capture comment patterns (single-line or multi-line)
    for start_pos, open_bracket, equals, close_bracket in lua_code:gmatch("()%-%-(%-*%[?)(=*)(%[?)") do
        table.insert(tokens, {
            startPos = start_pos,
            terminator = open_bracket == "[" and close_bracket == "[" and "]" .. equals .. "]" or "\n",
        })
    end
    -- Capture multi-line string patterns
    for start_pos, equals in lua_code:gmatch("()%[(=*)%[[%[=]*") do
        table.insert(tokens, { isString = true, startPos = start_pos, terminator = "]" .. equals .. "]" })
    end
    -- Capture single/double-quoted string patterns
    for start_pos, quote in lua_code:gmatch("()(['\"])") do
        table.insert(tokens, { isString = true, startPos = start_pos, quote = quote })
    end
    -- Sort tokens by their starting position
    table.sort(tokens, function(a, b)
        return a.startPos < b.startPos
    end)
    local end_pos = 0
    for _, token in ipairs(tokens) do
        local start_pos, found, char = token.startPos
        if start_pos > end_pos then
            if token.terminator == "\n" then
                -- Handle single-line comments until newline
                end_pos = lua_code:find("\n", start_pos + 1, true) or #lua_code
                while lua_code:sub(end_pos, end_pos):match("%s") do
                    end_pos = end_pos - 1
                end
            elseif token.terminator then
                -- Handle multi-line strings/comments
                found, end_pos = lua_code:find(token.terminator, start_pos + 1, true)
                assert(found, "Not a valid Lua code")
            else
                -- Handle quoted strings
                end_pos = start_pos
                repeat
                    found, end_pos, char = lua_code:find("(\\?.)", end_pos + 1)
                    assert(found, "Not a valid Lua code")
                until char == token.quote
            end
            local content = lua_code:sub(start_pos, end_pos):gsub("^%-*%s*", "")
            if token.terminator ~= "\n" then
                content = assert((loadstring or load)("return " .. content))()
            end
            callback(token.isString and "string" or "comment", content, start_pos, end_pos)
        end
    end
end

-- Converts a string to its binary (byte) representation
local function to_binary_string(str)
    if str == "" then
        return "''"
    end
    return "'" .. str:gsub(".", function(s)
        return "\\" .. s:byte()
    end):gsub(" ", "") .. "'"
end

-- Replaces dot notation with bracket notation for table access
local function convert_dots_to_brackets(lua_code)
    lua_code = lua_code:gsub("%s*%.%s*", ".")
    lua_code = lua_code:gsub("([%w_]+)%.([%w_]+)", '%1["%2"]')
    lua_code = lua_code:gsub("%]%.([%w_]+)", ']["%1"]')
    lua_code = lua_code:gsub("([%w_]+)%.%([%w_]+)%(", '%1["%2"](')
    lua_code = lua_code:gsub("%)%.([%w_]+)", ')["%1"]')
    return lua_code
end

-- Converts method-style function declarations to explicit assignments
local function convert_to_function_assignments(lua_code)
    return lua_code:gsub("function%s*([%w_]+%[.-%])%s*%(", "%1 = function(")
end

-- Converts a string to a table of byte values with additional metadata
local function encode_to_bytes(str, index, identifier)
    if str == "" then
        return "''"
    end
    str = { str:byte(1, -1) }
    str[#str + 1] = index
    str[#str + 1] = identifier
    return "{" .. table.concat(str, ",") .. "}"
end

-- Obfuscates Lua code by transforming strings and restructuring code
local function obfuscate_code(lua_code, preset, preserve_bytecode)
    -- Validate the input Lua code
    local test, err = load("\t" .. lua_code)
    if not test then
        if not err then
            err = "Unknown error"
        end
        print("Failed to read file: " .. err)
        return
    end

    -- Generate 64 unique 6-character identifiers
    local identifiers = {}
    repeat
        local new_id = ""
        local is_unique = true
        for i = 1, 6 do
            new_id = new_id .. string.char(math.random(65, 90))
        end
        for _, v in next, identifiers do
            if v == new_id then
                is_unique = false
                break
            end
        end
        if is_unique and not lua_code:match(new_id) then
            identifiers[#identifiers + 1] = new_id
        end
    until #identifiers == 64

    -- Convert all strings in the code to binary representation
    local function convert_strings_to_binary(lua_code)
        local pos = 1
        local text = {}
        parse_strings_and_comments(lua_code, function(object, value, start_pos, end_pos)
            if object == "string" then
                table.insert(text, lua_code:sub(pos, start_pos - 1))
                table.insert(text, to_binary_string(value))
                pos = end_pos + 1
            end
        end)
        table.insert(text, lua_code:sub(pos))
        return table.concat(text)
    end

    local string_counter = 0
    local string_map = {}

    -- Replaces strings with obfuscated references
    local function obfuscate_strings(str)
        if str == "" then
            return "''"
        end
        str = assert((load or loadstring)('return "' .. str .. '"'))()
        if not string_map[str] then
            string_counter = string_counter + 1
            string_map[str] = identifiers[1] .. encode_to_bytes(str, string_counter, identifiers[2])
        end
        return string_map[str]
    end

    lua_code = convert_strings_to_binary(lua_code)
    lua_code = convert_dots_to_brackets(lua_code)
    lua_code = convert_to_function_assignments(lua_code)
    lua_code = lua_code:gsub("'(.-)'", function(s)
        return obfuscate_strings(s)
    end)
    lua_code = lua_code:gsub('"(.-)"', function(s)
        return obfuscate_strings(s)
    end)
    lua_code = lua_code:gsub("([%w_%]]+)%s*" .. identifiers[1] .. "{(.-)}", "%1(" .. identifiers[1] .. "{%2})")

    -- Replace placeholder identifiers in the translator module
    for i, v in next, identifiers do
        translator = translator:gsub("c" .. i, v)
    end

    -- Replace string.char with a precomputed byte table
    local byte_table = {}
    for i = 1, 256 do
        byte_table[i] = "'\\" .. (i - 1) .. "'"
    end
    translator = translator:gsub("string%.char", "{" .. table.concat(byte_table, ",") .. "}")

    -- Wrap the code in an IIFE (Immediately Invoked Function Expression)
    lua_code = "(function()\n\t" .. lua_code:gsub("\n", "\n\t") .. "\nend)"

    -- Prepare the final code with local declarations for identifiers
    local data = "local " .. identifiers[1] .. ", " .. identifiers[2] .. ", " .. identifiers[3] .. "\nreturn " .. lua_code
    test, err = load(data)
    if not test then
        if not err then
            err = "Unknown error"
        end
        print("Failed to encrypt script: " .. err)
        return 0, data
    end

    lua_code = lua_code:gsub("\n", "\n\t")
    lua_code = translator:gsub("%-%- content", lua_code)
    if not preserve_bytecode then
        lua_code = string.dump(load(lua_code), true)
    end

    return lua_code
end

-- Main script to handle file input and output
if arg and #arg >= 1 then
    local input_file = arg[1]

    -- Validate that the input file is a Lua file
    if not input_file:match("%.lua$") then
        print("Please select *.lua file")
        return
    end

    -- Read the input file
    local file_handle, err = io.open(input_file, "rb")
    if not file_handle then
        if not err then
            err = "Unknown error"
        end
        print(err)
        return
    end
    local content = file_handle:read("*a")
    file_handle:close()

    -- Define output paths
    local output_path = input_file:gsub("%.lua$", "") .. ".enc.lua"
    local error_path = input_file:gsub("%.lua$", "") .. ".err.lua"
    content, data = obfuscate_code(content)
    if not content then
        return
    elseif content == 0 then
        io.open(error_path, "w"):write(data):close()
        print("⚠️ Encryption Failed")
        print("📁 The file has been saved on: " .. error_path)
        print("📎 Please check again and correct any errors.")
        return
    end
    
    -- Calculate and format the output file size
    local size = #content
    if size < 1024 then
        size = size .. " B"
    elseif size > 1024 and size < 1024 ^ 2 then
        size = size / 1024
        size = string.format("%.2f Kb", size)
    elseif size > 1024 ^ 2 and size < 1024 ^ 3 then
        size = size / (1024 ^ 2)
        size = string.format("%.2f Mb", size)
    end
    
    -- Write the obfuscated code to the output file
    io.open(output_path, "w"):write(content):close()
    print("🎉 Encryption successful")
    print("📁 The file has been saved on: " .. output_path)
    print("📄 Size: " .. size)
end