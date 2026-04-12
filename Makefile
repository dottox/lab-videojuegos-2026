.PHONY: setup build watch run gen_levels

gen_levels:
	@PYTHON_BIN=$$(command -v python3 || command -v python); \
	if [ -z "$$PYTHON_BIN" ]; then \
		echo "Error: Python is not installed."; exit 1; \
	fi; \
	$$PYTHON_BIN src/levels/level_encoder.py; \

setup:
	@PYTHON_BIN=$$(command -v python3 || command -v python); \
	if [ -z "$$PYTHON_BIN" ]; then \
		echo "Error: Python is not installed."; exit 1; \
	fi; \
	$$PYTHON_BIN -m venv .venv; \
	. .venv/bin/activate; \
	pip install shrinko; \
	sudo apt install entr -y; \
	echo "\n### EJECUTA 'source .venv/bin/activate' PARA UTILIZAR LOS DEMAS COMANDOS ###\n"
	echo "### ABRE UNA TERMINAL Y EJECUTA 'make run', Y EN OTRA TERMINAL 'make watch' ###\n" 

build:
	mkdir -p build
	rm -f build/game.p8
	shrinko8 src/main.lua --merge assets/assets.p8 gfx,map,gff,sfx,music -f p8 build/game.p8
	echo "\n### BUILD ACTUALIZADA: USA CONTROL+R EN PICO8 PARA VER LOS CAMBIOS ###\n"

run: build
	pico8 build/game.p8

watch:
	@echo "Watching src/ and assets/ for changes..."
	@find src/ assets/ -type f | entr make build