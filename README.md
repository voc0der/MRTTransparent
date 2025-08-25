# MRT Transparent CD

A micro‑addon for **Method Raid Tools (MRT)** that makes the **Raid cooldowns** window clean and minimalist:

* Hides the title label ("Raid cooldowns")
* Fades the parent frame’s background/borders to a configurable alpha (true transparency possible)
* Leaves the cooldown bars/icons fully intact
* Auto‑reapplies when MRT rebuilds its window

Works on **WoW Classic Era 1.15.7** (and generally Retail as well). Requires **MRT** to be installed and enabled.

---

## Why?

MRT’s Raid cooldowns panel is super useful, but the title bar and solid background can clash with lightweight UIs. This addon non‑destructively “skins” only the outer frame, so you get icon/bars with no chrome.

---

## Features

* **True transparency**: `/mrtcd alpha 0` for invisible background (or any 0.0–1.0 value)
* **Hide the title**: `/mrtcd title off` (default hidden)
* **Localization‑friendly**: Target the window by its visible title text via `/mrtcd match <text>`
* **Resilient**: Reapplies on login/zone swaps/raid changes/MRT UI rebuilds
* **Safe & lightweight**: Uses guarded API calls and does not taint protected code

---

## Installation

1. **Dependency**: Install/enable **Method Raid Tools (MRT)**.
2. **AddOn folder**:

   * Classic Era: `World of Warcraft/_classic_era_/Interface/AddOns/MRTTransparentCD/`
   * Retail: `World of Warcraft/_retail_/Interface/AddOns/MRTTransparentCD/`
3. Place the two files inside that folder:

   * `MRTTransparentCD.toc`
   * `MRTTransparentCD.lua`
4. Restart the client or type `/reload` in-game.

> If you’re packaging for friends/guild: keep the folder name **exactly** `MRTTransparentCD`.

---

## Usage

All controls are via a single slash command:

```
/mrtcd alpha <0–1>     # Set background alpha (0.00 fully transparent)
/mrtcd title on|off    # Show/hide the "Raid cooldowns" label (default: off)
/mrtcd match <text>    # Case‑insensitive substring of the panel’s title to match
/mrtcd debug on|off    # Prints which frame was skinned (for troubleshooting)
```

**Examples**

* Make it fully invisible: ` /mrtcd alpha 0`
* Subtle glass look: ` /mrtcd alpha 0.15`
* Show the title again: ` /mrtcd title on`
* Non‑English client (e.g., just match the word “cooldown”): ` /mrtcd match cooldown`

---

## How it works (tech notes)

* Enumerates top‑level frames and looks for a **FontString** whose text matches `match` (default: `raid cooldowns`).
* Hides that title string (optional) and fades only the **parent frame’s own textures** (borders/background). Bars/icons are children and left untouched.
* Uses guarded (`pcall`) calls for `GetRegions`, `GetObjectType`, `GetText`, `SetAlpha`, etc., to avoid rare "bad self" issues when the UI is mid‑build.
* Reapplies on common UI events and every 2 seconds via a light ticker, in case MRT rebuilds the window.

---

## Troubleshooting

**The panel isn’t changing**

* The visible title might differ (localization or MRT update). Run `/mrtcd debug on` and then try `/mrtcd match <a unique word you see on the title>`. Example: `/mrtcd match cooldown`.

**I saw an error about `GetObjectType` or `GetRegions`**

* Update to the latest version. Current release guards every API call to squash these edge cases.

**Flicker or reappearing border**

* That’s usually another skin (ElvUI/Plater/Masque) drawing overlays. This addon only fades the parent frame’s *own* regions. If an overlay texture is injected by a skin, consider skin‑side options or a small rule there.

**Performance**

* The scan is cheap and the ticker is light (every 2s). If you want to change the cadence, you can edit the ticker value near the end of `MRTTransparentCD.lua`.

---

## Compatibility

* **WoW Classic Era 1.15.7** (developed & tested here)
* **Retail** should work (same APIs). If the title differs, set a matching substring via `/mrtcd match`.
* **Dependencies**: MRT v5210+ recommended.

---

## Changelog

* **v1.3** – Hardened scanning (no vararg misuse), full `pcall` guards for stability outside raids/login.
* **v1.2** – Added safety wrappers and forbidden‑frame checks.
* **v1.1** – Initial stable release with slash commands (`alpha`, `title`, `match`, `debug`).
* **v1.0** – First working prototype.

---

## License

MIT. Do whatever you like; keep attribution if you redistribute.

---

## Credits

* Built by vocoder + GPT, for folks who love MRT but prefer minimalist UI chrome.

---

## Appendix: One‑off test macro (optional)

If you want to preview the effect without installing, run this once (change the search string if needed):

```
/run s="raid cooldowns";f=EnumerateFrames()while f do if f.GetRegions then R={f:GetRegions()}for i=1,#R do x=R[i];if x and x.GetText and x:GetObjectType()=="FontString"and(x:GetText()or""):lower():find(s,1,true)then x:Hide()for j=1,#R do y=R[j];if y and y.GetObjectType and y:GetObjectType()=="Texture"then y:SetAlpha(0)end end end end end f=EnumerateFrames(f)end
```

If your client shows a different title, change `s="..."` to any unique part of the label.
