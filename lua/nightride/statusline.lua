local M = {}

local status_cache = {
	is_playing = false,
	current_station = nil,
	volume = 50,
}

function M.refresh()
	local ok, nightride = pcall(require, "nightride")
	if ok and nightride.get_state then
		local state = nightride.get_state()
		status_cache.is_playing = state.is_playing
		status_cache.current_station = state.current_station
		status_cache.volume = state.volume
	end
end

function M.component()
	if status_cache.is_playing then
		return string.format(
			"%%#NightridePlaying# ♫ %s (%d%%%%)",
			status_cache.current_station or "Unknown",
			status_cache.volume
		)
	end
	return "♫ --"
end

function M.setup()
	vim.defer_fn(function()
		M.refresh()
		vim.defer_fn(M.refresh, 1000)
	end, 100)

	vim.api.nvim_create_autocmd("User", {
		pattern = "NightrideStateChanged",
		callback = function()
			M.refresh()
		end,
	})
end

return M
