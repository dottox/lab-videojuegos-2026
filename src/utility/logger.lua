-- configuration
HUD_HEIGHT = 40
LOG_LIMIT = 4
logs = {}

-- updated log function
function log(title, message, clr)
    if not GAME_CONFIG.DEBUG then return end
    
    if clr == "err" then clr = GAME_CONFIG.DEBUG_COLORS.ERROR
    elseif clr == "warn" then clr = GAME_CONFIG.DEBUG_COLORS.WARN
    elseif clr == "info" then clr = GAME_CONFIG.DEBUG_COLORS.INFO
    else clr = GAME_CONFIG.DEBUG_COLORS.DEFAULT end

    -- add new log to the end
    add(logs, {
        title = "["..title.."]",
        msg = message,
        clr = clr
    })
    
    -- keep only the last LOG_LIMIT
    if (#logs > LOG_LIMIT) del(logs, logs[1])
    
    -- also print to system console for backup
    printh("["..title.."] "..message)
end

function draw_logger_hud()
    if not GAME_CONFIG.DEBUG then return end
    
    -- 1. draw background (semi-transparent black)
    rectfill(0, 0, 127, HUD_HEIGHT, 0)
    fillp(0xa5a5.5) -- checkerboard transparency
    rectfill(0, 0, 127, HUD_HEIGHT, 0)
    fillp() -- reset transparency
    
    -- 2. player & projectiles section
    line(0, HUD_HEIGHT, 127, HUD_HEIGHT, 6) -- bottom border
    
    -- stats
    print("♥"..player.health, 2, 2, 11)
    print("★"..#active_projectiles, 25, 2, 12)
    print("⧗"..flr(time()), 45, 2, 12)
    print("♪"..current_level, 68, 2, 12)
    
    -- 3. input buttons (visualizer)
    local bx = 90
    local by = 0
    draw_btn(0, bx, by+5)     -- left
    draw_btn(1, bx+10, by+5)  -- right
    draw_btn(2, bx+5, by)     -- up
    draw_btn(3, bx+5, by+5)  -- down
    draw_btn(4, bx+18, by+5)  -- z
    draw_btn(5, bx+28, by+5)  -- x
    
    -- 4. terminal section (last 5 logs)
    local ty = 15
    for i=1, #logs do
        local l = logs[i]
        local curr_y = ty + ((i-1) * 6)
        print(l.title, 2, curr_y, l.clr)
        print(l.msg, 6 + (#l.title * 4), curr_y, 7)
    end
end

-- helper to draw buttons
function draw_btn(i, x, y)
    local is_pressed = btn(i)
    local c = is_pressed and 7 or 5
    -- if not pressed, use fillp for semi-transparency
    if (not is_pressed) fillp(0xa5a5.5)
    rectfill(x, y, x+3, y+3, c)
    fillp()
end