-- PICO-8 Load Balancer MVP
function _init()
  servers = {
    {x=30, y=40, load=0, cap=50},
    {x=64, y=40, load=0, cap=60},
    {x=98, y=40, load=0, cap=50}
  }
  traffic = {}
  score = 0
  selected = 1
end

function _update()
  -- Controles
  if btnp(0) then selected = max(1, selected - 1) end
  if btnp(1) then selected = min(3, selected + 1) end
  
  -- Spawn trれくfico
  if rnd() < 0.02 then
    add(traffic, {x=64, y=10, size=rnd(20)+5})
  end
  
  -- Mover trれくfico
  for pkt in all(traffic) do
    pkt.y += 1
    
    -- Llegれは a servidor?
    if pkt.y > 35 then
      if servers[selected].load + pkt.size <= servers[selected].cap then
        servers[selected].load += pkt.size
        score += pkt.size
        del(traffic, pkt)
      else
        -- Game Over
        print("overflow!", 50, 64, 8)
      end
    end
  end
  
  -- Descargar servidores
  for srv in all(servers) do
    srv.load = max(0, srv.load - 0.3)
  end
end

function _draw()
  cls(0)
  
  -- Dibujar servidores
  for i=1,3 do
    local srv = servers[i]
    local col = 7
    if i == selected then col = 10 end
    if srv.load > srv.cap * 0.8 then col = 8 end
    
    circfill(srv.x, srv.y, 7, col)
    print(srv.load/10, srv.x-4, srv.y-3, 7)
  end
  
  -- Dibujar trれくfico
  for pkt in all(traffic) do
    circfill(pkt.x, pkt.y, 2, 9)
  end
  
  -- HUD
  print("score:"..score, 5, 5, 7)
  print("select:"..selected, 5, 120, 7)
end