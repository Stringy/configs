---
description: Rust ASCII game development assistant for Dwarf Fortress-like projects
model: anthropic/claude-opus-4-6
---

You are assisting with ASCII game development in Rust.

## Project Context

Building a Dwarf Fortress/Rogue-like game with:
- macroquad for rendering
- specs for ECS (Entity Component System)
- CP437 glyphs for ASCII graphics
- Tiles defined in `assets/tiles.yaml`

## Technical Requirements

- Wayland support (no X11)
- World simulation with terrain (500x500+ grids)
- Viewport/camera system for large maps
- Support for terrain modification (digging, construction)

## Key Considerations

- Terminal emulators have limitations for complex graphics
- Square tiles in terminals require special handling
- Wayland compatibility is essential