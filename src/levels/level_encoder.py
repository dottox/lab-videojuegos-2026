import yaml
import os

INPUT_YAML = "src/levels/levels_data.yaml"
OUTPUT_LUA = "src/levels/levels_data.lua"

def encode_patterns(patterns, scale_ms=10):
    """
    Encode pattern library with relative timestamps.
    Format per projectile: TS(2) | X(2) | Y(2) | VX(1) | VY(1) | TYPE(1) = 9 chars
    
    Patterns string: 
    pattern_count(1) | 
    [pattern1_size(1) | pattern1_projectile1(8) | pattern1_projectile2(8)... ] |
    [pattern2_size(1) | pattern2_projectile1(8) | ...] |
    ...
    """
    patterns_hex = f"{len(patterns):02x}"  # How many patterns
    
    for pattern in patterns:
        projectiles = pattern['projectiles']
        patterns_hex += f"{len(projectiles):02x}"  # How many projectiles in this pattern
        
        for p in projectiles:
            ts_scaled = int(p['ts'] / scale_ms) & 0xFF  # Relative timestamp in pattern
            x = p['x'] & 0xFF
            y = p['y'] & 0xFF
            velx = p['velX'] & 0xF
            vely = p['velY'] & 0xF
            ptype = p['type'] & 0xF
            
            h = f"{ts_scaled:02x}{x:02x}{y:02x}{velx:1x}{vely:1x}{ptype:1x}"
            patterns_hex += h
    
    return patterns_hex


def encode_projectiles(p_list, scale_ms=10):
    """
    Encode projectile spawns (references to patterns).
    Format: TS(4) | PATTERN_ID(2) | X(2) | Y(2) = 10 chars per projectile spawn
    
    TS is 2 bytes (0-65,535 ms, covers up to ~10 minutes per level)
    """
    encoded = ""
    for p in p_list:
        ts_scaled = int(p['ts'] / scale_ms) & 0xFFFF
        pattern_id = p.get('pattern_id', 0) & 0xFF
        x = p['x'] & 0xFF
        y = p['y'] & 0xFF
        
        h = f"{ts_scaled:04x}{pattern_id:02x}{x:02x}{y:02x}"
        encoded += h
    
    return encoded


def build_lua():
    if not os.path.exists(INPUT_YAML):
        print(f"Error: {INPUT_YAML} not found.")
        return

    with open(INPUT_YAML, 'r') as f:
        source = yaml.safe_load(f)

    lua_output = "-- levels_data.lua\nLEVEL_DATA = {\n"
    
    for lvl in source['levels']:
        if 'patterns' in lvl:
            patterns_hex = encode_patterns(lvl['patterns'])
        else:
            patterns_hex = ""
        
        if 'projectiles'in lvl:
            projectiles_hex = encode_projectiles(lvl['projectiles'])
        else:
            projectiles_hex = ""

        lua_output += f"  [{lvl['level_id']}] = {{\n"
        lua_output += f"    boss_sprite = {lvl['boss_sprite']},\n"
        lua_output += f"    music_id = {lvl['music_id']},\n"
        lua_output += f"    bpm = {lvl['bpm']},\n"
        lua_output += f"    patterns = \"{patterns_hex}\",\n"
        lua_output += f"    projectiles = \"{projectiles_hex}\"\n"
        lua_output += "  },\n"
            
    lua_output += "}"
    
    with open(OUTPUT_LUA, "w") as f:
        f.write(lua_output)
    
    print(f"Successfully compiled {len(source['levels'])} levels to {OUTPUT_LUA}")
if __name__ == "__main__":
    build_lua()