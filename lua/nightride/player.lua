local utils = require("nightride.utils")
local config = require("nightride.config")
local state = require("nightride.state")

---@class nightride.PlayerState
---@field is_playing boolean Whether audio is currently playing
---@field current_station string|nil ID of current station
---@field volume number Current volume (0-100)
---@field job_id number|nil Current job ID
---@field player_cmd string|nil Current player command

local M = {}

-- Debounce timer for state saving
local save_timer = nil

---@type nightride.PlayerState
M.state = {
	is_playing = false,
	current_station = nil,
	volume = 50,
	job_id = nil,
	player_cmd = nil,
}

---Initialize the player with configuration
function M.init()
	local opts = config.get()

	-- Load saved state and use saved volume if available
	local saved_state = state.load()
	M.state.volume = saved_state.last_volume or opts.default_volume

	-- Detect or set player
	if opts.player == "auto" then
		M.state.player_cmd = utils.detect_player()
		if not M.state.player_cmd then
			vim.notify("No compatible audio player found (mpv, ffplay, vlc)", vim.log.levels.ERROR)
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

---Clean up a stale mpv IPC socket file if it exists
local function cleanup_socket()
	local socket_path = utils.get_ipc_socket_path()
	os.remove(socket_path)
end

---Kill the running player process without resetting playback state.
---Used internally when restarting the stream (e.g. station change on fallback players).
local function kill_job()
	if M.state.job_id then
		vim.fn.jobstop(M.state.job_id)
		M.state.job_id = nil
	end
	-- Clean up socket so mpv can create a fresh one on next start
	if M.state.player_cmd == "mpv" then
		cleanup_socket()
	end
end

---Stop current playback
function M.stop()
	kill_job()

	M.state.is_playing = false
	M.state.current_station = nil
end

---Start playback for a station
---@param station_id string Station identifier
---@param url string Stream URL
---@return boolean Success
function M.start(station_id, url)
	-- Kill current process if running (without resetting state)
	kill_job()

	if not M.state.player_cmd then
		vim.notify("No audio player available", vim.log.levels.ERROR)
		return false
	end

	local args = utils.get_player_args(M.state.player_cmd, url, M.state.volume)
	if not args then
		vim.notify(string.format("Unsupported player: %s", M.state.player_cmd), vim.log.levels.ERROR)
		return false
	end

	-- Start the audio stream
	local job_id = vim.fn.jobstart(args, {
		on_exit = function(id, exit_code, _)
			-- Only handle if this is still the active job
			if M.state.job_id ~= id then
				return
			end

			M.state.is_playing = false
			M.state.current_station = nil
			M.state.job_id = nil

			if exit_code ~= 0 and exit_code ~= 130 and exit_code ~= 143 then
				vim.schedule(function()
					vim.notify(string.format("Stream ended unexpectedly (code: %d)", exit_code), vim.log.levels.WARN)
				end)
			end

			-- Clean up socket on exit
			if M.state.player_cmd == "mpv" then
				cleanup_socket()
			end
		end,

		-- Note: on_stderr callback removed to prevent UI lag from mpv's verbose stderr output
	})

	if job_id <= 0 then
		vim.notify("Failed to start audio player", vim.log.levels.ERROR)
		return false
	end

	M.state.job_id = job_id
	M.state.is_playing = true
	M.state.current_station = station_id

	return true
end

---Toggle playback (start default station if not playing)
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

---Set volume via mpv IPC (seamless, no stream restart)
---@param new_volume number New volume (0-100)
---@return boolean Success (always true; IPC is fire-and-forget)
local function set_volume_ipc(new_volume)
	local socket_path = utils.get_ipc_socket_path()
	utils.send_mpv_command(socket_path, { "set_property", "volume", new_volume }, function(err, _)
		if err then
			vim.notify(string.format("mpv IPC volume error: %s", tostring(err)), vim.log.levels.DEBUG)
		end
	end)
	return true
end

---Set volume via stream restart (ffplay/vlc fallback)
---@param new_volume number New volume (0-100)
---@param old_volume number Previous volume to restore on failure
---@return boolean Success
local function set_volume_restart(new_volume, old_volume)
	local stations = require("nightride.stations")
	local station = stations.get_by_id(M.state.current_station)

	if station then
		local success = M.start(M.state.current_station, station.url)
		if not success then
			M.state.volume = old_volume
			return false
		end
	end

	return true
end

---Set volume
---@param new_volume number New volume (0-100)
---@return boolean Success
function M.set_volume(new_volume)
	local clamped_volume = utils.clamp(new_volume, 0, 100)
	local old_volume = M.state.volume
	M.state.volume = clamped_volume

	if M.state.is_playing and M.state.current_station then
		if utils.supports_ipc(M.state.player_cmd) then
			-- mpv: seamless volume change via IPC socket
			set_volume_ipc(clamped_volume)
		else
			-- ffplay/vlc: must restart stream with new volume args
			local success = set_volume_restart(clamped_volume, old_volume)
			if not success then
				return false
			end
		end

		-- Save volume change (debounced to avoid excessive I/O)
		if save_timer then
			save_timer:stop()
		end
		save_timer = vim.defer_fn(function()
			local current_state = {
				last_volume = M.state.volume,
				last_station = M.state.current_station,
			}
			state.save(current_state)
		end, 1000) -- 1 second debounce

		return true
	end

	return true
end

---Adjust volume by delta
---@param delta number Volume change amount
---@return boolean Success
function M.adjust_volume(delta)
	return M.set_volume(M.state.volume + delta)
end

---Save state immediately (used for station changes and cleanup)
local function save_state_now()
	local current_state = {
		last_volume = M.state.volume,
		last_station = M.state.current_station,
	}
	state.save(current_state)
end

---Cleanup on plugin unload
function M.cleanup()
	-- Cancel any pending debounced save
	if save_timer then
		save_timer:stop()
	end

	-- Save state immediately before cleanup
	save_state_now()

	if M.state.is_playing then
		M.stop()
	end
end

-- Setup autocmd to cleanup on VimLeavePre
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		M.cleanup()
	end,
	desc = "Cleanup nightride audio on Neovim exit",
})

return M
