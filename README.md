# GazeSwitch

Switch your cursor between monitors by looking at them.

GazeSwitch is a macOS menu bar app that uses your webcam to track eye gaze and automatically moves the mouse cursor to the monitor you're looking at.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Eye + head tracking** — uses both pupils and head yaw for accurate gaze estimation
- **5-point calibration** — calibrates center and four corners per monitor
- **Multi-monitor support** — works with any number of connected displays
- **Dwell timer** — configurable delay prevents accidental switches (default 300ms)
- **Hysteresis cooldown** — prevents rapid flickering when looking near monitor boundaries
- **Global hotkey** — toggle tracking with Cmd+Shift+E
- **Menu bar app** — lives in your menu bar, no Dock icon

## Requirements

- macOS 14 (Sonoma) or later
- A webcam (built-in or external)
- 2 or more monitors

## Install

### Homebrew (coming soon)

```bash
brew tap vetlehf/tap
brew install --cask gazeswitch
```

### Build from source

```bash
git clone https://github.com/vetlehf/gazeswitch.git
cd gazeswitch
make bundle
make install
```

## Usage

1. Launch GazeSwitch — it appears in your menu bar as an eye icon
2. Click the menu bar icon and select **Calibrate...**
3. Follow the 5-point calibration for each monitor (look at the indicated position and press Space)
4. Press **Cmd+Shift+E** or click **Start Tracking** to begin
5. Look at a monitor — your cursor follows your gaze

## Permissions

GazeSwitch needs two permissions:

- **Camera** — to track your eyes via the webcam
- **Accessibility** — to move the mouse cursor between monitors

You'll be prompted on first launch. You can also grant these in **System Settings > Privacy & Security**.

## Settings

- **Camera selection** — choose which webcam to use
- **Dwell time** — how long you need to look at a monitor before the cursor moves (100ms–1000ms)
- **Launch at login** — start GazeSwitch automatically

## Support

If you find GazeSwitch useful, consider supporting development:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/vetfin)

## License

[MIT](LICENSE) — Vetle H. Fiskaa
