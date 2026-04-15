function decode_patterns(hex_string)
    local patterns = {}
    local pattern_count = tonum(sub(hex_string, 1, 2), 16)
    local pos = 3
    
    if pattern_count == nil then 
        log("pattern","no patterns found","warn")
        return
    end
    
    for p = 1, pattern_count do
        if pos + 1 > #hex_string then break end

        local projectile_count = hex_to_decimal(sub(hex_string, pos, pos+1))
        pos += 2
        
        patterns[p - 1] = {}
        
        for pr = 1, projectile_count do
            if pos + 8 > #hex_string then break end

            local ts = hex_to_decimal(sub(hex_string, pos, pos+1))
            local x = hex_to_decimal(sub(hex_string, pos+2, pos+3), true)
            local y = hex_to_decimal(sub(hex_string, pos+4, pos+5), true)
            local velx = hex_to_decimal(sub(hex_string, pos+6, pos+6))
            local vely = hex_to_decimal(sub(hex_string, pos+7, pos+7))
            local ptype = hex_to_decimal(sub(hex_string, pos+8, pos+8))
            pos += 9
            
            patterns[p - 1][pr] = {
                ts_ms = ts * GAMEPLAY_CONFIG.SCALE_MS,
                x = x,
                y = y,
                velx = velx,
                vely = vely,
                type = ptype
            }
        end
    end
    
    return patterns
end