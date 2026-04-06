.PHONY: setup build watch

setup:
	@PYTHON_BIN=$$(command -v python3 || command -v python); \
	if [ -z "$$PYTHON_BIN" ]; then \
		echo "Error: Python is not installed."; exit 1; \
	fi; \
	$$PYTHON_BIN -m venv .venv; \
	. .venv/bin/activate; \
	pip install shrinko; \
	sudo apt install entr -y

build:
	rm build/game.p8
	shrinko8 src/main.lua --merge assets/assets.p8 gfx,map,gff,sfx,music -f p8 build/game.p8

watch:
	@echo "Watching src/ and assets/ for changes..."
	@find src/ assets/ -type f | entr make build