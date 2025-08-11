-- Creator: Arif Rahman
-- Copyright (c) 2025 Arif Rahman. All rights reserved.

-- Converts a string to its hexadecimal representation with an offset, appends metadata, and returns a formatted string
-- @param inputString The input string to convert to hexadecimal
-- @param metadataKey A metadata key to include in the output
-- @param identifier A random identifier to include in the output
-- @return A string representation of a table containing the hex string, metadataKey, and identifier
local function stringToHexWithMetadata(inputString, metadataKey, identifier)
    -- Return empty string quotes if the input string is empty
    if inputString == "" then
        return "''"
    end

    -- Convert each character to its hexadecimal value with an offset of 13, wrap in quotes
    local hexString = "'" .. inputString:gsub('.', function(char)
        return string.format('%02X', (string.byte(char) + 13) % 256)
    end) .. "'"

    -- Create a table with the hex string, metadata key, and identifier
    local resultTable = { hexString, metadataKey, identifier }

    -- Concatenate table elements with commas and wrap in curly braces
    return "{" .. table.concat(resultTable, ",") .. "}"
end

-- Return the function for external use
return stringToHexWithMetadata