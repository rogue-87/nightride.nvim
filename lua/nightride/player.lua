local utils = require('nightride.utils')
local config = require('nightride.config')

---@class nightride.PlayerState
---@field is_playing boolean Whether audio is currently playing
---@field current_station string|nil ID of current station
---@field volume number Current volume (0-100)
---@field job_id number|nil Current job ID
---@field player_cmd string|nil Current player command

local M = {}

---@type nightride.PlayerState
M.state = {
  is_playing = false,
  current_station = nil,
  volume = 50,
  job_id = nil,
  player_cmd = nil
}

---Initialize the player with configuration
function M.init()
  local opts = config.get()
  M.state.volume = opts.default_volume
  
  -- Detect or set player
  if opts.player == 'auto' then
    M.state.player_cmd = utils.detect_player()
    if not M.state.player_cmd then
      vim.notify('No compatible audio player found (ffplay, vlc)', vim.log.levels.ERROR)
      return false
    end
  else
    if utils.command_exists(opts.player) then
      M.state.player_cmd = opts.player
    else
      vim.notify(string.format('Audio player "%s" not found', opts.player), vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

---Get current player state
---@return nightride.PlayerState
function M.get_state()
  return vim.deepcopy(M.state)
end

---Stop current playback
function M.stop()
  if M.state.job_id then
    vim.fn.jobstop(M.state.job_id)
    M.state.job_id = nil
  end
  
  M.state.is_playing = false
  M.state.current_station = nil
  
  -- Trigger status update
  vim.api.nvim_exec_autocmds('User', { pattern = 'NightrideStatusChanged' })
end

---Start playback for a station
---@param station_id string Station identifier
---@param url string Stream URL
---@return boolean Success
function M.start(station_id, url)
  -- Stop current playback if running
  if M.state.is_playing then
    M.stop()
  end
  
  if not M.state.player_cmd then
    vim.notify('No audio player available', vim.log.levels.ERROR)
    return false
  end
  
  local args = utils.get_player_args(M.state.player_cmd, url, M.state.volume)
  if not args then
    vim.notify(string.format('Unsupported player: %s', M.state.player_cmd), vim.log.levels.ERROR)
    return false
  end
  
  -- Start the audio stream
  M.state.job_id = vim.fn.jobstart(args, {
    on_exit = function(job_id, exit_code, event_type)
      if M.state.job_id == job_id then
        M.state.is_playing = false
        M.state.job_id = nil
        
        if exit_code ~= 0 and exit_code ~= 130 then -- 130 is normal SIGINT
          vim.notify(string.format('Stream ended unexpectedly (code: %d)', exit_code), vim.log.levels.WARN)
        end
        
        -- Trigger status update
        vim.api.nvim_exec_autocmds('User', { pattern = 'NightrideStatusChanged' })
      end
    end,
    
    -- Note: on_stderr callback removed to prevent UI lag from mpv's verbose stderr output
  })
  
  if M.state.job_id <= 0 then
    vim.notify('Failed to start audio player', vim.log.levels.ERROR)
    M.state.job_id = nil
    return false
  end
  
  M.state.is_playing = true
  M.state.current_station = station_id
  
  -- Trigger status update
  vim.api.nvim_exec_autocmds('User', { pattern = 'NightrideStatusChanged' })
  
  return true
end

---Toggle playbook (start default station if not playing)
---@param default_station string Default station to start if not playing
---@param station_url string URL for default station
---@return boolean Success
function M.toggle(default_station, station_url)
  if M.state.is_playing then
    M.stop()
    return true
  else
    return M.start(default_station, station_url)
  end
end

---Set volume
---@param new_volume number New volume (0-100)
---@return boolean Success
function M.set_volume(new_volume)
  local clamped_volume = utils.clamp(new_volume, 0, 100)
  local old_volume = M.state.volume
  M.state.volume = clamped_volume
  
  -- If currently playing, restart with new volume
  if M.state.is_playing and M.state.current_station then
    local stations = require('nightride.stations')
    local station = stations.get_by_id(M.state.current_station)
    
    if station then
      -- Restart playback with new volume
      local success = M.start(M.state.current_station, station.url)
      if not success then
        -- Restore old volume on failure
        M.state.volume = old_volume
        return false
      end
    end
  else
    -- Just update volume state
    vim.api.nvim_exec_autocmds('User', { pattern = 'NightrideStatusChanged' })
  end
  
  return true
end

---Adjust volume by delta
---@param delta number Volume change amount
---@return boolean Success
function M.adjust_volume(delta)
  return M.set_volume(M.state.volume + delta)
end

---Get formatted status string
---@return string
function M.get_status_string()
  local opts = config.get()
  
  if not M.state.is_playing then
    return ''
  end
  
  local stations = require('nightride.stations')
  local station = stations.get_by_id(M.state.current_station)
  local station_name = station and station.name or 'Unknown'
  
  return utils.format_status(opts.statusline.format, station_name, M.state.volume)
end

---Cleanup on plugin unload
function M.cleanup()
  if M.state.is_playing then
    M.stop()
  end
end

-- Setup autocmd to cleanup on VimLeavePre
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    M.cleanup()
  end,
  desc = 'Cleanup nightride audio on Neovim exit'
})

return M