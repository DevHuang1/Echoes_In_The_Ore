# Echoes in the Ore — Web foundation

Minimal Godot 4.7 project setup for opening the project and checking the Web export path. This is only a boot screen; gameplay, rooms, characters, and input systems have not been started.

## Open in Godot

Use Godot **4.7.2 stable** for the shared project. Give your teammate the whole `Echoes_In_The_Ore` project folder (or a ZIP of it), including `project.godot`, `export_presets.cfg`, `scenes/`, `scripts/`, and `art/`. They can import `project.godot` from Godot's Project Manager, or open the project folder directly. The main scene is `scenes/boot.tscn`; press **F6** to run that scene or **F5** to run the project.

## Web target

- Renderer: Compatibility (Godot Web targets WebGL 2.0)
- Export preset: `Web`
- Thread support: disabled for the single-threaded browser export
- Export path: `build/web/index.html`

Exporting requires the matching Godot 4.7.2 Web export templates to be installed in the editor. The project files configure the target; they do not include the engine templates.

## Teammate setup: preview it in a browser

1. Install Godot **4.7.2 stable** and open/import this project.
2. In Godot, install the matching export templates using **Editor → Manage Export Templates → Download and Install**. The editor version and template version must match. The Web export preset is already in `export_presets.cfg`.
3. From the project folder, create the export directory if needed:

   ```sh
   mkdir -p build/web
   ```

4. Export in Godot using **Project → Export**, select **Web**, then export to `build/web/index.html`. Or, if the Godot command-line executable is on PATH, run this from the project folder:

   ```sh
   godot --headless --path . --export-release Web build/web/index.html
   ```

5. Serve the export over HTTP from the project folder. Keep this terminal running:

   ```sh
   python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
   ```

6. Open <http://127.0.0.1:8765/> in a browser.

The browser address above works on the teammate's own computer only. To share it with others, upload the entire contents of `build/web/` to an HTTPS web host; keep the generated HTML, JavaScript, WebAssembly, and PCK files together. The current project is only a startup screen, not the game campaign.
