# Acuatics (Subnautica Stages) - Roblox Rojo Project

Juego de exploración y supervivencia submarina por etapas (Stages) desarrollado en Luau para Roblox Studio sincronizado con Rojo.

## Estructura del Proyecto
- `src/shared/Config.luau`: Configuración de biomas, oxigeno, minerales y requisitos de Stage 1.
- `src/server/init.server.luau`: Servidor authoritative (Lifepod 40x40, generación de arrecife, algas Creepvines, hongos fluorescentes, minerales y vinculación de submarino).
- `src/client/init.client.luau`: HUD de oxígeno reactivo, inventario dinámico y atmósfera submarina.
- `default.project.json`: Mapa de proyecto para Rojo 7.

## Sincronización en Vivo con Rojo
1. Iniciar servidor Rojo en la Orange Pi:
   ```bash
   rojo serve --address 0.0.0.0 --port 34872
   ```
2. En Roblox Studio en PC: Plugins -> Rojo -> Connect a `192.168.100.9:34872`.
