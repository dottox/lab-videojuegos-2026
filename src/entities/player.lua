function create_player(x, y, health)
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

