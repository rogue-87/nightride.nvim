---@class nightride.Config
---@field player string Audio player preference ('mpv', 'ffplay', 'vlc', 'auto')
---@field default_station string Default station to play
---@field default_volume number Default volume (0-100)
---@field volume_step number Volume adjustment step size
---@field keymaps nightride.KeymapConfig Key mapping configuration

---@class nightride.KeymapConfig
---@field toggle string Key mapping for play/pause toggle
---@field select string Key mapping for station selection
---@field volume_up string Key mapping for volume up
---@field volume_down string Key mapping for volume down

local M = {}

---@type nightride.Config
M.defaults = {
  player = 'auto',
  default_station = 'nightride',
  default_volume = 50,
  volume_step = 5,
  keymaps = {
    toggle = '<leader>np',
    select = '<leader>ns',
    volume_up = '<leader>n+',
    volume_down = '<leader>n-',
  }
}

---@type nightride.Config
M.options = {}

---Setup configuration with user options
---@param opts nightride.Config|nil User configuration options
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

---Get current configuration
---@return nightride.Config
function M.get()
  return M.options
end

---Get a specific config value with dot notation
---@param key string Configuration key (e.g., 'statusline.enabled')
---@return any
function M.get_option(key)
  local keys = vim.split(key, '.', { plain = true })
  local value = M.options
  
  for _, k in ipairs(keys) do
    if type(value) ~= 'table' then
      return nil
    end
    value = value[k]
  end
  
  return value
end

---Set a specific config value with dot notation
---@param key string Configuration key (e.g., 'default_volume')
---@param value any Value to set
function M.set_option(key, value)
  local keys = vim.split(key, '.', { plain = true })
  local config = M.options
  
  for i = 1, #keys - 1 do
    local k = keys[i]
    if type(config[k]) ~= 'table' then
      config[k] = {}
    end
    config = config[k]
  end
  
  config[keys[#keys]] = value
end

return M