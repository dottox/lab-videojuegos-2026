-- unpack projectiles from raw_data
-- with this method (compressed projectile), we reduce Pico8 token usage

function load_projectiles(str)
  local list = {}
  
  -- Loop through string 8 characters at a time
  for i=1, #str, 8 do
    local p = sub(str, i, i+7)
    
    -- tonum(str, 1) converts hex string to number in PICO-8
    add(list, {
      ts = tonum("0x"..sub(p, 1, 1)),
      x = tonum("0x"..sub(p, 2, 3)),
      y = tonum("0x"..sub(p, 4, 5)),
      v = tonum("0x"..sub(p, 6, 6)),
      b = tonum("0x"..sub(p, 7, 7)),
      w = tonum("0x"..sub(p, 8, 8))
    })
  end
  return list
end