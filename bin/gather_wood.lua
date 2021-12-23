local FUEL_THRESHOLD = 10000;
local NB_TREE_BEFORE_REFUEL = 10;

local fuelLevel = tstorage.logInternalFuel();

if fuelLevel < 1 then
  error('Not enough fuel');
end

local function turtleNeedFuel()
  return turtle.getFuelLevel() < FUEL_THRESHOLD;
end

local function suckChest(side)
  local inv = peripheral.wrap(side);

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

local function left(n)
  return {'left', n}
end

local function right(n)
  return {'right', n}
end

local function forward(n)
  return {'forward', n}
end

local function back(n)
  return {'back', n}
end

local function up(n)
  return {'up', n}
end

local function down(n)
  return {'down', n}
end

local goToOutputChest = {right(1), forward(4), left(1)};
local goToSaplingChest = {left(1), forward(1), right(1), forward(3), up(1)};
local goToStorageChest = {right(2), forward(2)};
local goToRedstone = {back(2), right(1), forward(6)};

local function getFertilizerSlot()
  return tstorage.findItemSlotByName('thermal:phytogro') or tstorage.findItemSlotByName('minecraft:bone_meal');
end

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
    tstorage.dropByName('minecraft:stick');
    tstorage.dropByTag('minecraft:sapling', 'minecraft:planks', 'minecraft:logs_that_burn');
    tpath.execReverse(goToStorageChest);
  end
end

local treeCounter = 0;
local totalTreeCounter = 0;
local firstLaunch = true;

local function waitForInventory(side)
  local counter = 0;

  while true do
    local inv = peripheral.wrap(side);

    if inv and inv.getItemDetail then
      break
    elseif counter == 5 then
      print('Waiting for inventory (' .. side .. ')...');
      printed = true;
    end

    counter = counter + 1;
    os.sleep(1);
  end
end

while true do
  if firstLaunch or treeCounter >= NB_TREE_BEFORE_REFUEL or turtleNeedFuel() then
    firstLaunch = false;
    treeCounter = 0;
    tpath.exec(goToOutputChest);

    waitForInventory('front')
    local ok, err = suckChest('front');

    tpath.execReverse(goToOutputChest);

    if not ok then
      error(err);
    end
  end

  dropSaplings()
  dropRestItems();

  while true do
    local fertilizerSlot = getFertilizerSlot();
    if fertilizerSlot then
      turtle.select(fertilizerSlot);
      local ok = turtle.place();
      if not ok then
        break
      end
    else
      break
    end

    os.sleep(0.5);
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

    os.sleep(10);
  end

  if getFertilizerSlot() then
    os.sleep(2);
  else
    os.sleep(20);
  end
end
