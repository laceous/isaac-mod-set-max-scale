local mod = RegisterMod('Set Max Scale', 1)
local json = require('json')
local game = Game()

-- 5-99 seem to have the same behavior on a 2560x1440 screen
mod.maxScales = { 1, 2, 3, 4, 99 }
mod.onGameStartHasRun = false
mod.allowUpdate = false
mod.global = 99

mod.state = {}
mod.state.useGlobal = true
mod.state.room1x1 = 99
mod.state.room1x2 = 4
mod.state.room2x1 = 4
mod.state.room2x2 = 3
mod.state.mother1 = 4   -- 1x1ish
mod.state.mother2 = 4   -- 1x2
mod.state.theBeast = 99 -- 1x1
mod.state.menu = 99
mod.state.enableKeyboard = true
mod.state.preferFullscreenToggle = false

function mod:onGameStart()
  mod:loadSaveData()
  
  mod.onGameStartHasRun = true
  mod:onNewRoom()
end

function mod:onGameExit()
  mod:save()
  mod.onGameStartHasRun = false
  
  -- set the menu scale when exiting back to the menu
  -- this doesn't work when exiting the game while in-game
  if not mod.state.useGlobal then
    mod:update(mod.state.menu)
  end
end

function mod:onNewRoom()
  if not mod.onGameStartHasRun then
    return
  end
  
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
    mod.allowUpdate = not mod.state.useGlobal and mod:isMother()
  end
end

-- check the keyboard every frame
-- putting this in onUpdate will miss keypresses sometimes
-- this should go up or down based on the current room scale rather than the value from whichever room size (which is different than what we do for mod config menu)
function mod:onRender()
  if not mod.state.enableKeyboard then
    return
  end
  
  if game:IsPaused() then
    return
  end
  
  local keyboard = 0 -- keyboard seems to always be at index zero, even if you have multiple keyboards plugged in, controllers start at 1
  
  -- shift + , = <
  if (Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, keyboard) or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, keyboard)) and Input.IsButtonTriggered(Keyboard.KEY_COMMA, keyboard) then
    local i = mod:getMaxScalesIndex(mod:getSnappedMaxScale())
    local val = i == 1 and mod.maxScales[#mod.maxScales] or mod.maxScales[i-1]
    
    if mod.state.useGlobal then
      mod.global = val
    elseif mod:isMother() then
      mod.state[mod:getMotherState()] = val
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
    elseif mod:isMother() then
      mod.state[mod:getMotherState()] = val
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
      for _, v in ipairs({ 'useGlobal', 'enableKeyboard', 'preferFullscreenToggle' }) do
        if type(state[v]) == 'boolean' then
          mod.state[v] = state[v]
        end
      end
      for _, v in ipairs({ 'room1x1', 'room1x2', 'room2x1', 'room2x2', 'mother1', 'mother2', 'theBeast', 'menu' }) do
        if math.type(state[v]) == 'integer' and mod:getMaxScalesIndex(state[v]) >= 1 then
          mod.state[v] = state[v]
        end
      end
    end
  end
end

function mod:save()
  mod:SaveData(json.encode(mod.state))
end

function mod:update(override)
  local maxScale
  if math.type(override) == 'integer' and mod:getMaxScalesIndex(override) >= 1 then
    maxScale = override
  elseif mod.state.useGlobal then
    maxScale = mod.global
  elseif mod:isMother() then
    maxScale = mod.state[mod:getMotherState()]
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
    mod:triggerWindowResize()
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

-- mother phase 1 has GRID_WALL @ 151-163, 166-178, 181-193, 196-208, 211-223
function mod:getMotherState()
  local room = game:GetRoom()
  
  local gridEntity = room:GetGridEntity(151)
  if gridEntity and gridEntity:GetType() == GridEntityType.GRID_WALL then
    return 'mother1'
  end
  
  return 'mother2'
end

function mod:isMother()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  
  if StageAPI and StageAPI.CurrentStage and not StageAPI.CurrentStage.NormalStage and StageAPI.CurrentStage.LevelgenStage and not StageAPI.InTestMode then
    stage = StageAPI.CurrentStage.LevelgenStage.Stage
    stageType = StageAPI.CurrentStage.LevelgenStage.StageType
  end
  
  -- ROOM_SECRET_EXIT_IDX or ROOM_DEBUG_IDX
  return not game:IsGreedMode() and
         (stage == LevelStage.STAGE4_2 or stage == LevelStage.STAGE4_1) and
         (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) and
         roomDesc.Data.Shape == RoomShape.ROOMSHAPE_1x2 and
         roomDesc.Data.Type == RoomType.ROOM_BOSS and
         roomDesc.Data.StageID == 33 and -- corpse
         roomDesc.Data.Variant == 1      -- Mother
end

function mod:isTheBeast()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  
  -- ROOM_SECRET_EXIT_IDX or ROOM_DEBUG_IDX
  return not game:IsGreedMode() and
         stage == LevelStage.STAGE8 and
         roomDesc.Data.Shape == RoomShape.ROOMSHAPE_1x1 and
         roomDesc.Data.Type == RoomType.ROOM_DUNGEON and
         (
           (
             roomDesc.Data.StageID == 35 and -- home
             (
               roomDesc.Data.Variant == 666 or -- Beast Room
               roomDesc.Data.Variant == 667 or -- Famine Test
               roomDesc.Data.Variant == 668 or -- Pestilence Test
               roomDesc.Data.Variant == 669 or -- War Test
               roomDesc.Data.Variant == 670 or -- Death Test
               roomDesc.Data.Variant == 671    -- Beast Test
             )
           ) or
           roomDesc.Data.Subtype == 4
         )
end

-- this is required for the MaxScale update to actually trigger
function mod:triggerWindowResize()
  if not REPENTOGON or mod.state.preferFullscreenToggle then
    -- toggle fullscreen
    Options.Fullscreen = not Options.Fullscreen
    Options.Fullscreen = not Options.Fullscreen
  else
    Isaac.TriggerWindowResize()
  end
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
  for _, v in ipairs({ 'Global', 'Rooms', 'Misc', 'Keyboard' }) do
    ModConfigMenu.RemoveSubcategory(mod.Name, v)
  end
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
        mod:save()
        if b then
          mod.global = mod:getSnappedMaxScale()
          mod.allowUpdate = false
        else
          mod.allowUpdate = mod:isMother()
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
  for _, v in ipairs({
                       { subcategory = 'Rooms', state = 'room1x1' , prefix = '1x1: '             , info = { 'Default: 99', 'Includes skinny rooms' } },
                       { subcategory = 'Rooms', state = 'room1x2' , prefix = '1x2: '             , info = { 'Recommended: 1-4', 'Includes skinny rooms' } },
                       { subcategory = 'Rooms', state = 'room2x1' , prefix = '2x1: '             , info = { 'Recommended: 1-4', 'Includes skinny rooms' } },
                       { subcategory = 'Rooms', state = 'room2x2' , prefix = '2x2: '             , info = { 'Recommended: 1-4', 'Includes L shaped rooms' } },
                       { subcategory = 'Misc' , state = 'mother1' , prefix = 'Mother 1st phase: ', info = { 'Default: 4', 'This is a special slightly larger than 1x1 room' } },
                       { subcategory = 'Misc' , state = 'mother2' , prefix = 'Mother 2nd phase: ', info = { 'Default: 4', 'This is a special 1x2 room' } },
                       { subcategory = 'Misc' , state = 'theBeast', prefix = 'The Beast: '       , info = { 'Default: 99', 'This is a special 1x1 room' } },
                       { subcategory = 'Misc' , state = 'menu'    , prefix = 'Menu: '            , info = { 'Default: 99' } }
                    })
  do
    ModConfigMenu.AddSetting(
      mod.Name,
      v.subcategory,
      {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
          return mod:getMaxScalesIndex(mod.state[v.state])
        end,
        Minimum = 1,
        Maximum = #mod.maxScales,
        Display = function()
          return v.prefix .. (mod.state.useGlobal and '(global)' or mod.state[v.state])
        end,
        OnChange = function(n)
          if not mod.state.useGlobal then
            mod.state[v.state] = mod.maxScales[n]
            mod:save()
            mod:update()
          end
        end,
        Info = v.info
      }
    )
  end
  for _, value in ipairs({ 'Global', 'Rooms', 'Misc' }) do
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, '1-4 and 99 are available to select')
    ModConfigMenu.AddText(mod.Name, value, '5-99 appear to have the same behavior')
    ModConfigMenu.AddSpace(mod.Name, value)
    ModConfigMenu.AddText(mod.Name, value, 'This is equivalent to setting')
    ModConfigMenu.AddText(mod.Name, value, 'MaxScale in options.ini')
  end
  for i, v in ipairs({
                      { state = 'preferFullscreenToggle', displayOn = 'Prefer fullscreen toggle', displayOff = 'Do not prefer fullscreen toggle', info = { 'Do you want to continue toggling', 'fullscreen with Repentogon?' } },
                      { state = 'enableKeyboard'        , displayOn = 'Keyboard enabled'        , displayOff = 'Keyboard disabled'              , info = { 'Enable or disable keyboard controls' } }
                    })
  do
    if i ~= 1 then
      ModConfigMenu.AddSpace(mod.Name, 'Settings')
    end
    ModConfigMenu.AddSetting(
      mod.Name,
      'Settings',
      {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
          return mod.state[v.state]
        end,
        Display = function()
          return mod.state[v.state] and v.displayOn or v.displayOff
        end,
        OnChange = function(b)
          mod.state[v.state] = b
          mod:save()
        end,
        Info = v.info
      }
    )
  end
  ModConfigMenu.AddSpace(mod.Name, 'Settings')
  ModConfigMenu.AddText(mod.Name, 'Settings', 'Cycle through the')
  ModConfigMenu.AddText(mod.Name, 'Settings', 'available options with')
  ModConfigMenu.AddSpace(mod.Name, 'Settings')
  ModConfigMenu.AddText(mod.Name, 'Settings',      '<      or      >')
  ModConfigMenu.AddText(mod.Name, 'Settings', '(shift + ,) or (shift + .)')
end
-- end ModConfigMenu --

-- set the menu scale when starting up since this may have failed on exit
mod:loadSaveData() -- defaults to 1st save slot
if not mod.state.useGlobal then
  mod:update(mod.state.menu)
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)

if ModConfigMenu then
  mod:setupModConfigMenu()
end