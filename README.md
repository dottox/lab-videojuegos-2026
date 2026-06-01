# lab-videojuegos-2026
Laboratorio de Videojuegos 2026

## Level Editor

Abre `scenes/editor/level_editor.tscn` en Godot y ejecútalo como escena. Desde ahí puedes cargar música, definir el playfield, crear zonas y proyectiles, y exportar/importar niveles en YAML. El YAML está pensado para este esquema simple (sin estructuras complejas, ni arrays con strings que contengan comas, ni strings multilínea).

## Exportación Web

### Requisitos

- Instalar las plantillas de exportación (Export Templates) de Godot.
- Utilizar el renderizador Compatibility en lugar de Forward+.

### Configuración

1. Abrir Editor → Manage Export Templates.
2. Instalar las plantillas oficiales que coincidan con la versión de Godot utilizada.

### Compilación

1. Abrir Project → Export.
2. Seleccionar HTML5.
3. Elegir la carpeta de destino.
4. Desactivar la opción Debug.
5. Exportar el proyecto.

### Notas

- Eliminar la compilación anterior antes de generar una nueva.
- Se necesita de levantar un server para correr el programa. (LiveServer de VsCode funciona perfectamente)