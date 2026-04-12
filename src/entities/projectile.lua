-- unpack projectiles from raw_data
-- with this method (compressed projectile), we reduce Pico8 token usage
function decode_projectiles(hex_string, patterns)
    local projectiles = {}
    
    -- 10 chars per projectile spawn (TS(4) + PATTERN_ID(2) + X(2) + Y(2))
    for i = 1, #hex_string, 10 do
        if i + 9 > #hex_string then break end

        local spawn_ts = hex_to_decimal(sub(hex_string, i, i+3))
        local pattern_id = hex_to_decimal(sub(hex_string, i+4, i+5))
        local spawn_x = hex_to_decimal(sub(hex_string, i+6, i+7), true)
        local spawn_y = hex_to_decimal(sub(hex_string, i+8, i+9), true)
        
        local spawn_ts_ms = spawn_ts * GAMEPLAY_CONFIG.SCALE_MS
        
        local pattern = patterns[pattern_id]
        if pattern then
            for _, proj in ipairs(pattern) do
                projectiles[#projectiles + 1] = {
                    ts_ms = spawn_ts_ms + proj.ts_ms,
                    x = proj.x + spawn_x,
                    y = proj.y + spawn_y,
                    velx = proj.velx,
                    vely = proj.vely,
                    type = proj.type
                }
            end
        end
    end
    
    return projectiles
end



function spawn_projectiles()
    while next_spawn_idx <= #projectiles_to_spawn do
        local proj = projectiles_to_spawn[next_spawn_idx]
        
        if proj.ts_ms <= game_time_ms then
            add(active_projectiles, {
                x = proj.x,
                y = proj.y,
                velx = proj.velx,
                vely = proj.vely,
                type = proj.type,
                spawn_time = game_time_ms,
                hit_time = proj.ts_ms
            })
            
            spawned_count += 1
            printh("SPAWNED: ts="..proj.ts_ms.."ms x="..proj.x.." y="..proj.y.." type="..proj.type)
            
            next_spawn_idx += 1
        else
            break
        end
    end
end

function update_projectiles()
    for i = #active_projectiles, 1, -1 do
        local p = active_projectiles[i]
        
        -- Move projectile
        p.x += p.velx * 0.5
        p.y += p.vely * 0.5
        
        -- Remove if off screen
        if p.x < 0 or p.x > 128 or p.y < 0 or p.y > 128 then
            del(active_projectiles, i)
        end
    end
end

function draw_projectiles()
    for _, p in ipairs(active_projectiles) do
        local col = 7
        if p.type == 0 then col = 8
        elseif p.type == 1 then col = 11
        elseif p.type == 2 then col = 10
        end
        
        circfill(p.x, p.y, 3, col)
    end
end