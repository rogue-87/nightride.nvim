---@class nightride.Health
local M = {}

function M.check()
	if not vim.health then
		vim.notify("Health API not available", vim.log.levels.WARN)
		return
	end

	vim.health.start("nightride.nvim")

	local version = require("nightride.version")
	vim.health.info(string.format("Version: %s", version.version))
	vim.health.info(string.format("Minimum Neovim: %s", version.min_nvim_version))

	local current = vim.version()
	vim.health.info(string.format("Current Neovim: %d.%d.%d", current.major, current.minor, current.patch))

	local required = vim.version.parse(version.min_nvim_version) --[[@as vim.Version]]
	if current.major < required.major or (current.major == required.major and current.minor < required.minor) then
		vim.health.warn(string.format("Neovim version too old (need >= %s)", version.min_nvim_version))
	end

	vim.health.start("Audio player")
	local utils = require("nightride.utils")
	local player = utils.detect_player()
	if player then
		vim.health.ok(string.format("Found: %s", player))
	else
		vim.health.error("No audio player found (mpv, ffplay, or vlc)")
	end

	vim.health.start("Stations")
	local stations = require("nightride.stations")
	local all_stations = stations.get_all()
	vim.health.info(string.format("%d stations available", #all_stations))

	for _, s in ipairs(all_stations) do
		vim.health.info(string.format("  - %s: %s", s.id, s.name))
	end

	local state = require("nightride.state")
	vim.health.start("State")
	vim.health.info(string.format("State file: %s", state.get_state_file()))
end

return M
