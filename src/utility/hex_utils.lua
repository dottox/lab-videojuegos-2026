function hex_to_decimal(hex_str, is_signed)
    local result = 0
    for i = 1, #hex_str do
        local char = sub(hex_str, i, i)
        local digit = 0
        
        if char >= "0" and char <= "9" then
            digit = ord(char) - ord("0")
        elseif char >= "a" and char <= "f" then
            digit = ord(char) - ord("a") + 10
        elseif char >= "A" and char <= "F" then
            digit = ord(char) - ord("A") + 10
        end
        
        result = result * 16 + digit
    end
    
    -- Convert to signed if needed (for 1-byte values)
    if is_signed and result > 127 then
        result = result - 256
    end
    
    return result
end