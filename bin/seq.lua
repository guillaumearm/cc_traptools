local el = eventloop.create();
local seq = msequencer.create(el);

local NB_STEPS = 64;
local INSTRUMENTS_WIDTH = 12;

local pattern = {};

local function instrument(name, volume, pitch)
  return {
    instrument = name,
    volume = volume,
    pitch = pitch
  }
end

local EMPTY = {}
local instruments = {instrument('basedrum'), instrument('snare'), instrument('hat', 0.8, 21)}
local nbInstruments = #instruments
local instrumentsHeight = nbInstruments;

local function resetPattern()
  pattern = {};

  for i = 1, NB_STEPS, 1 do
    pattern[i] = {}

    for _ = 1, nbInstruments, 1 do
      table.insert(pattern[i], EMPTY)
    end
  end
end

resetPattern()

local function getActions(x, y)
  local actions = pattern[x][y];

  if actions == EMPTY then
    return EMPTY;
  end

  if actions and actions[1] and actions[1].instrument then
    return actions;
  end

  if actions and actions.instrument then
    return {actions};
  end

  return nil;
end

local monitor = peripheral.find('monitor');

if not monitor then
  error('no monitor found')
end

monitor.setTextColor(colors.white);
monitor.setBackgroundColor(colors.black)
monitor.clear();
monitor.setCursorBlink(false)

local monitorWidth = monitor.getSize()

if monitorWidth < NB_STEPS then
  error('monitor width should be > ' .. NB_STEPS)
end

local function getColorWhenEmpty(x)
  if (x - 1) % 4 == 0 then
    return colors.gray, colors.lightGray
  else
    return colors.lightGray, colors.gray
  end
end

local function spacedString(n)
  local str = "";

  for _ = 1, n, 1 do
    str = str .. " "
  end

  return str;
end

local function rightPad(n, str)
  local diff = n - #str

  if diff > 0 then
    return str .. spacedString(diff)
  end

  return str
end

local windowInstruments = window.create(monitor, 1, 1, INSTRUMENTS_WIDTH, instrumentsHeight);
windowInstruments.setBackgroundColor(colors.black)
windowInstruments.setTextColor(colors.white)
windowInstruments.clear();

local windowPattern = window.create(monitor, INSTRUMENTS_WIDTH + 1, 1, NB_STEPS, instrumentsHeight);
windowPattern.clear()
-- windowPattern.setBackgroundColor(colors.black)
-- windowPattern.setTextColor(colors.white)

local currentCursor = 1;
local windowCursorBar = window.create(monitor, INSTRUMENTS_WIDTH + 1, instrumentsHeight + 1, NB_STEPS, 1)
windowCursorBar.setBackgroundColor(colors.black);
windowCursorBar.clear();
windowCursorBar.write('*')

local windowPlayPause = window.create(monitor, 1, instrumentsHeight + 2, 2, 1);

local windowResetCursor = window.create(monitor, 1 + 2 + 1, instrumentsHeight + 2, 2, 1);
windowResetCursor.setBackgroundColor(colors.purple);
windowResetCursor.clear();
windowResetCursor.write('<<')

local function drawPlay()
  windowPlayPause.setBackgroundColor(colors.red);
  windowPlayPause.clear();
  windowPlayPause.setCursorPos(1, 1)
  windowPlayPause.write('|>')
end

local function drawPause()
  windowPlayPause.setBackgroundColor(colors.green);
  windowPlayPause.clear();
  windowPlayPause.setCursorPos(1, 1)
  windowPlayPause.write('||')
end

drawPlay();

local function cursorRedraw()
  if currentCursor == 1 then
    windowCursorBar.setCursorPos(NB_STEPS, 1);
    windowCursorBar.write(' ')

    windowCursorBar.setCursorPos(currentCursor, 1);
    windowCursorBar.write('*')
  else
    windowCursorBar.setCursorPos(currentCursor - 1, 1);
    windowCursorBar.write(' *')
  end

end

local function renderAll()
  windowInstruments.clear()
  windowPattern.clear();

  for y = 1, 3, 1 do
    windowInstruments.setCursorPos(1, y);
    -- monitor.write(rightPad(10, instruments[y].instrument));
    windowInstruments.write(instruments[y].instrument);

    windowPattern.setCursorPos(1, y);

    for x = 1, NB_STEPS, 1 do
      local actions = getActions(x, y);

      if not actions or actions == EMPTY then
        local bgColor, textColor = getColorWhenEmpty(x);
        windowPattern.setBackgroundColor(bgColor);
        windowPattern.setTextColor(textColor);
        windowPattern.write('_')
      else
        windowPattern.setTextColor(colors.white);
        windowPattern.setBackgroundColor(colors.purple)
        windowPattern.write('x')
      end
    end
  end
end

renderAll();

el.register('monitor_touch', function(_, x, y)
  if y == instrumentsHeight + 2 and x >= 1 and x <= 2 then
    if seq.isRunning() then
      seq.pause()
      drawPlay()
    else
      seq.play()
      drawPause()
    end
    return
  end

  if y == instrumentsHeight + 2 and x >= 4 and x <= 5 then
    seq.reset();
    currentCursor = 1;
    windowCursorBar.clear();
    cursorRedraw();
  end

  if y > instrumentsHeight or x <= INSTRUMENTS_WIDTH or x > INSTRUMENTS_WIDTH + NB_STEPS then
    return
  end

  x = x - INSTRUMENTS_WIDTH

  if pattern[x][y] == EMPTY then
    pattern[x][y] = instruments[y];
  else
    pattern[x][y] = EMPTY;
  end

  renderAll();
end);

seq.setPattern(pattern)

seq.setHandler(function(c)
  currentCursor = c + 1;
  cursorRedraw();
end)

-- windowCursor.setVisible(false);

-- windowCursor.redraw();
-- windowPattern.redraw();

-- windowCursor.setBackgroundColor(colors.black)
-- windowCursor.clear();

-- windowCursor.reposition(INSTRUMENTS_WIDTH + currentCursor + 1, instrumentsHeight + 1);

-- windowCursor.setBackgroundColor(colors.green)
-- windowCursor.clear();

-- windowCursor.setVisible(true);
-- windowCursor.setVisible(false);

-- windowPattern.redraw();

-- windowInstruments.redraw();

-- windowCursor.setVisible(true);

-- initialRender();

-- windowPattern.redraw();
-- windowInstruments.redraw();

-- seq.setPattern({{kick}, {}, hh, {}, {kick, snare}, {}, hh, hh})
-- seq.setBpm(127);

-- seq.play();

-- seq.setHandler(function(step, numloop)
--   print(step, numloop)
--   if step == seq.getSteps() and numloop == 1 then
--     seq.pause()
--     el.setTimeout(function()
--       seq.play();
--     end, 1)
--   elseif step == 1 and numloop == 6 then
--     seq.stop();
--   end
-- end)

el.startLoop();
