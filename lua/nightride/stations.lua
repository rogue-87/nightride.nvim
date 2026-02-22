---@class nightride.Station
---@field id string Station identifier
---@field name string Display name
---@field description string Genre/description
---@field url string Stream URL

local M = {}

---@type nightride.Station[]
M.stations = {
  {
    id = 'nightride',
    name = 'Nightride FM',
    description = 'Synthwave / Retrowave / Outrun',
    url = 'https://nightride.fm/stream/nightride.m4a'
  },
  {
    id = 'chillsynth',
    name = 'ChillSynth FM',
    description = 'Chillsynth / Chillwave / Instrumental',
    url = 'https://nightride.fm/stream/chillsynth.m4a'
  },
  {
    id = 'datawave',
    name = 'Datawave FM',
    description = 'Glitchy Synthwave / IDM / Retro Computing',
    url = 'https://nightride.fm/stream/datawave.m4a'
  },
  {
    id = 'spacesynth',
    name = 'SpaceSynth FM',
    description = 'Spacesynth / Space Disco / Vocoder Italo',
    url = 'https://nightride.fm/stream/spacesynth.m4a'
  },
  {
    id = 'darksynth',
    name = 'DarkSynth',
    description = 'Darksynth / Cyberpunk / Synthmetal',
    url = 'https://nightride.fm/stream/darksynth.m4a'
  },
  {
    id = 'horrorsynth',
    name = 'HorrorSynth',
    description = 'Horrorsynth / Witch House',
    url = 'https://nightride.fm/stream/horrorsynth.m4a'
  },
  {
    id = 'ebsm',
    name = 'EBSM',
    description = 'EBSM / Industrial / Clubbing',
    url = 'https://nightride.fm/stream/ebsm.m4a'
  }
}

---Get all available stations
---@return nightride.Station[]
function M.get_all()
  return M.stations
end

---Get station by ID
---@param id string Station identifier
---@return nightride.Station|nil
function M.get_by_id(id)
  for _, station in ipairs(M.stations) do
    if station.id == id then
      return station
    end
  end
  return nil
end

---Get station IDs for tab completion
---@return string[]
function M.get_ids()
  local ids = {}
  for _, station in ipairs(M.stations) do
    table.insert(ids, station.id)
  end
  return ids
end

---Get formatted station list for display
---@return string[]
function M.get_display_names()
  local names = {}
  for _, station in ipairs(M.stations) do
    table.insert(names, string.format('%s - %s', station.name, station.description))
  end
  return names
end

---Get station from display name
---@param display_name string Display name
---@return nightride.Station|nil
function M.get_by_display_name(display_name)
  for _, station in ipairs(M.stations) do
    local expected = string.format('%s - %s', station.name, station.description)
    if expected == display_name then
      return station
    end
  end
  return nil
end

---Validate if station ID exists
---@param id string Station identifier
---@return boolean
function M.is_valid_id(id)
  return M.get_by_id(id) ~= nil
end

return M