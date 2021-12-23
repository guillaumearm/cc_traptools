local FUEL_THRESHOLD = 10000;
local NB_TREE_BEFORE_REFUEL = 10;

local fuelLevel = tstorage.logInternalFuel();

if fuelLevel < 1 then
  error('Not enough fuel');
end

local function turtleNeedFuel()
  return turtle.getFuelLevel() < FUEL_THRESHOLD;
end

local function suckChest()
  local inv = peripheral.wrap('front');

  if not inv or not inv.getItemDetail then
    return false, 'no inventory found';
  end

  tstorage.suckAll();

  -- 1. take all stick as fuel
  tstorage.refuelByName('minecraft:stick');

  -- 2. take logs if not fully refueled;
  tstorage.refuelByTag('minecraft:logs_that_burn', FUEL_THRESHOLD);

  -- 3. take sapling if not fully refueled;
  tstorage.refuelByTag('minecraft:saplings', FUEL_THRESHOLD);

  return true;
end

local goToOutputChest = {'up', {'back', 6}, 'right', {'forward', 3}, 'down'};
local goToSaplingChest = {'left', 'forward', 'right', {'forward', 3}, 'up'};
local goToStorageChest = {'up', {'back', 4}, 'right', {'forward', 2}};
local goToRedstone = {{'back', 3}, 'right', {'forward', 6}, 'left', 'forward', 'right'};

local function dropSaplings()
  if tstorage.findItemSlotByTag('minecraft:saplings') then
    tpath.exec(goToSaplingChest);

    local ok, err = tstorage.dropByTag('minecraft:saplings')

    if not ok and err == 'No space for items' then
      tstorage.refuelByTag('minecraft:saplings');
    end

    tpath.execReverse(goToSaplingChest);
  end
end

local function dropRestItems()
  local stickSlot = tstorage.findItemSlotByName('minecraft:stick');
  local woodSlot = tstorage.findItemSlotByTag('minecraft:sapling', 'minecraft:planks', 'minecraft:logs_that_burn')
  if stickSlot or woodSlot then
    tpath.exec(goToStorageChest);
    tstorage.dropDownAll();
    tpath.execReverse(goToStorageChest);
  end
end

local treeCounter = 0;
local totalTreeCounter = 0;
local firstLaunch = true;

while true do
  if firstLaunch or treeCounter >= NB_TREE_BEFORE_REFUEL or turtleNeedFuel() then
    firstLaunch = false;
    treeCounter = 0;
    tpath.exec(goToOutputChest);

    local ok, err = suckChest();

    tpath.execReverse(goToOutputChest);

    if not ok then
      error(err);
    end
  end

  dropSaplings()
  dropRestItems();

  local boneMealSlot = tstorage.findItemSlotByName('minecraft:bone_meal');
  if boneMealSlot then
    turtle.select(boneMealSlot);
    turtle.place();
  end

  turtle.forward();
  local ok, res = turtle.inspect();
  turtle.back();

  if ok and res and res.tags and res.tags['minecraft:logs'] == true then
    treeCounter = treeCounter + 1;
    totalTreeCounter = totalTreeCounter + 1;

    print('=> gather tree number ', totalTreeCounter);

    tpath.exec(goToRedstone);
    redstone.setOutput('front', true);
    os.sleep(0.5);
    redstone.setOutput('front', false);
    tpath.execReverse(goToRedstone);
  end

  if tstorage.findItemSlotByName('minecraft:bone_meal') then
    os.sleep(1);
  else
    os.sleep(20);
  end
end
