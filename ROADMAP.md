# nightride.nvim Development Roadmap

## Overview
A Neovim plugin for streaming music from nightride.fm - the home of synthwave radio.

## Research Findings

### Nightride FM Streaming
- **7 available stations**: `nightride`, `chillsynth`, `datawave`, `spacesynth`, `darksynth`, `horrorsynth`, `ebsm`
- **Stream URLs**: `https://nightride.fm/stream/{station}.m4a`
- **Quality**: High quality 320kbps AAC streams
- **Genres**: Synthwave, retrowave, cyberpunk, darksynth, chillsynth, spacesynth, horrorsynth, EBSM/industrial

### Audio Playback Strategy
- **Primary**: `mpv` (IPC-based runtime volume control via Unix socket)
- **Fallback 1**: `ffplay` (lightweight, part of FFmpeg; restart-based volume)
- **Fallback 2**: VLC (if ffplay unavailable; restart-based volume)
- **Integration**: Background streaming via Neovim job control
- **Detection priority**: mpv > ffplay > vlc (auto mode)

## Plugin Architecture

### File Structure
```
nightride.nvim/
├── lua/
│   └── nightride/
│       ├── init.lua          # Main module & public API
│       ├── config.lua        # Configuration and defaults
│       ├── player.lua        # Audio player management
│       ├── stations.lua      # Station data and management
│       ├── ui.lua           # Status line and selection menu
│       └── utils.lua        # Utility functions
├── plugin/
│   └── nightride.lua        # Plugin entry point & commands
├── doc/
│   └── nightride.txt        # Documentation
└── ROADMAP.md               # This file
```

## Core Features

### 1. Station Management
- [x] Pre-configured list of all 7 Nightride FM stations
- [x] Station metadata (name, genre, description)
- [x] Current station state tracking

### 2. Audio Player Control
- [x] `mpv` integration via Neovim jobs with IPC socket for runtime volume
- [x] `ffplay` integration via Neovim jobs (restart-based volume)
- [x] `vlc` integration via Neovim jobs (restart-based volume)
- [x] Start/stop/restart streaming
- [x] Volume control (0-100%) - seamless with mpv, restart with ffplay/vlc
- [x] Automatic cleanup on Neovim exit

### 3. User Interface
- [x] Status line integration showing: `♪ [Station] Volume%`
- [x] Selection menu with snacks.nvim picker (+ `vim.ui.select()` fallback)
- [x] Simple command-based interface

### 4. Now Playing (Best Effort)
- [ ] Attempt to parse stream metadata
- [ ] Display in status line when available
- [ ] Graceful fallback to station name only

## Commands & Keybindings

### Commands
- [x] `:Nightride start [station]` - Start streaming (default: nightride)
- [x] `:Nightride stop` - Stop streaming
- [x] `:Nightride toggle` - Toggle playback
- [x] `:Nightride select` - Show station selection menu
- [x] `:Nightride volume [0-100]` - Set volume
- [x] `:Nightride status` - Show current status

### Default Keybindings (configurable)
- [x] `<leader>np` - Play/pause toggle
- [x] `<leader>ns` - Station selection
- [x] `<leader>n+` - Volume up
- [x] `<leader>n-` - Volume down

## Configuration

```lua
require('nightride').setup({
    -- Audio player preference
    player = 'auto', -- 'mpv', 'ffplay', 'vlc', 'auto'
    
    -- Default station
    default_station = 'nightride',
    
    -- Volume settings
    default_volume = 50,
    volume_step = 5,
    
    -- Status line integration
    statusline = {
        enabled = true,
        format = '♪ [%s] %d%%', -- station, volume
        position = 'right',
    },
    
    -- Key mappings
    keymaps = {
        toggle = '<leader>np',
        select = '<leader>ns',
        volume_up = '<leader>n+',
        volume_down = '<leader>n-',
    }
})
```

## Implementation Plan

### Phase 1: Core Infrastructure
- [x] Create project structure
- [x] Implement configuration system
- [x] Create station data module
- [x] Set up utility functions

### Phase 2: Audio Engine
- [x] Implement player management with mpv (IPC), ffplay, vlc
- [x] Add volume control (seamless via mpv IPC, restart-based for ffplay/vlc)
- [x] Handle process lifecycle
- [x] Error handling and recovery

### Phase 3: User Interface
- [x] Status line integration
- [x] Station selection menu (snacks.nvim picker + vim.ui.select fallback)
- [x] Command interface

### Phase 4: Integration & Polish
- [x] Plugin entry point
- [x] Command registration
- [x] Keybinding setup
- [x] Documentation

### Phase 5: Testing & Refinement
- [x] Update repro.lua for testing
- [ ] Test all stations
- [ ] Performance optimization
- [ ] Bug fixes and improvements

## Success Criteria
- [ ] All 7 stations stream successfully
- [x] Volume control works smoothly
- [x] Status line shows current state
- [x] Selection menu is intuitive
- [ ] No memory leaks or zombie processes
- [ ] Clean integration with Neovim workflow

## Future Enhancements (Post-MVP)
- [ ] Favorite stations system
- [ ] Track history/logging
- [ ] Integration with notification systems
- [ ] Custom equalizer settings
- [ ] Playlist support (if API becomes available)