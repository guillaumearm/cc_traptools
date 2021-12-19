-- Check cli arguments
local filename = ...;

local PICKAXE_TOOL = "minecraft:diamond_pickaxe";
local AXE_TOOL = "minecraft:diamond_axe";
local SHOVEL_TOOL = "minecraft:shovel_tool";

local ALL_TOOLS = {PICKAXE_TOOL, AXE_TOOL, SHOVEL_TOOL};

local function printUsage()
  print('usage: trecord <filename>');
end

if not filename then
  printUsage();
  return;
end

local filepath = shell.resolve(filename);

if fs.exists(filepath) then
  if fs.isDir(filepath) then
    error('"' .. filepath .. '" is a directory!')
  else
    error('the file "' .. filepath .. '" already exists!')
  end
end

-- Check if is a turtle
if not turtle then
  error('should be run on a turtle!')
end

-- Utils

local function getAutomata()
  local left = peripheral.wrap('left');

  if left and left.chargeTurtle then
    return left;
  end

  local right = peripheral.wrap('right');

  if right and right.chargeTurtle then
    return right;
  end
end

-- Main implementation
local shiftCode = 340;
local ctrlCode = 341;

local function main(savePath)
  -- Print initial turtle fuel

  print('=> Initial turtle loaded fuel: ', turtle.getFuelLevel(), '/', turtle.getFuelLimit());

  local el = eventloop.create();
  local actions = {};
  local selectedSlot = turtle.getSelectedSlot();

  local function moveSlot(x)
    selectedSlot = ((selectedSlot + x - 1) % 16) + 1;
    turtle.select(selectedSlot);
  end

  local function save()
    local file = fs.open(savePath, 'w');
    local data = textutils.serialize(actions);
    file.write(data);
    file.close();
  end

  local function create(type, payload)
    if payload then
      return {
        type = type,
        payload = payload
      }
    else
      return {
        type = type
      }
    end
  end

  local function push(action)
    table.insert(actions, action);
  end

  local function exec(action, fn, ...)
    local ok, res = fn(...);

    if not ok then
      print('Error: ', res)
    else
      push(action)
    end
  end

  local function getItemId()
    local item = turtle.getItemDetail(nil, true)
    if item then
      return item.name .. '|||' .. item.displayName;
    end
  end

  local function refuel()
    local neededFuel = turtle.getFuelLimit() - turtle.getFuelLevel();

    if not neededFuel then
      print('Turtle is aslready fully refueled.');
      return;
    end

    local ok, res = turtle.refuel(64);

    if ok then
      print('=> ', turtle.getFuelLevel(), '/', turtle.getFuelLimit());
    else
      print('Refuel error: ', res);
    end
  end

  local function findItemSlot(toolName)
    for slotId = 1, 16, 1 do
      local item = turtle.getItemDetail(slotId);

      if item and item.name == toolName then
        return slotId;
      end
    end

    return nil;
  end

  local function findEmptySlot()
    for slotId = 1, 16, 1 do
      local itemCount = turtle.getItemCount(slotId);

      if itemCount == 0 then
        return slotId;
      end
    end

    return nil;
  end

  local function reverseAction()
    local lastAction = actions[#actions];
    if not lastAction then
      print('Error: Action queue is empty.')
      return;
    end

    if lastAction.type == 'use' then
      print('Error: last action "use" cannot be reversed')
    end

    local function tryDig(digFn, suckFn)
      local equiped = false;
      local lastEquipedErr = nil;
      local digged = false;
      local lastDigErr = nil;

      for _, toolName in ipairs(ALL_TOOLS) do
        local slot = findItemSlot(toolName);

        if slot then
          turtle.select(slot);
          local ok, res = turtle.equipLeft();
          if ok then
            equiped = true;

            digged, lastDigErr = digFn();
            if digged then
              suckFn();
              break
            end
          else
            lastEquipedErr = res;
          end
        end
      end

      if equiped then
        local slot = findEmptySlot()
        if slot then
          turtle.select(slot)
          turtle.equipLeft();
        else
          print('Warning: No valid slot found to depose tool!');
          -- TODO: wait for an empty slot
        end
      else
        lastEquipedErr = lastEquipedErr or 'no valid tool provided!';
        return false, lastEquipedErr;
      end

      return digged, lastDigErr;
    end

    local function reverseLastAction(fn)
      local ok, res = fn();

      if ok then
        table.remove(actions, #actions);
      else
        print('Error:', res)
      end

    end

    if lastAction.type == 'forward' then
      reverseLastAction(function()
        return turtle.back()
      end)
    elseif lastAction.type == 'back' then
      reverseLastAction(function()
        return turtle.forward()
      end)
    elseif lastAction.type == 'up' then
      reverseLastAction(function()
        return turtle.down()
      end)
    elseif lastAction.type == 'down' then
      reverseLastAction(function()
        return turtle.up()
      end)
    elseif lastAction.type == 'left' then
      reverseLastAction(function()
        return turtle.turnRight()
      end)
    elseif lastAction.type == 'right' then
      reverseLastAction(function()
        return turtle.turnLeft()
      end)
    elseif lastAction.type == 'place' then
      reverseLastAction(function()
        return tryDig(turtle.dig, turtle.suck);
      end)
    elseif lastAction.type == 'placeUp' then
      reverseLastAction(function()
        return tryDig(turtle.digUp, turtle.suckUp);
      end)
    elseif lastAction.type == 'placeDown' then
      reverseLastAction(function()
        return tryDig(turtle.digDown, turtle.suckDown);
      end)
    end
  end

  local ctrlPressed = false;
  local loopStoppedByUser = false;

  el.register('key_up', function(k)
    if k == ctrlCode then
      ctrlPressed = false;
    end
  end)

  el.register('key', function(k)
    if k == ctrlCode then
      ctrlPressed = true;
    elseif ctrlPressed and k == keys.q then
      -- Quit
      loopStoppedByUser = true;
      el.stopLoop();
    elseif ctrlPressed and k == keys.z then
      -- Reverse last action
      reverseAction();
    elseif k == keys.r then
      -- Refuel the turtle (this is not recorded)
      refuel();
    elseif k == keys.w then
      exec(create('forward'), turtle.forward);
    elseif k == keys.s then
      exec(create('back'), turtle.back);
    elseif k == keys.d then
      exec(create('right'), turtle.turnRight);
      exec(create('forward'), turtle.forward);
      exec(create('left'), turtle.turnLeft);
    elseif k == keys.a then
      exec(create('left'), turtle.turnLeft);
      exec(create('forward'), turtle.forward);
      exec(create('right'), turtle.turnRight);
    elseif k == keys.e then
      exec(create('right'), turtle.turnRight);
    elseif k == keys.q then
      exec(create('left'), turtle.turnLeft);
    elseif k == keys.space then
      exec(create('up'), turtle.up);
    elseif k == shiftCode then
      exec(create('down'), turtle.down);
    elseif k == keys.right then
      moveSlot(1);
    elseif k == keys.left then
      moveSlot(-1);
    elseif k == keys.down then
      moveSlot(4);
    elseif k == keys.up then
      moveSlot(-4);
    elseif k == keys.enter then
      exec(create('place', getItemId()), turtle.place);
    elseif k == keys.pageUp then
      exec(create('placeUp', getItemId()), turtle.placeUp);
    elseif k == keys.pageDown then
      exec(create('placeDown', getItemId()), turtle.placeDown);
    elseif k == keys.u then
      -- Use (useOnBlock with automata)
      local t = getAutomata();
      if not t then
        print('Warning: no automata found');
      else
        exec(create('use', getItemId()), t.useOnBlock);
      end
    end
  end)

  el.startLoop();

  if not loopStoppedByUser then
    print('Cancelled!');
    return;
  elseif #actions == 0 then
    print('Warning: no actions recorded.');
    return;
  else
    save();
  end
end

main(filepath);
