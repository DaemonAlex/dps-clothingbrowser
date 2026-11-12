# dps-clothingbrowser

Admin tool for FiveM servers to visually browse, identify, and export clothing/uniform configurations. Built for servers with multiple DLC clothing packs where identifying specific drawable IDs is difficult.

## Status

Not running on DelPerroSands. The code is complete and was imported from the live server on
18 August 2026. It was built when the server used qs-appearance. The server now runs
rcore_clothing, which has its own clothing catalogue, and nothing on the server reads the
`dps_outfits` table this tool writes.

## What it is for

A server with many clothing packs has thousands of numbered pieces and no names. Staff need to
find the right number for a uniform. This tool lets an admin flip through every piece on their
own character, keep the ones they want, and save the set as a named outfit for a job.

## On its own, and with other scripts

**On its own.** Needs `ox_lib` and `oxmysql`. An admin types `/cb`. A panel opens and the camera
moves to the body part being browsed. Arrow keys step through pieces and textures, and the
character changes as they go. `E` keeps a piece. The outfit builder saves the kept pieces to the
`dps_outfits` database table. Saving the same outfit name on a male and a female character fills
both halves of one row. Only players in `group.admin` can open it or save.

**With a paid clothing script (qs-appearance).** The exported JSON uses the same layout as
qs-appearance job outfits, so it can be pasted into that script's outfit config. This is a copy
and paste step. The tool does not call qs-appearance.

**With rcore_clothing.** No link. rcore_clothing does not read `dps_outfits` or this JSON
layout. The numbers found with `/cb` are still the real drawable and texture numbers, so they
can be typed into rcore_clothing by hand.

**With a paid ambulance or police script (wasabi).** The database rows store each piece in the
`component`, `drawable`, `texture` form that wasabi cloakrooms use. Nothing copies them across.
An admin has to move them into the wasabi config by hand.

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

## Recent changes

- **12 November 2026.** README: status, what it is for, how it works alone and with paid scripts, other DPS scripts.
- **18 August 2026.** First import from the live server (version 2.1.0). Line endings pinned in `.gitattributes`.

## Author

Made by [DaemonAlex](https://github.com/DaemonAlex) for DelPerroSands.

## Other DPS scripts

All of these are made for DelPerroSands and run together on one Qbox server. Each one works on
its own. The ones marked "pairs with" do more when both are running.

| Script | What it does |
|---|---|
| [dps-inventory](https://github.com/DaemonAlex/dps-inventory) | The inventory: ox_inventory with equipment slots, backpacks, armour plates and a self status panel, in the DelPerroSands colours. |
| [dps-medical](https://github.com/DaemonAlex/dps-medical) | Patient records, illness and diagnostic tests. A companion to wasabi_ambulance. Pairs with dps-inventory: symptoms and diagnoses show on the status panel. |
| [dps-insurance](https://github.com/DaemonAlex/dps-insurance) | Ties m-Insurance into the MDT, impound, hospital and medical chart. Pairs with dps-medical. |
| [dps-studio](https://github.com/DaemonAlex/dps-studio) | Build rooms, doors and portals in game from one panel (`/studio`), with owners and managers so staff do not have to support them. |
| [dps-shops](https://github.com/DaemonAlex/dps-shops) | Shop clerks who greet and react to a robbery, then player-owned shops. |
| [dps-fleet](https://github.com/DaemonAlex/dps-fleet) | Vehicle browser and workshop on one panel: extras, liveries and mods for emergency vehicles. |
| [dps-parking](https://github.com/DaemonAlex/dps-parking) | Parking with valet, impound, violations and reserved spots. |
| [dps-vehiclepersistence](https://github.com/DaemonAlex/dps-vehiclepersistence) | Vehicles stay where they were parked. Pairs with dps-parking. |
| [dps-towjob](https://github.com/DaemonAlex/dps-towjob) | Queue-based tow job with jg-mechanic integration. |
| [dps-services](https://github.com/DaemonAlex/dps-services) | Request a tow and follow it live on the lb-phone and lb-tablet. Pairs with dps-towjob. |
| [dps-autoshops](https://github.com/DaemonAlex/dps-autoshops) | Self-service repair shops when no mechanic is on duty. |
| [dps-cityworker](https://github.com/DaemonAlex/dps-cityworker) | City infrastructure job and career. |
| [dps-ainpcs](https://github.com/DaemonAlex/dps-ainpcs) | NPCs you can talk to, with trust, quests and intel. |
| [dps-badpeds](https://github.com/DaemonAlex/dps-badpeds) | Police interaction with NPCs: stops, arrests, intel and jail records. |
| [dps-gangwars](https://github.com/DaemonAlex/dps-gangwars) | Ambient gang NPCs, territory population and war reinforcements. |
| [dps-rotations](https://github.com/DaemonAlex/dps-rotations) | Moves dealers, harvests and other spots on a fixed schedule. |
| [dps-trains](https://github.com/DaemonAlex/dps-trains) | The train system. Pairs with dps-trains-stock, dps-traintools and dps-transitapp. |
| [dps-transitapp](https://github.com/DaemonAlex/dps-transitapp) | Live train arrival boards on the lb-phone. |
| [dps-faceplant](https://github.com/DaemonAlex/dps-faceplant) | City help, reports and staff tools on the lb-phone and lb-tablet. |
| [dps-chat](https://github.com/DaemonAlex/dps-chat) | A command box for voice-only servers. No chat feed. |
| [dps-filmmode](https://github.com/DaemonAlex/dps-filmmode) | One key hides every HUD layer and gives a smooth free camera for recording. |
