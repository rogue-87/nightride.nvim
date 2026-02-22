local player = require('nightride.player')
local stations = require('nightride.stations')
local config = require('nightride.config')

local M = {}

---Show station selection menu
function M.show_station_selector()
  local station_list = stations.get_all()
  local display_names = stations.get_display_names()
  
  vim.ui.select(display_names, {
    prompt = 'Select Nightride Station:',
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      return -- User cancelled
    end
    
    local selected_station = stations.get_by_display_name(choice)
    if not selected_station then
      vim.notify('Invalid station selection', vim.log.levels.ERROR)
      return
    end
    
    -- Start playing the selected station
    local success = player.start(selected_station.id, selected_station.url)
    if success then
      vim.notify(string.format('Now playing: %s', selected_station.name), vim.log.levels.INFO)
    else
      vim.notify(string.format('Failed to start: %s', selected_station.name), vim.log.levels.ERROR)
    end
  end)
end

---Get status line component for external status line plugins
---@return string
function M.get_statusline_component()
  local opts = config.get()
  
  if not opts.statusline.enabled then
    return ''
  end
  
  return player.get_status_string()
end

---Setup status line integration
function M.setup_statusline()
  local opts = config.get()
  
  if not opts.statusline.enabled then
    return
  end
  
  -- Create autocmd to update status line when player state changes
  vim.api.nvim_create_autocmd('User', {
    pattern = 'NightrideStatusChanged',
    callback = function()
      -- Force statusline refresh
      vim.cmd('redrawstatus')
    end,
    desc = 'Update status line when nightride status changes'
  })
  
  -- Setup vim-airline integration if available
  if vim.g.loaded_airline then
    vim.g['airline#extensions#nightride#enabled'] = 1
  end
end

---Initialize UI components
function M.setup()
  M.setup_statusline()
end

---Integration function for lualine
---@return table Lualine component
function M.lualine_component()
  return {
    function()
      return M.get_statusline_component()
    end,
    cond = function()
      return config.get_option('statusline.enabled') and player.get_state().is_playing
    end
  }
end

---Integration function for vim-airline
function M.airline_component()
  if not config.get_option('statusline.enabled') then
    return ''
  end
  
  return M.get_statusline_component()
end

---Show current status information
function M.show_status()
  local state = player.get_state()
  
  if not state.is_playing then
    vim.notify('Nightride: Not playing', vim.log.levels.INFO)
    return
  end
  
  local station = stations.get_by_id(state.current_station)
  local station_name = station and station.name or 'Unknown Station'
  local station_desc = station and station.description or ''
  
  local message = string.format(
    'Nightride: %s\n%s\nVolume: %d%%\nPlayer: %s',
    station_name,
    station_desc,
    state.volume,
    state.player_cmd or 'Unknown'
  )
  
  vim.notify(message, vim.log.levels.INFO)
end

return M