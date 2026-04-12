-- ============================================
-- PROJECTILE SPAWN TEST - PICO-8
-- ============================================

#include configs/game_config.lua
#include configs/gameplay_config.lua
#include levels/levels_data.lua
#include entities/pattern.lua
#include entities/projectile.lua
#include utility/hex_utils.lua

SCALE_MS = 10

function _init()
    game_time_ms = 0
    current_level = 1
    
    -- Load and decode level
    load_level(current_level)
    
    -- Projectile system
    active_projectiles = {}
    next_spawn_idx = 1
    
    -- Debug
    spawned_count = 0
end

function _update()
    game_time_ms += 16.67
    
    -- Spawn new projectiles based on timing
    spawn_projectiles()
    
    -- Update active projectiles
    update_projectiles()
end

function _draw()
    cls(0)
    
    -- Draw time
    printh("time: "..(game_time_ms/1000).."s", 2, 2, 7)
    printh("spawned: "..spawned_count, 2, 10, 7)
    printh("active: "..#active_projectiles, 2, 18, 7)
    
    -- Draw active projectiles
    draw_projectiles()
    
    -- Draw level info
    printh("level: "..current_level, 2, 110, 7)
end

-- ============================================
-- LEVEL LOADING
-- ============================================

function load_level(level_id)
    level_data = LEVEL_DATA[level_id]
    
    if not level_data then
        printh("ERROR: Level "..level_id.." not found!")
        return
    end
    
    -- Decode patterns
    patterns = decode_patterns(level_data.patterns)
    
    -- Decode projectiles
    projectiles_to_spawn = decode_projectiles(level_data.projectiles, patterns)
    
    printh("Level loaded with "..#projectiles_to_spawn.." projectiles")
end

-- ============================================
-- UTILITY
-- ============================================

function add(t, item)
    t[#t + 1] = item
end

function del(t, item)
    for i = #t, 1, -1 do
        if t[i] == item then
            table.remove(t, i)
            break
        end
    end
end