import yaml
import os

INPUT_YAML = "src/levels/levels_data.yaml"
OUTPUT_LUA = "src/levels/levels_data.lua"

def encode_projectiles(p_list):
    """
    Encodes projectiles into an 8-character hex string:
    TS(2) | X(2) | Y(2) | velX(1) | velY(1) | type(1)
    Total: 9 chars (or 8 if we pack tightly). 
    Let's use 8 chars for efficiency:
    TS(1) X(2) Y(2) VX(1) VY(1) TY(1) = 8 chars
    """
    encoded = ""
    for p in p_list:
        # TS(1)  X(2)   Y(2)   VX(1)  VY(1)  TY(1)
        # Note: hex(15) is 'f', hex(255) is 'ff'
        try:
            h = f"{p['ts']:1x}{p['x']:02x}{p['y']:02x}{p['velX']:1x}{p['velY']:1x}{p['type']:1x}"
            encoded += h
        except ValueError as e:
            print(f"Value Error: Check if numbers are too large (X/Y > 255 or others > 15). {e}")
    return encoded

def build_lua():
    if not os.path.exists(INPUT_YAML):
        print(f"Error: {INPUT_YAML} not found.")
        return

    with open(INPUT_YAML, 'r') as f:
        source = yaml.safe_load(f)

    lua_output = "-- levels_data.lua\nLEVEL_DATA = {\n"
    
    for lvl in source['levels']:
        hex_string = encode_projectiles(lvl['projectiles'])
        
        lua_output += f"  [{lvl['level_id']}] = {{\n"
        lua_output += f"    boss_sprite = {lvl['boss_sprite']},\n"
        lua_output += f"    music_id = {lvl['music_id']},\n"
        lua_output += f"    bpm = {lvl['bpm']},\n"
        lua_output += f"    projectiles = \"{hex_string}\"\n"
        lua_output += "  },\n"
            
    lua_output += "}"
    
    with open(OUTPUT_LUA, "w") as f:
        f.write(lua_output)
    print(f"Successfully compiled {len(source['levels'])} levels to {OUTPUT_LUA}")

if __name__ == "__main__":
    build_lua()