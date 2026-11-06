# Grudge Ledger

A weathered, medieval **blacklist** for World of Warcraft — keep a parchment ledger of players who've wronged you, and get warned the moment one of them crosses your path.

Built for **WoW Forever (1.60.1)** and Classic Era (1.15.x).

![Interface](https://img.shields.io/badge/Interface-16001%20%7C%2011509-c9a24b) ![Classic](https://img.shields.io/badge/WoW-Forever%201.60.1-8a2a26)

---

## What it does

- **A medieval parchment ledger** — aged paper, ornate gold frame, ink calligraphy. Record a player with a reason and the date.
- **Warns you automatically** when a blacklisted player:
  - **whispers you** — their message is tagged inline in chat: `[GRUDGE: reason] ...`
  - **targets / mouseovers** them, or they **join your group/raid**
  - **comes near you in the world** — a small parchment pop-up appears bottom-right
- **On-screen banner + sound** when an enemy is detected (15s per-person cooldown so it never spams).
- **Account-wide** — your ledger is shared across all your characters.
- **Two-name aware** — fully supports Forever's "First Last" name system.

---

## Install

1. Download and unzip.
2. Copy the `GrudgeLedger` folder into:
   `World of Warcraft\_forever_\Interface\AddOns\`
3. Restart WoW (or go to character-select) and enable **Grudge Ledger** in the AddOns list.

> The folder must be named `GrudgeLedger` and contain `GrudgeLedger.toc` directly inside it.

---

## Commands

| Command | What it does |
|---|---|
| `/gl` | Open / close the ledger |
| `/gl add <name> <reason>` | Add a player (no name = your current target) |
| `/gl add "First Last" <reason>` | Two-part names need quotes |
| `/gl remove <name>` | Remove a player (full name) |
| `/gl clear` | Wipe the ledger (with confirmation) |
| `/gl sound` | Toggle the warning sound |
| `/gl prox` | Toggle the bottom-right "nearby" pop-up |
| `/gl scan` | Diagnostic: how many nameplates it can read |

You can also click **Target → Inscribe** in the window, or the red **X** on any entry to remove it.

---

## Notes

- **Proximity detection needs nameplates ON.** Press `V` for enemies, and enable *Friendly Players* nameplates in Interface → Names to catch same-faction players. It reads the nameplate frames directly (the vanilla-compatible method).
- **Two-name matching:** blacklisting a first name alone still catches the full name (e.g. `Grobnar` matches `Grobnar Ironfist`); blacklisting the full name matches exactly.
- All graphics use WoW's built-in textures and fonts — **no extra files to install**.

---

## License

MIT — see [LICENSE](LICENSE).
