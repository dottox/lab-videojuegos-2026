-- ============================================
-- PROJECTILE SPAWN TEST - PICO-8
-- ============================================

#include configs/game_config.lua
#include configs/gameplay_config.lua
#include levels/level.lua
#include levels/levels_data.lua
#include entities/pattern.lua
#include entities/projectile.lua
#include entities/player.lua
#include utility/hex_utils.lua
#include utility/logger.lua

SCALE_MS = 10

function _init()
    current_level = 1
    
    -- Load and decode level
    load_level(current_level)
    
    -- Projectile system
    active_projectiles = {}
    player = create_player(64, 64, 100)
    next_spawn_idx = 1
    
    -- Debug
    spawned_count = 0
end

function _update()
    -- Spawn new projectiles based on timing
    spawn_projectiles()
    
    -- Update active projectiles
    update_projectiles()
end

function _draw()
    cls(0)
    
    -- Draw active projectiles
    draw_projectiles()

    draw_player()

    move_player()

    draw_logger_hud()
    
    -- Draw level info
end

-- ============================================
-- LEVEL LOADING
-- ============================================

