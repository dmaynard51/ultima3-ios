# Ultima III on iOS

**Play Ultima III: Exodus on your iPhone or iPad** — the complete, original DOS game,
running in DOSBox, booting straight into the game with a gem icon.

It's built on [dospad](https://github.com/litchie/dospad) (the open-source iOS DOSBox,
GPLv2), cloned and patched at build time, plus **your own** copy of Ultima III.

> **You must own Ultima III.** It isn't free, so **no game data is included in this repo** —
> the build copies your own copy onto the device. The DOSBox app is cloned + patched at
> build time, not re-hosted here.

## 🚀 Install

Requires a **Mac** with **Xcode** and **git**.

```sh
git clone https://github.com/dmaynard51/ultima3-ios.git
cd ultima3-ios
dosbox/build-ios-dosbox.sh ABCDE12345          # your 10-char Apple Team ID
```

It clones the iOS DOSBox, patches it to auto-run Ultima III, brands it with the gem icon
and the name "Ultima III", builds, signs, installs, and copies your game data onto the
device. First run: **trust the app once** under **Settings ▸ General ▸ VPN & Device
Management**, then reopen — it boots straight into the game.

By default it reads your U3 data from `/Applications/Ultima III™.app/Contents/Resources/game`
(a Mac GOG install — the **[Ultima 1+2+3 bundle](https://www.gog.com/game/ultima_123)**). If
yours is elsewhere, pass the folder (the one with `ULTIMA.COM`) as the last argument.

(Find your Team ID: `security find-identity -v -p codesigning` — the code in parentheses.)

## 🎮 Playing

Ultima III is keyboard-driven. dospad gives you an **on-screen keyboard** and gamepad
overlay — tap the keyboard toggle to type commands. Hold the phone in **landscape**.

## ☕ Support this port

- ☕ **[Buy me a coffee (Ko-fi)](https://ko-fi.com/dmaynard)**
- 💜 **[GitHub Sponsors](https://github.com/sponsors/dmaynard51)**

## 🙏 Credits & license

- iOS DOSBox: **[dospad](https://github.com/litchie/dospad)** by litchie (GPLv2) —
  cloned + patched at build time.
- Gem app icon and the build script: MIT — see [LICENSE](LICENSE).
- *Ultima III* and its data are © Origin Systems / Electronic Arts. This project ships
  none of it; you bring your own legally-owned copy.
