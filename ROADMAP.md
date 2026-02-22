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
- **Primary**: `ffplay` (lightweight, minimal UI, part of FFmpeg)
- **Fallback**: VLC (if ffplay unavailable)
- **Integration**: Background streaming via Neovim job control

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
- [ ] Current station state tracking

### 2. Audio Player Control
- [ ] `ffplay` integration via Neovim jobs
- [ ] Start/stop/restart streaming
- [ ] Volume control (0-100%)
- [ ] Automatic cleanup on Neovim exit

### 3. User Interface
- [ ] Status line integration showing: `♪ [Station] Volume%`
- [ ] Selection menu with `vim.ui.select()` for station choosing
- [ ] Simple command-based interface

### 4. Now Playing (Best Effort)
- [ ] Attempt to parse stream metadata
- [ ] Display in status line when available
- [ ] Graceful fallback to station name only

## Commands & Keybindings

### Commands
- [ ] `:Nightride start [station]` - Start streaming (default: nightride)
- [ ] `:Nightride stop` - Stop streaming
- [ ] `:Nightride toggle` - Toggle playback
- [ ] `:Nightride select` - Show station selection menu
- [ ] `:Nightride volume [0-100]` - Set volume
- [ ] `:Nightride status` - Show current status

### Default Keybindings (configurable)
- [ ] `<leader>np` - Play/pause toggle
- [ ] `<leader>ns` - Station selection
- [ ] `<leader>n+` - Volume up
- [ ] `<leader>n-` - Volume down

## Configuration

```lua
require('nightride').setup({
    -- Audio player preference
    player = 'auto', -- 'ffplay', 'vlc', 'auto'
    
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
- [ ] Implement configuration system
- [ ] Create station data module
- [ ] Set up utility functions

### Phase 2: Audio Engine
- [ ] Implement player management with ffplay
- [ ] Add volume control
- [ ] Handle process lifecycle
- [ ] Error handling and recovery

### Phase 3: User Interface
- [ ] Status line integration
- [ ] Station selection menu
- [ ] Command interface

### Phase 4: Integration & Polish
- [ ] Plugin entry point
- [ ] Command registration
- [ ] Keybinding setup
- [ ] Documentation

### Phase 5: Testing & Refinement
- [ ] Update repro.lua for testing
- [ ] Test all stations
- [ ] Performance optimization
- [ ] Bug fixes and improvements

## Technical Implementation Details

### Player Management
- Use `vim.system()` for spawning ffplay processes
- Store job handles for process management
- Implement volume control via ffplay's `-af volume` filter
- Handle process cleanup and error recovery

### Status Line Integration
- Hook into common status line plugins (lualine, etc.)
- Provide function for manual integration
- Update status when state changes

### Station Selection
- Use `vim.ui.select()` for native-feeling selection menu
- Display station names with genre descriptions
- Handle selection and immediate playback

## Success Criteria
- [ ] All 7 stations stream successfully
- [ ] Volume control works smoothly
- [ ] Status line shows current state
- [ ] Selection menu is intuitive
- [ ] No memory leaks or zombie processes
- [ ] Clean integration with Neovim workflow

## Future Enhancements (Post-MVP)
- [ ] Favorite stations system
- [ ] Track history/logging
- [ ] Integration with notification systems
- [ ] Custom equalizer settings
- [ ] Playlist support (if API becomes available)