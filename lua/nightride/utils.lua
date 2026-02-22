local M = {}

---Check if a command exists on the system
---@param cmd string Command name to check
---@return boolean
function M.command_exists(cmd)
  local handle = io.popen('which ' .. cmd .. ' 2>/dev/null')
  if not handle then
    return false
  end
  
  local result = handle:read('*a')
  handle:close()
  
  return result ~= ''
end

---Detect available audio player
---@return string|nil Available player command or nil
function M.detect_player()
  local players = { 'ffplay', 'vlc' }
  
  for _, player in ipairs(players) do
    if M.command_exists(player) then
      return player
    end
  end
  
  return nil
end

---Clamp a value between min and max
---@param value number Value to clamp
---@param min number Minimum value
---@param max number Maximum value
---@return number
function M.clamp(value, min, max)
  return math.min(max, math.max(min, value))
end

---Convert volume (0-100) to player-specific format
---@param volume number Volume percentage (0-100)
---@param player string Player type ('ffplay' or 'vlc')
---@return string
function M.volume_to_player_format(volume, player)
  local clamped = M.clamp(volume, 0, 100)
  
  if player == 'ffplay' then
    -- ffplay uses volume filter where 1.0 = 100%
    return string.format('%.2f', clamped / 100)
  elseif player == 'vlc' then
    -- VLC uses percentage directly
    return tostring(clamped)
  end
  
  return tostring(clamped)
end

---Create ffplay command arguments
---@param url string Stream URL
---@param volume number Volume (0-100)
---@return string[]
function M.create_ffplay_args(url, volume)
  return {
    'ffplay',
    '-nodisp',           -- No video display
    '-autoexit',         -- Exit when playback ends
    '-loglevel', 'quiet', -- Suppress output
    '-af', 'volume=' .. M.volume_to_player_format(volume, 'ffplay'),
    url
  }
end

---Create VLC command arguments
---@param url string Stream URL
---@param volume number Volume (0-100)
---@return string[]
function M.create_vlc_args(url, volume)
  return {
    'vlc',
    '--intf', 'dummy',   -- No interface
    '--play-and-exit',   -- Exit when playback ends
    '--quiet',           -- Suppress output
    '--volume=' .. M.volume_to_player_format(volume, 'vlc'),
    url
  }
end

---Get process arguments for player
---@param player string Player type
---@param url string Stream URL
---@param volume number Volume (0-100)
---@return string[]|nil
function M.get_player_args(player, url, volume)
  if player == 'ffplay' then
    return M.create_ffplay_args(url, volume)
  elseif player == 'vlc' then
    return M.create_vlc_args(url, volume)
  end
  
  return nil
end

---Format status line text
---@param format string Format string with %s and %d placeholders
---@param station_name string Current station name
---@param volume number Current volume
---@return string
function M.format_status(format, station_name, volume)
  return string.format(format, station_name, volume)
end

---Debounce a function call
---@param func function Function to debounce
---@param delay number Delay in milliseconds
---@return function Debounced function
function M.debounce(func, delay)
  local timer = nil
  
  return function(...)
    local args = { ... }
    
    if timer then
      timer:stop()
      timer:close()
    end
    
    timer = vim.defer_fn(function()
      func(unpack(args))
      timer = nil
    end, delay)
  end
end

return M