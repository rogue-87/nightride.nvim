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

## Recent Changes

### Simplification (February 2026)

- **Removed statusline integration**: Eliminated all statusline functionality to resolve freezing issues and reduce complexity
- **Removed `:Nightride select` command**: Replaced interactive station selection with tab completion for `:Nightride start <station>`
- **Streamlined configuration**: Reduced configuration options to focus on core streaming functionality
- **Fixed stability issues**: Resolved lualine loading order problems and blocking operation freezes
- **Added persistence**: Implemented minimal state persistence for volume and last played station between sessions

## Core Features

### 1. Station Management

- [x] Pre-configured list of all 7 Nightride FM stations
- [x] Station metadata (name, genre, description)
- [x] Current station state tracking
- [x] Last played station persistence

### 2. Audio Player Control

- [x] `mpv` integration via Neovim jobs with IPC socket for runtime volume
- [x] `ffplay` integration via Neovim jobs (restart-based volume)
- [x] `vlc` integration via Neovim jobs (restart-based volume)
- [x] Start/stop/restart streaming
- [x] Volume control (0-100%) - seamless with mpv, restart with ffplay/vlc
- [x] Volume persistence across sessions
- [x] Automatic cleanup on Neovim exit

### 3. User Interface

- [x] Simple command-based interface with tab completion
- [x] Configurable keybindings for core controls
- ~~Status line integration~~ (removed for simplicity)
- ~~Station selection menu~~ (removed in favor of tab completion)

### 4. Now Playing (Best Effort)

- [ ] Attempt to parse stream metadata
- [ ] Display in status line when available
- [ ] Graceful fallback to station name only

## Commands & Keybindings

### Commands

- [x] `:Nightride start [station]` - Start streaming (with tab completion)
- [x] `:Nightride stop` - Stop streaming
- [x] `:Nightride toggle` - Toggle playback (uses last played station)
- ~~`:Nightride select`~~ - ~~Show station selection menu~~ (removed)
- [x] `:Nightride volume [0-100]` - Set volume
- [x] `:Nightride status` - Show current status

### Default Keybindings (configurable)

- [x] `<leader>np` - Play/pause toggle
- ~~`<leader>ns`~~ - ~~Station selection~~ (removed)
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
    
    -- Key mappings
    keymaps = {
        toggle = '<leader>np',
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

- [x] Command interface with tab completion
- [x] Keybinding setup for core controls
- ~~Status line integration~~ (removed for simplicity)
- ~~Station selection menu~~ (removed in favor of tab completion)

### Phase 4: Integration & Polish

- [x] Plugin entry point
- [x] Command registration
- [x] Keybinding setup
- [x] Documentation
- [x] Session persistence for volume and station

### Phase 5: Testing & Refinement

- [x] Update repro.lua for testing
- [ ] Test all stations
- [ ] Performance optimization
- [ ] Bug fixes and improvements

## Success Criteria

- [ ] All 7 stations stream successfully
- [x] Volume control works smoothly
- [x] Tab completion provides easy station selection
- [x] Simple, focused interface without UI complexity
- [ ] No memory leaks or zombie processes
- [x] Clean integration with Neovim workflow

## Future Enhancements (Post-MVP)

- [ ] Favorite stations system
- [ ] Track history/logging
- [ ] Integration with notification systems
- [ ] Custom equalizer settings
- [ ] Playlist support (if API becomes available)
