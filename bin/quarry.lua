local SIZE_X = 3;
local SIZE_Y = 3;

local PICKAXE_TOOL = "minecraft:diamond_pickaxe";
local SHOVEL_TOOL = "minecraft:diamond_shovel";
local AXE_TOOL = "minecraft:diamond_axe";

local COAL_ITEM = 'minecraft:coal';

local function getItemName(slot)
  local item = turtle.getItemDetail(slot);

  if item then
    return item.name;
  end
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

local function equipTurtle(slot)
  local initialSlot = turtle.getSelectedSlot();
  slot = slot or initialSlot;

  turtle.select(slot);
  local ok, res = turtle.equipLeft();

  if initialSlot ~= slot then
    turtle.select(initialSlot)
  end

  return ok, res;
end

local function unequipCurrentItem()
  local slot = findEmptySlot();

  if not slot then
    error('no empty slot available!')
  end
  return equipTurtle(slot)
end

local function getSlotForTools()
  local pickaxeSlot = nil;
  local shovelSlot = nil;
  local axeSlot = nil; -- unused

  for slot = 1, 16, 1 do
    local itemName = getItemName(slot);
    if itemName == PICKAXE_TOOL then
      pickaxeSlot = slot;
    elseif itemName == SHOVEL_TOOL then
      shovelSlot = slot;
    elseif itemName == AXE_TOOL then
      axeSlot = slot;
    end
  end

  return pickaxeSlot, shovelSlot, axeSlot;
end

local function createSwitchTool(slotTool)
  return function()
    local itemName = getItemName(slotTool);
    if itemName == PICKAXE_TOOL or itemName == SHOVEL_TOOL then
      return equipTurtle(slotTool);
    end
    return false, 'Unable to switch tool!';
  end
end

local function createDig(slotTool, digFn, detectFn)
  local _switchTool = createSwitchTool(slotTool);

  return function()
    if not detectFn() then
      return true;
    end

    return digFn();
  end
end

local function moveN(n, moveFn)
  local counter = 0;

  while counter < n do
    local ok, res = moveFn();

    if ok then
      counter = counter + 1;
    else
      print('turtle movement blocked: ', res);
      os.sleep(1)
    end
  end
end

local function getNbFreeSlot()
  local counter = 0;

  for slot = 1, 16, 1 do
    if not turtle.getItemDetail(slot) then
      counter = counter + 1;
    end
  end

  return counter;
end

local function quarry(slotTool)
  local digDown = createDig(slotTool, turtle.digDown, turtle.detectDown);
  local dig = createDig(slotTool, turtle.dig, turtle.detect);

  local currentLayer = 1;

  while true do
    -- check if inventory is almost full
    if getNbFreeSlot() < 2 then
      return 'inventory_full', currentLayer;
    end

    for y = 1, SIZE_Y, 1 do
      for x = 1, SIZE_X, 1 do

        digDown();

        if x < SIZE_X then
          -- regular move
          local ok = turtle.forward();

          -- handle randomium ore
          if not ok then
            dig();
            ok = turtle.forward();
          end

          if not ok then
            print('Turtle blocked !');
            return 'blocked', currentLayer;
          end
        end
      end

      if y < SIZE_Y then
        if y % 2 == 0 then
          turtle.turnLeft();
        else
          turtle.turnRight();
        end

        local ok = turtle.forward();

        -- handle randomium ore
        if not ok then
          dig();
          ok = turtle.forward();
        end

        if not ok then
          print('Turtle blocked !');
          return 'blocked', currentLayer;
        end

        if y % 2 == 0 then
          turtle.turnLeft();
        else
          turtle.turnRight();
        end
      end
    end

    if SIZE_Y % 2 == 0 then
      turtle.turnRight();
      moveN(SIZE_Y - 1, turtle.forward);
      turtle.turnRight();
    else
      turtle.turnLeft();
      moveN(SIZE_Y - 1, turtle.forward);

      turtle.turnLeft();
      moveN(SIZE_X - 1, turtle.forward);

      turtle.turnLeft();
      turtle.turnLeft();
    end

    local ok = turtle.down();

    if not ok then
      print('Turtle blocked !');
      return 'blocked', currentLayer;
    end

    currentLayer = currentLayer + 1;
  end
end

local function waitForInventory()
  local side = 'front';
  local messagePrinted = false;

  while true do
    local p = peripheral.wrap(side);
    local _, type = peripheral.getType(side);
    if p and type == 'inventory' then
      return p;
    elseif p then
      print('Error: bad peripheral type: ', type);
    end
    if not messagePrinted then
      messagePrinted = true;
      print('Wait for inventory...')
    end
    os.sleep(5)
  end
end

local function cleanupInventory(toolSlot)
  local initialSelectedSlot = turtle.getSelectedSlot();

  for slotId = 1, 16, 1 do
    if slotId ~= toolSlot then
      turtle.select(slotId)

      if getItemName(slotId) == COAL_ITEM then
        turtle.refuel();
      end

      local ok, res = turtle.drop();

      if not ok and res ~= 'No items to drop' then
        turtle.select(initialSelectedSlot);
        return false, 'Cannot drop item in inventory: ' .. res;
      end

    end
  end

  turtle.select(initialSelectedSlot);
  return true;
end

local function main()
  -- Print initial turtle fuel
  print('=> Initial turtle loaded fuel: ', turtle.getFuelLevel(), '/', turtle.getFuelLimit());

  unequipCurrentItem();
  local pickaxeSlot = getSlotForTools();

  if not pickaxeSlot then
    error('missing diamond pickaxe!');
  end

  turtle.turnLeft();
  turtle.turnLeft();
  waitForInventory();
  turtle.turnLeft();
  turtle.turnLeft();

  equipTurtle(pickaxeSlot);

  local mainToolSlot = pickaxeSlot;

  -- DIG HERE
  print('Starting quarry ', SIZE_X, '*', SIZE_Y)

  while true do
    local msg, layer = quarry(mainToolSlot);

    -- inventory is full
    if msg == 'inventory_full' then
      local nbLayerToMove = layer - 1;

      -- BACK TO HOME
      moveN(nbLayerToMove, turtle.up);

      -- TODO: EMPTY TURTLE INVENTORY (except for mainToolSlot)
      turtle.turnLeft();
      turtle.turnLeft();
      waitForInventory();

      while true do
        local ok, res = cleanupInventory(mainToolSlot);
        if ok then
          break
        end
        print(res);
        os.sleep(5);
      end

      turtle.turnLeft();
      turtle.turnLeft();

      -- BACK TO LAYER
      moveN(nbLayerToMove, turtle.down);
    elseif msg == 'blocked' then
      local nbLayerToMove = layer - 1;
      moveN(nbLayerToMove + 1, turtle.up);
      print('=> End of Quarry.')
      return;
    else
      -- error quarry
      local err = layer;
      error(msg .. ': ' .. err);
    end
  end
end

main();
