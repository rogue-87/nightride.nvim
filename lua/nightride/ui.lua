local M = {}

---Initialize UI components
function M.setup()
  -- UI setup complete - no statusline integration
end

---Show current status information
function M.show_status()
  local player = require('nightride.player')
  local stations = require('nightride.stations')
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