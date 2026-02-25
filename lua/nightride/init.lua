local config = require("nightride.config")
local player = require("nightride.player")
local stations = require("nightride.stations")
local ui = require("nightride.ui")
local state = require("nightride.state")
local version = require("nightride.version")

local M = {}

-- Plugin state
local initialized = false

local function check_nvim_version()
	local current = vim.version()
	local required = vim.version.parse(version.min_nvim_version)
	if not current or not required then
		return true
	end
	if current.major < required.major or (current.major == required.major and current.minor < required.minor) then
		vim.notify(
			string.format(
				"nightride.nvim requires Neovim >= %s (current: %d.%d.%d)",
				version.min_nvim_version,
				current.major,
				current.minor,
				current.patch
			),
			vim.log.levels.WARN
		)
		return false
	end
	return true
end

---Setup the plugin with user options
---@param opts nightride.Config|nil User configuration options
function M.setup(opts)
	if not check_nvim_version() then
		return false
	end

	-- Configure the plugin
	config.setup(opts)

	-- Initialize player
	if not player.init() then
		return false
	end

	-- Setup UI components
	ui.setup()

	-- Setup keymappings if enabled
	M.setup_keymaps()

	initialized = true
	return true
end

---Setup default keymappings
function M.setup_keymaps()
	local opts = config.get()

	if not opts.keymaps then
		return
	end

	local function map(key, cmd, desc)
		if key and key ~= "" then
			vim.keymap.set("n", key, cmd, { desc = desc, silent = true })
		end
	end

	map(opts.keymaps.toggle, M.toggle, "Nightride: Toggle playback")
	map(opts.keymaps.volume_up, function()
		M.volume_up()
	end, "Nightride: Volume up")
	map(opts.keymaps.volume_down, function()
		M.volume_down()
	end, "Nightride: Volume down")
end

---Start streaming a station
---@param station_id string|nil Station ID to play (default: config default_station)
---@return boolean Success
function M.start(station_id)
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return false
	end

	local opts = config.get()
	local id = station_id or opts.default_station

	if not stations.is_valid_id(id) then
		vim.notify(string.format("Invalid station ID: %s", id), vim.log.levels.ERROR)
		return false
	end

	local station = stations.get_by_id(id)
	if not station then
		vim.notify(string.format("Station not found: %s", id), vim.log.levels.ERROR)
		return false
	end

	local success = player.start(station.id, station.url)
	if success then
		-- Save the station to state for next session
		state.save({ last_station = station.id })
	end
	return success
end

---Stop streaming
function M.stop()
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return
	end

	player.stop()
end

---Toggle playback (start last played or default station if not playing)
---@return boolean Success
function M.toggle()
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return false
	end

	local player_state = player.get_state()

	if player_state.is_playing then
		M.stop()
		return true
	else
		local opts = config.get()
		local saved_state = state.load()
		local station_id = saved_state.last_station or opts.default_station
		return M.start(station_id)
	end
end

---Set volume
---@param volume number Volume (0-100)
---@return boolean Success
function M.volume(volume)
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return false
	end

	if type(volume) ~= "number" or volume < 0 or volume > 100 then
		vim.notify("Volume must be a number between 0 and 100", vim.log.levels.ERROR)
		return false
	end

	return player.set_volume(volume)
end

---Increase volume
---@return boolean Success
function M.volume_up()
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return false
	end

	local opts = config.get()
	return player.adjust_volume(opts.volume_step)
end

---Decrease volume
---@return boolean Success
function M.volume_down()
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return false
	end

	local opts = config.get()
	return player.adjust_volume(-opts.volume_step)
end

---Show current status
function M.status()
	if not initialized then
		vim.notify("Nightride not initialized. Call setup() first.", vim.log.levels.ERROR)
		return
	end

	ui.show_status()
end

---Get current player state (for external integrations)
---@return nightride.PlayerState
function M.get_state()
	if not initialized then
		return {
			is_playing = false,
			current_station = nil,
			volume = 0,
			job_id = nil,
			player_cmd = nil,
		}
	end

	return player.get_state()
end

---List available stations
---@return nightride.Station[]
function M.list_stations()
	return stations.get_all()
end

-- Internal command handler for :Nightride command
function M._command_handler(opts)
	local args = opts.fargs
	local cmd = args[1]

	if not cmd then
		M.status()
		return
	end

	if cmd == "start" then
		local station_id = args[2]
		local success = M.start(station_id)
		if success then
			local station = stations.get_by_id(station_id or config.get().default_station)
			vim.notify(string.format("Started: %s", station and station.name or "Unknown"), vim.log.levels.INFO)
		end
	elseif cmd == "stop" then
		M.stop()
		vim.notify("Stopped", vim.log.levels.INFO)
	elseif cmd == "toggle" then
		M.toggle()
	elseif cmd == "volume" then
		local vol = tonumber(args[2])
		if not vol then
			vim.notify("Usage: :Nightride volume <0-100>", vim.log.levels.ERROR)
			return
		end

		local success = M.volume(vol)
		if success then
			vim.notify(string.format("Volume set to %d%%", vol), vim.log.levels.INFO)
		end
	elseif cmd == "status" then
		M.status()
	else
		vim.notify(string.format("Unknown command: %s", cmd), vim.log.levels.ERROR)
		vim.notify("Available commands: start, stop, toggle, volume, status", vim.log.levels.INFO)
	end
end

M.version = version.version

return M
