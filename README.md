# RPG Attempt

A small original 2.5D RPG prototype inspired by the technical presentation of Nintendo DS-era RPGs. Built with **Godot 4.4.1** and **GDScript**.

## Prototype 001
- 3D tile-like outdoor map, two houses, trees and paths
- Procedurally generated pixel-style player sprite
- Fixed angled orthographic camera following the player
- Touch-drag movement on the left side of the screen
- WASD / arrow keys for desktop testing
- Simple obstacle collision and camera smoothing

## Android builds
GitHub Actions runs on pushes to `main`. Open **Actions → Android Debug APK → latest successful run → Artifacts** to download the zipped APK, extract it, and install it on Android. You may need to allow installation from your browser/file manager.

The workflow currently targets arm64 Android devices. It uses Godot's built-in Android exporter, not a web wrapper.

## Next
Replace prototype graphics with original polished pixel-art assets, add interaction, interiors, animation directions, map transitions, and persistent saves.

No Pokémon assets are included.
