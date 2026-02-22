local M = {}

---Show station selection menu
function M.show_station_selector()
  local stations = require('nightride.stations')
  local player = require('nightride.player')
  local station_list = stations.get_all()
  
  -- Check if snacks.nvim picker is available
  local has_snacks, snacks = pcall(require, 'snacks')
  
  if has_snacks and snacks.picker then
    -- Use snacks.nvim picker for enhanced UI
    snacks.picker({
      title = 'Nightride FM',
      finder = function()
        local items = {}
        for i, station in ipairs(station_list) do
          items[#items + 1] = {
            idx = i,
            score = 0,
            text = station.name .. ' ' .. station.description,
            station = station,
          }
        end
        return items
      end,
      format = function(item)
        return {
          { item.station.name, 'Special' },
          { ' - ', 'Comment' },
          { item.station.description, 'Normal' },
        }
      end,
      actions = {
        confirm = function(picker, item)
          picker:close()
          if not item or not item.station then
            return
          end

          local selected_station = item.station
          vim.schedule(function()
            local success = player.start(selected_station.id, selected_station.url)
            if success then
              vim.notify(string.format('Now playing: %s', selected_station.name), vim.log.levels.INFO)
            else
              vim.notify(string.format('Failed to start: %s', selected_station.name), vim.log.levels.ERROR)
            end
          end)
        end,
      },
    })
  else
    -- Fallback to vim.ui.select
    local display_names = stations.get_display_names()
    
    vim.ui.select(display_names, {
      prompt = 'Select Nightride Station:',
      format_item = function(item)
        return item
      end,
    }, function(choice)
      if not choice then
        return -- User cancelled
      end
      
      local selected_station = stations.get_by_display_name(choice)
      if not selected_station then
        vim.notify('Invalid station selection', vim.log.levels.ERROR)
        return
      end
      
      -- Start playing the selected station
      local success = player.start(selected_station.id, selected_station.url)
      if success then
        vim.notify(string.format('Now playing: %s', selected_station.name), vim.log.levels.INFO)
      else
        vim.notify(string.format('Failed to start: %s', selected_station.name), vim.log.levels.ERROR)
      end
    end)
  end
end

---Initialize UI components
function M.setup()
  -- UI setup complete - no statusline integration
end

---Show current status information
function M.show_status()
  local player = require('nightride.player')
  local stations = require('nightride.stations')
  local state = player.get_state()
  
  if not state.is_playing then
    vim.notify('Nightride: Not playing', vim.log.levels.INFO)
    return
  end
  
  local station = stations.get_by_id(state.current_station)
  local station_name = station and station.name or 'Unknown Station'
  local station_desc = station and station.description or ''
  
  local message = string.format(
    'Nightride: %s\n%s\nVolume: %d%%\nPlayer: %s',
    station_name,
    station_desc,
    state.volume,
    state.player_cmd or 'Unknown'
  )
  
  vim.notify(message, vim.log.levels.INFO)
end

return M