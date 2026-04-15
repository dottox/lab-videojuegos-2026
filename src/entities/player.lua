function create_player(x, y, health)
    log("player", "created x"..x.." y"..y.." h"..health, "info")
    return {
        x = x or 0,
        y = y or 0,
        health = health or 100,
        
        move = function(self, dx, dy)
            self.x += dx
            self.y += dy
        end,
        
        take_damage = function(self, amount)
            self.health -= amount
        end
    }
end

function draw_player()
    spr(14, player.x, player.y)
end

function move_player()
    if (btn(⬆️)) then
        player.y -= 1
    end
    if (btn(⬇️)) then
        player.y += 1
    end
    if (btn(➡️)) then
        player.x += 1
    end
    if (btn(⬅️)) then
        player.x -= 1
    end
end