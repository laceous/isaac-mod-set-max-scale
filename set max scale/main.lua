local mod = RegisterMod('Set Max Scale', 1)
local json = require('json')
local game = Game()

-- 5-99 seem to have the same behavior
mod.maxScales = { 1, 2, 3, 4, 99 }
mod.allowUpdate = false

mod.state = {}
mod.state.room1x1 = 99
mod.state.room1x2 = 4
mod.state.room2x1 = 4
mod.state.room2x2 = 3
mod.state.menu = 99

function mod:onGameExit()
  mod:SaveData(json.encode(mod.state))
  
  -- set the menu scale when exiting back to the menu
  -- this doesn't work when exiting the game while in-game
  mod:update(mod.state.menu)
end

function mod:onNewRoom()
  mod.allowUpdate = true
end

function mod:onUpdate()
  if mod.allowUpdate then
    mod:update() -- doing this here rather than in onNewRoom lets us see the room transition animation
    mod.allowUpdate = false
  end
end

function mod:loadSaveData()
  if mod:HasData() then
    local state = json.decode(mod:LoadData())
    
    if type(state) == 'table' then
      if math.type(state.room1x1) == 'integer' and mod:getMaxScalesIndex(state.room1x1) >= 1 then
        mod.state.room1x1 = state.room1x1
      end
      if math.type(state.room1x2) == 'integer' and mod:getMaxScalesIndex(state.room1x2) >= 1 then
        mod.state.room1x2 = state.room1x2
      end
      if math.type(state.room2x1) == 'integer' and mod:getMaxScalesIndex(state.room2x1) >= 1 then
        mod.state.room2x1 = state.room2x1
      end
      if math.type(state.room2x2) == 'integer' and mod:getMaxScalesIndex(state.room2x2) >= 1 then
        mod.state.room2x2 = state.room2x2
      end
      if math.type(state.menu) == 'integer' and mod:getMaxScalesIndex(state.menu) >= 1 then
        mod.state.menu = state.menu
      end
    end
  end
end

function mod:update(override)
  local maxScale
  if math.type(override) == 'integer' and mod:getMaxScalesIndex(override) >= 1 then
    maxScale = override
  elseif mod:isRoom1x2() then
    maxScale = mod.state.room1x2
  elseif mod:isRoom2x1() then
    maxScale = mod.state.room2x1
  elseif mod:isRoom2x2() then
    maxScale = mod.state.room2x2
  else -- 1x1
    maxScale = mod.state.room1x1
  end
  
  -- if another mod sets MaxScale without triggering it then this could be in a bad state
  if Options.MaxScale ~= maxScale then
    Options.MaxScale = maxScale
    mod:toggleFullscreen() -- hack
  end
end

function mod:isRoom1x2()
  -- game:GetLevel():GetCurrentRoom():GetRoomShape()
  -- game:GetLevel():GetCurrentRoomDesc().Data.Shape
  local shape = game:GetRoom():GetRoomShape()
  return shape == RoomShape.ROOMSHAPE_1x2 or
         shape == RoomShape.ROOMSHAPE_IIV
end

function mod:isRoom2x1()
  local shape = game:GetRoom():GetRoomShape()
  return shape == RoomShape.ROOMSHAPE_2x1 or
         shape == RoomShape.ROOMSHAPE_IIH
end

function mod:isRoom2x2()
  local shape = game:GetRoom():GetRoomShape()
  return shape == RoomShape.ROOMSHAPE_2x2 or
         shape == RoomShape.ROOMSHAPE_LTL or
         shape == RoomShape.ROOMSHAPE_LTR or
         shape == RoomShape.ROOMSHAPE_LBL or
         shape == RoomShape.ROOMSHAPE_LBR
end

-- this is required for the MaxScale update to actually trigger
-- you can also change the window size, but there doesn't seem to be a way to do that via code
function mod:toggleFullscreen()
  Options.Fullscreen = not Options.Fullscreen
  Options.Fullscreen = not Options.Fullscreen
end

function mod:getMaxScalesIndex(val)
  for i, value in ipairs(mod.maxScales) do
    if val == value then
      return i
    end
  end
  return -1
end

-- start ModConfigMenu --
function mod:setupModConfigMenu()
  ModConfigMenu.AddSetting(
    mod.Name,
    'Rooms',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.room1x1)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return '1x1: ' .. mod.state.room1x1
      end,
      OnChange = function(n)
        mod.state.room1x1 = mod.maxScales[n]
        mod:update()
      end,
      Info = { 'Default: 99' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Rooms',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.room1x2)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return '1x2: ' .. mod.state.room1x2
      end,
      OnChange = function(n)
        mod.state.room1x2 = mod.maxScales[n]
        mod:update()
      end,
      Info = { 'Recommended: 1-4' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Rooms',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.room2x1)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return '2x1: ' .. mod.state.room2x1
      end,
      OnChange = function(n)
        mod.state.room2x1 = mod.maxScales[n]
        mod:update()
      end,
      Info = { 'Recommended: 1-4' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Rooms',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.room2x2)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return '2x2: ' .. mod.state.room2x2
      end,
      OnChange = function(n)
        mod.state.room2x2 = mod.maxScales[n]
        mod:update()
      end,
      Info = { 'Recommended: 1-4' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Menu',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.menu)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return 'Menu: ' .. mod.state.menu
      end,
      OnChange = function(n)
        mod.state.menu = mod.maxScales[n]
      end,
      Info = { 'Default: 99' }
    }
  )
  for _, value in ipairs({ 'Rooms', 'Menu' }) do
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, '1-4 and 99 are available to select')
    ModConfigMenu.AddText(mod.Name, value, '5-99 appear to have the same behavior')
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, 'This is equivalent to setting')
    ModConfigMenu.AddText(mod.Name, value, 'MaxScale in options.ini')
  end
end
-- end ModConfigMenu --

-- set the menu scale when starting up since this may have failed on exit
mod:loadSaveData()
mod:update(mod.state.menu)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)

if ModConfigMenu then
  mod:setupModConfigMenu()
end