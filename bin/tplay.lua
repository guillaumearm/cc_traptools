-- CLI arguments
local filename = ...

if not filename then
  print('usage: tplay <filename>');
  return;
end

local filepath = shell.resolve(filename);

if not fs.exists(filepath) then
  error('the file "' .. filepath .. '" does not exists!');
end

if fs.isDir(filepath) then
  error('"' .. filepath .. '" is a directory!');
end

-- Read file

local file = fs.open(filepath, 'r');
local data = file.readAll();
file.close();
local actions = textutils.unserialize(data);

if not actions then
  error('Unable to parse file "' .. filepath .. '"');
end

if not actions[1] or not actions[1].type then
  error('Invalid format file "' .. filepath .. '"')
end

local function getItemIdFromAction(action)
  if action and action.type == 'place' or action.type == 'placeUp' or action.type == 'placeDown' or action.type == 'use' then
    return action.payload;
  end
end

local function getItemIdFromItem(item)
  if item then
    return item.name .. '|||' .. item.displayName;
  end
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

local function getItemId(slotId)
  local item = turtle.getItemDetail(slotId, true);
  return getItemIdFromItem(item)
end

local function getNeededItems()
  local needed = {};

  for _, action in ipairs(actions) do
    print('===>', action.type, action.payload);
    local itemId = getItemIdFromAction(action);

    if itemId then
      local counter = needed[itemId] or 0;
      needed[itemId] = counter + 1;
    end
  end

  return needed;
end

local function shallowClone(data)
  local result = {};

  for k, v in pairs(data) do
    result[k] = v;
  end

  return result;
end

local function waitForItems(neededItems)
  local ok = false;
  local el = eventloop.create();

  local function render(itemsCounters)
    term.clear();
    term.setCursorPos(1, 1);
    print('Wait for items...')

    for k, v in pairs(itemsCounters) do
      if v > 0 then
        print(k, ':', v);
      end
    end
  end

  local function checkCounters(itemsCounters)
    for k, v in pairs(itemsCounters) do
      if v > 0 then
        return false;
      end
    end

    return true;
  end

  local inventoryHandler = function()
    local itemsCounters = shallowClone(neededItems);

    -- decrement itemsCounters
    for slotId = 1, 16, 1 do
      local item = turtle.getItemDetail(slotId, true);
      local itemId = getItemIdFromItem(item);

      if item and type(itemsCounters[itemId]) == 'number' then
        itemsCounters[itemId] = itemsCounters[itemId] - item.count;
      end
    end

    if checkCounters(itemsCounters) then
      ok = true;
      if el.isRunningLoop() then
        el.stopLoop();
      end
      return;
    end

    render(itemsCounters);
  end

  el.register('turtle_inventory', inventoryHandler);
  inventoryHandler();

  if not ok then
    el.startLoop();
  end

  return ok;
end

-- Play Actions

local commands = {
  forward = turtle.forward,
  back = turtle.back,
  left = turtle.turnLeft,
  right = turtle.turnRight,
  up = turtle.up,
  down = turtle.down,
  place = turtle.place,
  placeUp = turtle.placeUp,
  placeDown = turtle.placeDown,
  use = function()
    local t = getAutomata();
    if t then
      return t.useOnBlock()
    else
      return false, 'Error: missing automata!';
    end
  end
}

local function playAction(action)
  local itemId = getItemIdFromAction(action);

  if itemId then
    for slotId = 1, 16, 1 do
      if getItemId(slotId) == itemId then
        if turtle.getSelectedSlot() ~= slotId then
          turtle.select(slotId);
        end
        break
      end
    end
  end

  local command = commands[action.type];

  if not command then
    error('Fatal: unknown command')
  end

  local lastErr = nil;

  while true do
    local ok, err = command();
    if ok then
      break
    end

    if not lastErr then
      lastErr = err or 'unknown error';
      print('Cannot perform action because', err);
    end

    os.sleep(3);
  end
end

-- Main
local function main()
  local items = getNeededItems();
  local ok = waitForItems(items);

  if not ok then
    print('cancelled!');
    return;
  end

  print('=> Items found!');
  print('=> Play build actions...');

  for _, action in ipairs(actions) do
    playAction(action);
  end
end

main();
