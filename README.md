# lab-videojuegos-2026
Laboratorio de Videojuegos 2026

## Como desarrollar

Clona el repositorio y muevete a la root del proyecto.

1. **Usa `make setup` para instalar las dependecias.**
2. **Usa `make run` para correr Pico8** (debes añadirlo al PATH)
3. **Usa `make watch` para iniciar el hot-reload.** Cada vez que hagas un cambio en `src/` o `assets/` se va a crear la nueva build.
4. Cada vez que se cree una nueva build. **Usa `Control+R` dentro de Pico8 para obtener los nuevos cambios.**

---------------------

## Estructura de carpetas

**Esta es una estructura de ejemplo.** Los archivos dentro de src/ pueden variar.

```text
proyecto/
├── src/
│   ├── main.lua          # Punto de entrada (realiza los includes/imports)
│   ├── server.lua        # Lógica de servidores
│   ├── traffic.lua       # Lógica de tráfico
│   ├── input.lua         # Controles de usuario
│   ├── ui.lua            # Interfaz de usuario (HUD, menús)
│   └── utils.lua         # Funciones auxiliares y helpers
├── assets/
│   └── assets.p8         # Cartucho base con Sprites, Mapas y Sonidos
├── build/                # Binarios y cartuchos generados
│   └── game.p8           # Resultado final compilado
├── Makefile              # Automatización de build y watch
└── .gitignore            # Archivos ignorados (ej: .venv)
```