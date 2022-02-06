local mod = RegisterMod('Set Max Scale', 1)
local json = require('json')
local game = Game()

-- 5-99 seem to have the same behavior
mod.maxScales = { 1, 2, 3, 4, 99 }
mod.allowUpdate = false
mod.global = 99

mod.state = {}
mod.state.useGlobal = true
mod.state.room1x1 = 99
mod.state.room1x2 = 4
mod.state.room2x1 = 4
mod.state.room2x2 = 3
mod.state.theBeast = 99
mod.state.menu = 99
mod.state.enableKeyboard = true

function mod:onGameExit()
  mod:SaveData(json.encode(mod.state))
  
  -- set the menu scale when exiting back to the menu
  -- this doesn't work when exiting the game while in-game
  if not mod.state.useGlobal then
    mod:update(mod.state.menu)
  end
end

function mod:onNewRoom()
  if not mod.state.useGlobal and mod:isTheBeast() then
    mod:update() -- the beast looks better triggering it from here
    mod.allowUpdate = false
  else
    mod.allowUpdate = not mod.state.useGlobal
  end
end

function mod:onUpdate()
  if mod.allowUpdate then
    mod:update() -- doing this here rather than in onNewRoom lets us see the room transition animation
    mod.allowUpdate = false
  end
end

-- check the keyboard every frame
-- putting this in onUpdate will miss keypresses sometimes
-- this should go up or down based on the current room scale rather than the value from whichever room size (which is different than what we do for mod config menu)
function mod:onRender()
  if not mod.state.enableKeyboard then
    return
  end
  
  local keyboard = 0 -- keyboard seems to always be at index zero, even if you have multiple keyboards plugged in, controllers start at 1
  
  -- shift + , = <
  if (Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, keyboard) or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, keyboard)) and Input.IsButtonTriggered(Keyboard.KEY_COMMA, keyboard) then
    local i = mod:getMaxScalesIndex(mod:getSnappedMaxScale())
    local val = i == 1 and mod.maxScales[#mod.maxScales] or mod.maxScales[i-1]
    
    if mod.state.useGlobal then
      mod.global = val
    elseif mod:isTheBeast() then
      mod.state.theBeast = val
    elseif mod:isRoom1x2() then
      mod.state.room1x2 = val
    elseif mod:isRoom2x1() then
      mod.state.room2x1 = val
    elseif mod:isRoom2x2() then
      mod.state.room2x2 = val
    else -- 1x1
      mod.state.room1x1 = val
    end
    
    mod:update()
    
  -- shift + . = >
  elseif (Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, keyboard) or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, keyboard)) and Input.IsButtonTriggered(Keyboard.KEY_PERIOD, keyboard) then
    local i = mod:getMaxScalesIndex(mod:getSnappedMaxScale())
    local val = i == #mod.maxScales and mod.maxScales[1] or mod.maxScales[i+1]
    
    if mod.state.useGlobal then
      mod.global = val
    elseif mod:isTheBeast() then
      mod.state.theBeast = val
    elseif mod:isRoom1x2() then
      mod.state.room1x2 = val
    elseif mod:isRoom2x1() then
      mod.state.room2x1 = val
    elseif mod:isRoom2x2() then
      mod.state.room2x2 = val
    else -- 1x1
      mod.state.room1x1 = val
    end
    
    mod:update()
  end
end

function mod:loadSaveData()
  if mod:HasData() then
    local _, state = pcall(json.decode, mod:LoadData()) -- deal with bad json data
    
    if type(state) == 'table' then
      if type(state.useGlobal) == 'boolean' then
        mod.state.useGlobal = state.useGlobal
      end
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
      if math.type(state.theBeast) == 'integer' and mod:getMaxScalesIndex(state.theBeast) >= 1 then
        mod.state.theBeast = state.theBeast
      end
      if math.type(state.menu) == 'integer' and mod:getMaxScalesIndex(state.menu) >= 1 then
        mod.state.menu = state.menu
      end
      if type(state.enableKeyboard) == 'boolean' then
        mod.state.enableKeyboard = state.enableKeyboard
      end
    end
  end
end

function mod:update(override)
  local maxScale
  if math.type(override) == 'integer' and mod:getMaxScalesIndex(override) >= 1 then
    maxScale = override
  elseif mod.state.useGlobal then
    maxScale = mod.global
  elseif mod:isTheBeast() then
    maxScale = mod.state.theBeast
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

function mod:isTheBeast()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  
  return level:GetStage() == LevelStage.STAGE8 and
         roomDesc.Data.Shape == RoomShape.ROOMSHAPE_1x1 and
         roomDesc.Data.Type == RoomType.ROOM_DUNGEON and
         roomDesc.Data.Variant == 666 and
         roomDesc.Data.Name == 'Beast Room'
end

-- this is required for the MaxScale update to actually trigger
-- you can also change the window size, but there doesn't seem to be a way to do that via code
function mod:toggleFullscreen()
  Options.Fullscreen = not Options.Fullscreen
  Options.Fullscreen = not Options.Fullscreen
end

-- snap MaxScale to our list of allowed maxScales
function mod:getSnappedMaxScale()
  return mod:getMaxScalesIndex(Options.MaxScale) >= 1 and Options.MaxScale or 99
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
    'Global',
    {
      Type = ModConfigMenu.OptionType.BOOLEAN,
      CurrentSetting = function()
        return mod.state.useGlobal
      end,
      Display = function()
        return 'Use ' .. (mod.state.useGlobal and 'global setting' or 'per room settings')
      end,
      OnChange = function(b)
        mod.state.useGlobal = b
        if b then
          mod.global = mod:getSnappedMaxScale()
        end
        mod:update()
      end,
      Info = { 'Use global or per room (and menu) settings' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Global',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod:getSnappedMaxScale())
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return 'Global: ' .. (mod.state.useGlobal and mod:getSnappedMaxScale() or '(per room)')
      end,
      OnChange = function(n)
        if mod.state.useGlobal then
          mod.global = mod.maxScales[n]
          mod:update()
        end
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
        return mod:getMaxScalesIndex(mod.state.room1x1)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return '1x1: ' .. (mod.state.useGlobal and '(global)' or mod.state.room1x1)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.room1x1 = mod.maxScales[n]
          mod:update()
        end
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
        return '1x2: ' .. (mod.state.useGlobal and '(global)' or mod.state.room1x2)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.room1x2 = mod.maxScales[n]
          mod:update()
        end
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
        return '2x1: ' .. (mod.state.useGlobal and '(global)' or mod.state.room2x1)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.room2x1 = mod.maxScales[n]
          mod:update()
        end
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
        return '2x2: ' .. (mod.state.useGlobal and '(global)' or mod.state.room2x2)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.room2x2 = mod.maxScales[n]
          mod:update()
        end
      end,
      Info = { 'Recommended: 1-4' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Misc',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.theBeast)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return 'The Beast: ' .. (mod.state.useGlobal and '(global)' or mod.state.theBeast)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.theBeast = mod.maxScales[n]
          mod:update()
        end
      end,
      Info = { 'Default: 99', 'This is a special 1x1 room' }
    }
  )
  ModConfigMenu.AddSetting(
    mod.Name,
    'Misc',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getMaxScalesIndex(mod.state.menu)
      end,
      Minimum = 1,
      Maximum = #mod.maxScales,
      Display = function()
        return 'Menu: ' .. (mod.state.useGlobal and '(global)' or mod.state.menu)
      end,
      OnChange = function(n)
        if not mod.state.useGlobal then
          mod.state.menu = mod.maxScales[n]
        end
      end,
      Info = { 'Default: 99' }
    }
  )
  for _, value in ipairs({ 'Global', 'Rooms', 'Misc' }) do
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, '1-4 and 99 are available to select')
    ModConfigMenu.AddText(mod.Name, value, '5-99 appear to have the same behavior')
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, 'This is equivalent to setting')
    ModConfigMenu.AddText(mod.Name, value, 'MaxScale in options.ini')
  end
  ModConfigMenu.AddSetting(
    mod.Name,
    'Keyboard',
    {
      Type = ModConfigMenu.OptionType.BOOLEAN,
      CurrentSetting = function()
        return mod.state.enableKeyboard
      end,
      Display = function()
        return 'Keyboard ' .. (mod.state.enableKeyboard and 'enabled' or 'disabled')
      end,
      OnChange = function(b)
        mod.state.enableKeyboard = b
      end,
      Info = { 'Enable or disable keyboard controls' }
    }
  )
  ModConfigMenu.AddSpace(mod.Name, 'Keyboard')
  ModConfigMenu.AddText(mod.Name, 'Keyboard', 'Cycle through the')
  ModConfigMenu.AddText(mod.Name, 'Keyboard', 'available options with')
  ModConfigMenu.AddSpace(mod.Name, 'Keyboard')
  ModConfigMenu.AddText(mod.Name, 'Keyboard',      '<      or      >')
  ModConfigMenu.AddText(mod.Name, 'Keyboard', '(shift + ,) or (shift + .)')
end
-- end ModConfigMenu --

-- set the menu scale when starting up since this may have failed on exit
mod:loadSaveData()
if not mod.state.useGlobal then
  mod:update(mod.state.menu)
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)

if ModConfigMenu then
  mod:setupModConfigMenu()
end