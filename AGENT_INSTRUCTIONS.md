# INSTRUCCIONES PARA AGENTE HERMES: Proyecto Acuatics (Roblox + Rojo)

Actúa como desarrollador senior de Luau/Roblox colaborando en el repositorio Acuatics con Carlos (CariGhost).

## 1. Setup del Entorno y Repositorio
1. Clona el repositorio oficial:
   ```bash
   git clone git@github.com:CariGhost/Acuatics.git
   cd Acuatics
   ```
2. Instala Rojo (v7.x) si no está presente en el sistema (vía cargo, aftman o binario directo):
   ```bash
   rojo --version
   ```
3. Levanta el servidor de sincronización de Rojo para escuchar conexiones de Roblox Studio:
   ```bash
   rojo serve --address 0.0.0.0 --port 34872
   ```

## 2. Conexión en Roblox Studio
- Abre el archivo base `SubnauticaStages.rbxl` en Roblox Studio.
- En la pestaña **Plugins**, abre el plugin de **Rojo**.
- Conecta a la IP local y puerto de la máquina donde corre Rojo (`localhost:34872` o la IP de red local en el puerto `34872`).

## 3. Estructura y Reglas del Código
El proyecto mapea mediante `default.project.json`:
- `src/shared/` -> `ReplicatedStorage.Shared` (Configuraciones, constantes, tipos, tablas de biomas y minerales).
- `src/server/` -> `ServerScriptService` (Lógica authoritative: generación procedural de arrecifes/biomas, gestión de salud/oxígeno, inventario en servidor, spawn de items).
- `src/client/` -> `StarterPlayer.StarterPlayerScripts` (HUD de oxígeno reactivo, efectos visuales bajo el agua, atmósfera, inputs del jugador).

### Reglas de desarrollo:
- **Server Authoritative:** Nunca confíes en el cliente para inventario, vida ni oxígeno. El cliente solo renderiza UI y envía inputs mediante RemoteEvents/RemoteFunctions.
- **Sintaxis Luau:** Usa tipado estricto (`--!strict`), variables locales y Luau idioms.
- **Sin binarios pesados en git:** Solo edita y commitea código en `src/` y configuraciones JSON. No sobreescribas `SubnauticaStages.rbxl` a menos que sea un cambio estructural de mapa no sincronizable por Rojo.

## 4. Flujo de Trabajo y Colaboración (Git)
- Siempre crea ramas de funcionalidad para tus tareas:
  ```bash
  git checkout -b feature/nombre-de-la-mejora
  ```
- Haz commits atómicos y descriptivos:
  ```bash
  git commit -m "feat(crafting): add fabricator recipes in shared config"
  ```
- Antes de pushear a main, haz pull con rebase para evitar conflictos:
  ```bash
  git pull --rebase origin main
  ```
