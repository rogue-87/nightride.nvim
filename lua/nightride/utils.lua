local M = {}

---Check if a command exists on the system
---@param cmd string Command name to check
---@return boolean
function M.command_exists(cmd)
  -- Use vim.system for non-blocking execution (nvim 0.10+)
  if vim.system then
    local result = vim.system({'which', cmd}, {text = true}):wait(1000)
    return result.code == 0
  else
    -- Fallback for older nvim versions - this blocks but should only run once at init
    local handle = io.popen('which ' .. cmd .. ' 2>/dev/null')
    if not handle then
      return false
    end
    
    local result = handle:read('*a')
    handle:close()
    
    return result ~= ''
  end
end

---Detect available audio player
---Priority: mpv (IPC volume control) > ffplay > vlc (restart-based volume)
---@return string|nil Available player command or nil
function M.detect_player()
  local players = { 'mpv', 'ffplay', 'vlc' }

  for _, player in ipairs(players) do
    if M.command_exists(player) then
      return player
    end
  end

  return nil
end

---Check if a player supports IPC-based runtime volume control
---@param player string Player command name
---@return boolean
function M.supports_ipc(player)
  return player == 'mpv'
end

---Get the IPC socket path for mpv
---Cross-platform: Termux uses $PREFIX/tmp, others use /tmp
---@return string
function M.get_ipc_socket_path()
  local prefix = os.getenv('PREFIX')
  if prefix then
    -- Termux (Android): $PREFIX/tmp/
    return prefix .. '/tmp/nightride-mpv.sock'
  end
  return '/tmp/nightride-mpv.sock'
end

---Send a JSON-RPC command to mpv via its IPC socket
---Uses luv (vim.uv / vim.loop) for async pipe communication
---@param socket_path string Path to the mpv IPC socket
---@param command table The command array, e.g. {"set_property", "volume", 75}
---@param callback function|nil Optional callback(err, response)
function M.send_mpv_command(socket_path, command, callback)
  local uv = vim.uv or vim.loop
  local pipe = uv.new_pipe(false)

  if not pipe then
    if callback then callback('Failed to create pipe', nil) end
    return
  end

  pipe:connect(socket_path, function(err)
    if err then
      pipe:close()
      if callback then
        vim.schedule(function() callback(err, nil) end)
      end
      return
    end

    local payload = vim.json.encode({ command = command }) .. '\n'

    pipe:write(payload, function(write_err)
      if write_err then
        pipe:close()
        if callback then
          vim.schedule(function() callback(write_err, nil) end)
        end
        return
      end

      if callback then
        -- Read one response
        pipe:read_start(function(read_err, data)
          pipe:read_stop()
          pipe:close()
          vim.schedule(function()
            if read_err then
              callback(read_err, nil)
            elseif data then
              local ok, decoded = pcall(vim.json.decode, data)
              callback(nil, ok and decoded or data)
            else
              callback(nil, nil)
            end
          end)
        end)
      else
        -- Fire-and-forget: close after a small delay to let the write flush
        pipe:shutdown(function()
          pipe:close()
        end)
      end
    end)
  end)
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
---@param player string Player type ('mpv', 'ffplay', or 'vlc')
---@return string
function M.volume_to_player_format(volume, player)
  local clamped = M.clamp(volume, 0, 100)
  
  if player == 'ffplay' then
    -- ffplay uses volume filter where 1.0 = 100%
    return string.format('%.2f', clamped / 100)
  elseif player == 'vlc' then
    -- VLC uses percentage directly
    return tostring(clamped)
  elseif player == 'mpv' then
    -- mpv uses 0-100 directly
    return tostring(clamped)
  end
  
  return tostring(clamped)
end

---Create mpv command arguments (with IPC socket for runtime control)
---@param url string Stream URL
---@param volume number Volume (0-100)
---@return string[]
function M.create_mpv_args(url, volume)
  return {
    'mpv',
    '--no-video',
    '--quiet',
    '--volume=' .. M.volume_to_player_format(volume, 'mpv'),
    '--input-ipc-server=' .. M.get_ipc_socket_path(),
    url,
  }
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
  if player == 'mpv' then
    return M.create_mpv_args(url, volume)
  elseif player == 'ffplay' then
    return M.create_ffplay_args(url, volume)
  elseif player == 'vlc' then
    return M.create_vlc_args(url, volume)
  end
  
  return nil
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