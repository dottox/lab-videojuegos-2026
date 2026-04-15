-- load level (pattern + projectile) from levels_data.lua
function load_level(level_id)
    level_data = LEVEL_DATA[level_id]
    
    if not level_data then
        log("level", "id "..level_id.." not found!", 8)
        return
    end
    
    -- Decode patterns
    patterns = decode_patterns(level_data.patterns)
    
    -- Decode projectiles
    projectiles_to_spawn = decode_projectiles(level_data.projectiles, patterns)
    
    log("level", "loaded lvl"..level_id..", "..#projectiles_to_spawn.." projs.","info")
end