-- Check cli arguments
local filename = ...;

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
      loopStoppedByUser = true;
      el.stopLoop();
    elseif k == keys.w then
      exec(create('forward'), turtle.forward)
    elseif k == keys.s then
      exec(create('back'), turtle.back)
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
      exec(create('left'), turtle.turnLeft)
    elseif k == keys.space then
      exec(create('up'), turtle.up);
    elseif k == shiftCode then
      exec(create('down'), turtle.down);
    elseif k == keys.right then
      moveSlot(1)
    elseif k == keys.left then
      moveSlot(-1)
    elseif k == keys.down then
      moveSlot(4)
    elseif k == keys.up then
      moveSlot(-4)
    elseif k == keys.enter then
      exec(create('place', getItemId()), turtle.place);
    elseif k == keys.pageUp then
      exec(create('placeUp', getItemId()), turtle.placeUp);
    elseif k == keys.pageDown then
      exec(create('placeDown', getItemId()), turtle.placeDown)
    elseif k == keys.u then
      local t = getAutomata();
      if not t then
        print('Warning: no automata found');
      else
        exec(create('use', getItemId()), t.useOnBlock);
      end
    end
  end)

  el.startLoop()

  if not loopStoppedByUser then
    print('Cancelled!')
    return;
  elseif #actions == 0 then
    print('Warning: no actions recorded.');
    return;
  else
    save()
  end
end

main(filepath);
