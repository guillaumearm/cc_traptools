-- This is a little turtle program to gather resources inside a greenhouse (using botany pot)
local ENERGY_THRESHOLD = 10000;
local ENERGY_CUBE_NAME = "mekanism:ultimate_energy_cube";
local GREENHOUSE_LENGTH = 15;

local t = peripheral.wrap('right');

local use = t.useOnBlock;
local collect = t.collectItems;

local up = turtle.up;
local down = turtle.down;
local left = turtle.turnLeft;
local right = turtle.turnRight;
local forward = turtle.forward;
local back = turtle.back;

local private = {};

local function printFuel()
  print('=> Initial Fuel: ', turtle.getFuelLevel(), '/', turtle.getFuelLimit())
end

local function findEnergyCube()
  for i = 1, 16, 1 do
    local item = turtle.getItemDetail(i);
    if item and item.name == ENERGY_CUBE_NAME then
      return i;
    end
  end

  return nil;
end

-- when on home
local function goCleanup()
  up();
  right();
  forward();
  right();
  up();
  up();
end

local function cleanup()
  for i = 1, 16, 1 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i);
      turtle.drop();
    end
  end
end

-- when front of ender chest
function private.goBackCleanup()
  right();
  down();
  down();
  forward();
  right();
  down();
end

-- when on home point
local function goReload()
  up();
  right();
  forward();
  forward();
  right();
  up();
  up();
end

local function reload()
  turtle.dig();
  t.collectItems();

  local cubeSlot = findEnergyCube()
  if not cubeSlot then
    private.goBackReload()
    error('Fatal: item "' .. ENERGY_CUBE_NAME .. '" not found')
  end

  turtle.select(cubeSlot);

  while true do
    local ok, result = t.chargeTurtle(1000000);

    if ok and result > 0 then
      print('=> Loading fuel: ', turtle.getFuelLevel(), '/', turtle.getFuelLimit())
    else
      break
    end
  end

  turtle.place()
end

-- when front of energy cube
function private.goBackReload()
  right();
  down();
  down();
  forward();
  forward();
  right();
  down();
end

local function goCleanupFromReload()
  right();
  forward();
  left();
end

local function gatherLeft()
  left();
  use();
  collect();
  right();
end

local function gatherLine()
  for _i = 1, GREENHOUSE_LENGTH - 1, 1 do
    gatherLeft();
    forward();
  end

  gatherLeft();
end

local function shouldCleanup()
  for i = 1, 16, 1 do
    if turtle.getItemCount(i) > 0 then
      return true;
    end
  end

  return false;
end

local function waitUnblock()
  print('=> Turtle collect paused');

  while turtle.detectUp() do
    os.sleep(2)
  end

  print('=> Turtle collect resumed');
end

local function gather()
  gatherLine();
  right();
  right();

  -- for _i = 1, GREENHOUSE_LENGTH - 1, 1 do
  --   forward();
  -- end

  gatherLine();
  right();
  right();
end

local function getNbFreeStack()
  local counter = 0;

  for i = 1, 16, 1 do
    if turtle.getItemCount(i) == 0 then
      counter = counter + 1
    end
  end

  return counter;
end

local function main()
  turtle.select(1);

  if turtle.detectUp() then
    waitUnblock();
  end

  printFuel();

  goReload()
  reload();

  if shouldCleanup() then
    goCleanupFromReload();
    cleanup();
    private.goBackCleanup();
  else
    private.goBackReload();
  end

  print('=> Turtle collect started')

  while true do
    gather();

    if turtle.detectUp() then
      waitUnblock();
    end

    if getNbFreeStack() <= 2 then
      goCleanup();
      cleanup();
      private.goBackCleanup();
    end

    printFuel();
    if turtle.getFuelLevel() <= ENERGY_THRESHOLD then
      goReload()
      reload();
      private.goBackReload();
    end
  end

  print('=> Turtle collect stopped');
end

main();
