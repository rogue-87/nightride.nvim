# nightride.nvim

A Neovim plugin for streaming music from [nightride.fm](https://nightride.fm) - the home of synthwave radio.

## Features

- 🎵 Stream from 7 different nightride.fm stations
- 🔊 Volume control from within Neovim
- 📊 Status line integration (not yet)
- ⌨️ Configurable keybindings
- 🎮 Support for mpv (recommended), ffplay, and VLC media players
- 🎚️ Seamless volume control via mpv IPC (no stream restart)
- 🌊 High-quality 320kbps AAC streams

## Available Stations

- **Nightride FM** - Synthwave / Retrowave / Outrun
- **ChillSynth FM** - Chillsynth / Chillwave / Instrumental
- **Datawave FM** - Glitchy Synthwave / IDM / Retro Computing
- **SpaceSynth FM** - Spacesynth / Space Disco / Vocoder Italo
- **DarkSynth** - Darksynth / Cyberpunk / Synthmetal
- **HorrorSynth** - Horrorsynth / Witch House
- **EBSM** - EBSM / Industrial / Clubbing

## Requirements

- Neovim 0.7.0 or later
- One of the following audio players (in order of preference):
  - `mpv` (recommended - enables seamless volume control via IPC)
  - `ffplay` (part of FFmpeg - volume changes restart stream)
  - `vlc` (VLC media player - volume changes restart stream)
- Internet connection for streaming

## Installation

### lazy.nvim

```lua
{
    "rogue-87/nightride.nvim",
    config = function()
        require("nightride").setup()
    end,
}
```

### packer.nvim

```lua
use({
    "rogue-87/nightride.nvim",
    config = function()
        require("nightride").setup()
    end,
})
```

### vim-plug

```vim
Plug "rogue-87/nightride.nvim"
```

Then add to your `init.lua`:

```lua
require("nightride").setup()
```

## Configuration

Default configuration:

```lua
require("nightride").setup({
    -- Audio player preference
    player = "auto", -- 'mpv', 'ffplay', 'vlc', 'auto'

    -- Default station
    default_station = "nightride",

    -- Volume settings
    default_volume = 50,
    volume_step = 5,

    -- Key mappings
    keymaps = {
        toggle = "<leader>np",
        volume_up = "<leader>n+",
        volume_down = "<leader>n-",
    },
})
```

## Usage

### Commands

- `:Nightride` - Show current status
- `:Nightride start [station]` - Start streaming (optional station)
- `:Nightride stop` - Stop streaming
- `:Nightride toggle` - Toggle playback
- `:Nightride volume <0-100>` - Set volume
- `:Nightride status` - Show detailed status

### Default Keybindings

- `<leader>np` - Toggle playback
- `<leader>n+` - Volume up
- `<leader>n-` - Volume down

## API

The plugin provides a comprehensive API for integration:

```lua
local nightride = require("nightride")

-- Basic controls
nightride.start("nightride")  -- Start specific station
nightride.stop()              -- Stop playback
nightride.toggle()            -- Toggle playback

-- Volume control
nightride.volume(75)          -- Set volume to 75%
nightride.volume_up()         -- Increase volume
nightride.volume_down()       -- Decrease volume

-- Information
nightride.status()            -- Show status
nightride.get_state()         -- Get player state
nightride.list_stations()     -- Get available stations
```

## Testing

To test the plugin during development:

```bash
nvim -u repro.lua
```

This will load the plugin with lualine for status line testing.

## Troubleshooting

### Audio Player Not Found

Install mpv (recommended), ffplay, or VLC:

```bash
# Ubuntu/Debian
sudo apt install mpv
# or
sudo apt install ffmpeg
# or
sudo apt install vlc

# macOS
brew install mpv
# or
brew install ffmpeg
# or
brew install vlc

# Android (Termux)
pkg install mpv
```

### Stream Issues

1. Check internet connectivity
2. Verify audio player installation: `which mpv`, `which ffplay`, or `which vlc`
3. Try a different player in configuration: `player = 'ffplay'`

### Volume Control

When using **mpv** (recommended), volume changes are applied instantly via IPC
without restarting the stream. With **ffplay** or **vlc**, volume changes
restart the stream with new settings - this causes a brief audio interruption.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [nightride.fm](https://nightride.fm) for providing amazing synthwave radio streams
- The Neovim community for excellent plugin ecosystem
