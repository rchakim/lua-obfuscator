-- Creator: Arif Rahman
-- Copyright (c) 2025 Arif Rahman. All rights reserved.

-- Converts a string to a table of byte values, appends metadata, and returns a formatted string
-- @param inputStr The input string to convert to byte values
-- @param metadataKey A metadata key to append to the byte values
-- @param randomIdentifier A random identifier to append to the byte values
-- @return A string representation of a table containing byte values, metadataKey, and randomIdentifier
local function stringToBytesWithMetadata(inputStr, metadataKey, randomIdentifier)
	-- Check if the input string is empty; if so, return empty string quotes
	if inputStr == "" then
		return "''"
	end

	-- Convert the input string to a table of its byte values
	local byteValues = { inputStr:byte(1, -1) }
	-- Append the metadata key to the byte values table
	table.insert(byteValues, metadataKey)
	-- Append the random identifier to the byte values table
	table.insert(byteValues, randomIdentifier)

	-- Concatenate the table values with commas and wrap in curly braces
	return "{" .. table.concat(byteValues, ",") .. "}"
end

-- Return the function for external use
return stringToBytesWithMetadata