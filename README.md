# Bozo List

A weathered, medieval **blacklist** for World of Warcraft — keep a parchment ledger of the bozos who've wronged you, and get warned the moment one of them crosses your path.

Built for **WoW Forever (1.60.1)** and Classic Era (1.15.x).

![Interface](https://img.shields.io/badge/Interface-16001%20%7C%2011509-c9a24b) ![Classic](https://img.shields.io/badge/WoW-Forever%201.60.1-8a2a26)

---

## What it does

- **A medieval parchment ledger** — aged paper, ornate gold frame, ink calligraphy. Record a bozo with a reason and the date.
- **Warns you automatically** when a listed bozo:
  - **whispers you** — their message is tagged inline in chat: `[BOZO: reason] ...`
  - **targets / mouseovers** them, or they **join your group/raid**
  - **comes near you in the world** — a small parchment pop-up appears bottom-right
- **On-screen banner + sound** when a bozo is detected (15s per-person cooldown so it never spams).
- **Account-wide** — your list is shared across all your characters.
- **Two-name aware** — fully supports Forever's "First Last" name system.

---

## Install

1. Download and unzip.
2. Copy the `BozoList` folder into:
   `World of Warcraft\_forever_\Interface\AddOns\`
3. Restart WoW (or go to character-select) and enable **Bozo List** in the AddOns list.

> The folder must be named `BozoList` and contain `BozoList.toc` directly inside it.

---

## Commands

| Command | What it does |
|---|---|
| `/bl` | Open / close the list |
| `/bl add <name> <reason>` | Add a bozo (no name = your current target) |
| `/bl add "First Last" <reason>` | Two-part names need quotes |
| `/bl remove <name>` | Remove a bozo (full name) |
| `/bl clear` | Wipe the list (with confirmation) |
| `/bl sound` | Toggle the warning sound |
| `/bl prox` | Toggle the bottom-right "nearby" pop-up |
| `/bl scan` | Diagnostic: how many nameplates it can read |

Also `/bozo` and `/blacklist` open the list. You can click **Target → Inscribe** in the window, or the red **X** on any entry to remove it.

---

## Notes

- **Proximity detection needs nameplates ON.** Press `V` for enemies, and enable *Friendly Players* nameplates in Interface → Names to catch same-faction bozos. It reads the nameplate frames directly (the vanilla-compatible method).
- **Two-name matching:** blacklisting a first name alone still catches the full name (e.g. `Grobnar` matches `Grobnar Ironfist`); blacklisting the full name matches exactly.
- All graphics use WoW's built-in textures and fonts — **no extra files to install**.

---

## License

MIT — see [LICENSE](LICENSE).
