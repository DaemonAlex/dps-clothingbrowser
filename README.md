# dps-clothingbrowser

Admin tool for FiveM servers to visually browse, identify, and export clothing/uniform configurations. Built for servers with multiple DLC clothing packs where identifying specific drawable IDs is difficult.

## Features

- **Component Browser** - Cycle through all clothing drawables (tops, pants, shoes, vests, masks, etc.) with real-time preview on your character
- **Prop Browser** - Cycle through hats, glasses, ears, watches, bracelets
- **Outfit Builder** - Save individual pieces as you browse, then export them all as a complete outfit
- **Snapshot Export** - Capture your entire current appearance in one click
- **Jump to Drawable** - Go directly to a specific component + drawable ID
- **Restore Original** - Revert all appearance changes made during the session
- **Database Export** - Every export is written to the `dps_outfits` MySQL table (via oxmysql). Male and female exports of the same outfit name auto-merge onto a single row (`male_data` / `female_data` columns), ready to query later.

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib) (input dialogs, notifications, server callbacks)
- [oxmysql](https://github.com/overextended/oxmysql) (database export storage — the `dps_outfits` table is created automatically on first start)

## Installation

1. Drop `dps-clothingbrowser` into your resources folder
2. Add `ensure dps-clothingbrowser` to server.cfg (or place in a bracket folder that auto-loads)
3. Restrict access via ACE permissions. **This is required** — the `/cb` and `/clothingbrowser` commands are registered as restricted, and the server independently verifies `group.admin` before opening the UI or writing any export to the database:
   ```
   add_ace group.admin command.cb allow
   add_ace group.admin command.clothingbrowser allow
   ```
   Without these ACEs, non-admins cannot open the browser or write to `dps_outfits`.

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `/cb` | Open the clothing browser |
| `/clothingbrowser` | Alias for `/cb` |

### Browse Mode Controls

| Key | Action |
|-----|--------|
| Left / Right Arrow | Previous / next drawable |
| SHIFT + Left / Right | Skip 10 drawables |
| Up / Down Arrow | Previous / next texture |
| E | Save current piece to outfit builder |
| Escape | Close the browser |

### Workflow

1. `/cb` → **Browse Components** → select a slot (e.g. Tops)
2. Use arrow keys to cycle through drawables - your character updates in real-time
3. Press **E** to save pieces you want to keep
4. Repeat for other slots (pants, hats, armor, etc.)
5. Open **Outfit Builder** → **Export Saved Pieces**
6. Enter outfit label, job name, and grades
7. The outfit is written to the `dps_outfits` MySQL table (set `Config.Debug = true` to also dump the raw JSON to the F8/server console)

### Export Format

Exports are compatible with qs-appearance job outfits:

```json
{
  "label": "LSPD Patrol Uniform",
  "model": "mp_m_freemode_01",
  "job": "police",
  "grades": [0, 1, 2, 3],
  "components": [
    {"component_id": 3, "drawable": 15, "texture": 0},
    {"component_id": 4, "drawable": 35, "texture": 2},
    {"component_id": 8, "drawable": 58, "texture": 0},
    {"component_id": 11, "drawable": 55, "texture": 1}
  ],
  "props": [
    {"prop_id": 0, "drawable": 120, "texture": 0}
  ]
}
```

### Component Reference

| ID | Slot | ID | Slot |
|----|------|----|------|
| 0 | Face | 6 | Shoes |
| 1 | Mask | 7 | Accessories |
| 2 | Hair | 8 | Undershirt |
| 3 | Arms/Torso | 9 | Body Armor |
| 4 | Pants | 10 | Decals/Badge |
| 5 | Bag | 11 | Tops |

**Props:** 0 = Hats, 1 = Glasses, 2 = Ears, 6 = Watches, 7 = Bracelets

## Tips

- DLC clothing items are at the **high end** of each component's drawable range (vanilla items are at low indices)
- Use **SHIFT + Arrow** to quickly skip through vanilla items and reach your DLC packs
- Use **Jump to Drawable** if you already know an approximate range from your clothing catalog
- The **Snapshot Current Look** option captures everything at once - useful when you've manually dressed up using qs-appearance and want to save the result
