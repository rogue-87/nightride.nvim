-- nightride.nvim - Stream music from nightride.fm in Neovim
-- Plugin entry point and command registration

if vim.g.loaded_nightride then
	return
end
vim.g.loaded_nightride = 1

-- Create the main command
vim.api.nvim_create_user_command("Nightride", function(opts)
	require("nightride")._command_handler(opts)
end, {
	nargs = "*",
	desc = "Nightride FM music streaming",
	complete = function(arg_lead, cmd_line, cursor_pos)
		local args = vim.split(cmd_line, "%s+")
		local num_args = #args - 1 -- Subtract 1 for the command itself

		if num_args == 1 then
			-- Complete first argument (subcommands)
			local commands = { "start", "stop", "toggle", "volume", "status" }
			return vim.tbl_filter(function(cmd)
				return cmd:match("^" .. arg_lead)
			end, commands)
		elseif num_args == 2 and args[2] == "start" then
			-- Complete station names for 'start' command
			local stations = require("nightride.stations")
			local station_ids = stations.get_ids()
			return vim.tbl_filter(function(id)
				return id:match("^" .. arg_lead)
			end, station_ids)
		end

		return {}
	end,
})
