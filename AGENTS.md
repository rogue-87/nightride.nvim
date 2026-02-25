# AGENTS.md - nightride.nvim Development Guide

## Project Overview

nightride.nvim is a Neovim plugin for streaming music from nightride.fm. It supports multiple audio players (mpv, ffplay, VLC) with configurable keybindings and volume control.

## Build/Lint/Test Commands

### Testing

```bash
# Run the plugin in a test environment
nvim -u repro.lua
```

This loads the plugin with lazy.nvim for development testing.

### Code Quality

The project uses:
- **stylua** for Lua formatting (tabs, 4 spaces per indent)
- **luacheck** for Lua linting (optional)
- **Neovim built-in LSP** with lua_ls for type checking

To format code:
```bash
stylua lua/nightride/
```

## Code Style Guidelines

### General Structure

```lua
-- Module pattern used throughout
local M = {}

-- Use vim.api.nvim_* for Neovim API calls
-- Use vim.notify for user notifications
-- Use vim.log.levels for logging (ERROR, WARN, INFO, DEBUG, TRACE)

-- Return module at end
return M
```

### Naming Conventions

- **Files**: snake_case.lua (e.g., `nightride_config.lua`)
- **Modules**: snake_case (e.g., `require("nightride.config")`)
- **Functions**: snake_case (e.g., `get_state()`, `start_stream()`)
- **Variables**: snake_case (e.g., `local initialized = false`)
- **Types/Classes**: PascalCase with `nightride.` prefix (e.g., `nightride.Config`, `nightride.Station`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_VOLUME`)

### Indentation and Formatting

- Use **tabs** for indentation (not spaces)
- Each indent level = 1 tab
- Maximum line length: 120 characters (soft limit)
- Add trailing commas in tables for easier diffs

### Imports

- Use `local` for all require statements
- Group requires logically (stdlibs first, then third-party, then local)
- Example:
```lua
local M = {}

-- No external stdlib requires needed typically

-- Local module requires
local config = require("nightride.config")
local player = require("nightride.player")
local stations = require("nightride.stations")

-- Rest of module...
return M
```

### Types

This project uses **EmmyLua** annotations for type hints:

```lua
---@class nightride.Config
---@field player string Audio player preference ('mpv', 'ffplay', 'vlc', 'auto')
---@field default_station string Default station to play
---@field default_volume number Default volume (0-100)

---@param opts nightride.Config|nil User configuration options
function M.setup(opts)
    -- function body
end
```

Common patterns:
- `---@param` - function parameters
- `---@return` - return types
- `---@class` - type definitions
- `---@field` - class fields
- `---|` - union types (e.g., `station_id string|nil`)

### Error Handling

- Use `vim.notify()` with `vim.log.levels.ERROR` for user-facing errors
- Return `false` or `nil` on failure where appropriate
- Use `pcall()` for potentially failing operations (e.g., JSON decode)
- Validate input parameters early and return early with error

Example:
```lua
if not initialized then
    vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
    return false
end
```

### State Management

- Use module-level state (local variables) for runtime state
- Use `vim.fn.stdpath("state")` for persistent state storage
- Save state to JSON files using `vim.json.encode/decode`
- Use debouncing for frequent state saves (e.g., volume changes)

### Player Integration

- Use `vim.fn.jobstart()` for spawning audio players
- Use `vim.fn.jobstop()` to terminate players
- Handle `on_exit` callback for cleanup
- For mpv: use IPC socket (`--input-ipc-server`) for runtime volume control
- For ffplay/vlc: restart stream on volume change

### Keymappings

- Use `vim.keymap.set()` for creating keybindings
- Always provide a `desc` option for documentation
- Use `silent = true` to suppress command output

Example:
```lua
vim.keymap.set("n", "<leader>np", function()
    M.toggle()
end, { desc = "Nightride: Toggle playback", silent = true })
```

### Autocommands

- Use `vim.api.nvim_create_autocmd()` for autocommands
- Always provide a `desc` option
- Use `vim.schedule()` for UI-related callbacks from async operations

### Commands

- Create user commands with `vim.api.nvim_create_user_command()`
- Use `nargs = "*"` or `nargs = "?"` for command arguments
- Use `complete` for argument completion (e.g., station names)

## Project Structure

```
nightride.nvim/
├── lua/nightride/
│   ├── init.lua       -- Main plugin entry point
│   ├── config.lua     -- Configuration management
│   ├── player.lua     -- Audio player control
│   ├── stations.lua   -- Radio station definitions
│   ├── ui.lua         -- UI/status notifications
│   ├── state.lua      -- Persistent state (JSON)
│   └── utils.lua      -- Utility functions
├── plugin/nightride.lua    -- Plugin bootstrap
├── repro.lua               -- Test environment
└── README.md               -- User documentation
```

## Common Development Tasks

### Adding a New Station

Edit `lua/nightride/stations.lua` and add to the `M.stations` table:

```lua
{
    id = "newstation",
    name = "New Station FM",
    description = "Genre description",
    url = "https://nightride.fm/stream/newstation.m4a",
},
```

### Adding a New Player

1. Add player detection in `utils.lua:detect_player()`
2. Add argument creation in `utils.lua` (e.g., `create_player_args()`)
3. Add to `utils.lua:get_player_args()`
4. Add IPC support check in `utils.lua:supports_ipc()`

### Testing Changes

```bash
# Start Neovim with test configuration
nvim -u repro.lua

# Then test commands:
:Nightride start nightride
:Nightride volume 75
:Nightride stop
:Nightride status
```

## Configuration Reference

Default configuration:

```lua
require("nightride").setup({
    player = "auto",              -- 'mpv', 'ffplay', 'vlc', 'auto'
    default_station = "nightride",
    default_volume = 50,
    volume_step = 5,
    keymaps = {
        toggle = "<leader>np",
        volume_up = "<leader>n+",
        volume_down = "<leader>n-",
    },
})
```

## API Reference

| Function | Description |
|----------|-------------|
| `nightride.start(station_id)` | Start playing a station |
| `nightride.stop()` | Stop playback |
| `nightride.toggle()` | Toggle playback on/off |
| `nightride.volume(level)` | Set volume (0-100) |
| `nightride.volume_up()` | Increase volume |
| `nightride.volume_down()` | Decrease volume |
| `nightride.status()` | Show current status |
| `nightride.get_state()` | Get player state object |
| `nightride.list_stations()` | Get all available stations |
