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

-- when front of energy cube
local function goBackToHomePoint()
  left();
  back();
  left();
  down();
  down();
  down();
end

local function findEnergyCube()
  for i = 1, 16, 1 do
    turtle.select(i);
    local item = turtle.getItemDetail()
    if item and item.name == ENERGY_CUBE_NAME then
      return i;
    end
  end

  return nil;
end

local function cleanup()
  up();
  up();
  up();
  left();
  left();

  for i = 1, 16, 1 do
    turtle.select(i);
    turtle.drop();
  end

  turtle.select(1)

  left();
  left();
  down();
  down();
  down();
end

local function reload()
  up();
  up();
  up();
  right();
  forward();
  right();
  turtle.dig();
  t.collectItems();

  local cubeSlot = findEnergyCube()
  if not cubeSlot then
    goBackToHomePoint()
    error('Fatal: cube not found')
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

  left();
  back();
  left();
  down();
  down();
  down();
end

local function gatherLeft()
  left();
  use();
  collect();
  right();
end

local function gatherLine()
  for i = 1, GREENHOUSE_LENGTH - 1, 1 do
    gatherLeft();
    forward();
  end

  gatherLeft();
end

local function gather()
  gatherLine();
  left();
  left();
  gatherLine();
  left();
  left();
end

if turtle.detectUp() then
  error('turtle blocked')
end

reload();
cleanup();

while true do
  gather();

  if turtle.detectUp() then
    error('turtle blocked')
  end

  cleanup();

  if turtle.getFuelLevel() <= ENERGY_THRESHOLD then
    reload()
  end
end
