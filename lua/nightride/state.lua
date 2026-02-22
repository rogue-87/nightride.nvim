-- Minimal state persistence for nightride.nvim
-- Transparently saves/loads volume and last station between sessions
-- State is stored at: stdpath('state')/nightride/state.json

local M = {}

-- Use standard Neovim state directory
local state_dir = vim.fn.stdpath('state') .. '/nightride'
local state_file = state_dir .. '/state.json'

-- Minimal persistent state structure
local default_state = {
  last_volume = nil,    -- nil = use config default_volume
  last_station = nil,   -- nil = use config default_station
}

-- Simple table copy function
local function copy_table(t)
  local copy = {}
  for k, v in pairs(t) do
    if type(v) == 'table' then
      copy[k] = copy_table(v)
    else
      copy[k] = v
    end
  end
  return copy
end

-- Merge tables (target gets values from source)
local function merge_tables(target, source)
  local result = copy_table(target)
  for k, v in pairs(source) do
    result[k] = v
  end
  return result
end

---Load persistent state from file
---@return table state Loaded state or defaults if file doesn't exist/invalid
function M.load()
  -- Check if state file exists
  local file = io.open(state_file, 'r')
  if not file then
    return copy_table(default_state)
  end
  
  local content = file:read('*all')
  file:close()
  
  -- Empty file
  if content == '' then
    return copy_table(default_state)
  end
  
  -- Try to decode JSON
  local ok, state = pcall(vim.json.decode, content)
  if not ok or type(state) ~= 'table' then
    -- Corrupted file, return defaults
    return copy_table(default_state)
  end
  
  -- Merge with defaults to handle missing keys
  return merge_tables(default_state, state)
end

---Save persistent state to file
---@param state table State to save
---@return boolean success Whether save was successful
function M.save(state)
  -- Ensure state directory exists
  vim.fn.mkdir(state_dir, 'p')
  
  -- Load existing state (but avoid recursion by direct file read)
  local current_state = copy_table(default_state)
  local file = io.open(state_file, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    if content and content ~= '' then
      local ok, existing = pcall(vim.json.decode, content)
      if ok and type(existing) == 'table' then
        current_state = merge_tables(default_state, existing)
      end
    end
  end
  
  -- Update current state with new values
  if state.last_volume ~= nil then
    current_state.last_volume = state.last_volume
  end
  if state.last_station ~= nil then
    current_state.last_station = state.last_station
  end
  
  -- Only save non-nil values
  local save_state = {}
  if current_state.last_volume ~= nil then
    save_state.last_volume = current_state.last_volume
  end
  if current_state.last_station ~= nil then
    save_state.last_station = current_state.last_station
  end
  
  -- Convert to JSON
  local ok, json = pcall(vim.json.encode, save_state)
  if not ok then
    return false
  end
  
  -- Write to file
  local write_file = io.open(state_file, 'w')
  if not write_file then
    return false
  end
  
  write_file:write(json)
  write_file:close()
  return true
end

---Get the state file path (for debugging)
---@return string path Path to state file
function M.get_state_file()
  return state_file
end

return M