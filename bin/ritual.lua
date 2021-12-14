local chat = peripheral.find('chatBox');
local t = peripheral.wrap('right');

function sendFormattedMessage(payload, prefix)
  prefix = prefix or 'Trap Weather Bot';
  chat.sendFormattedMessage(textutils.serializeJSON(payload), prefix);
end

local function doRitual(slot)
  sendFormattedMessage({
    text = "OK, processing...",
    color = 'yellow'
  })
  turtle.select(slot);
  t.useOnBlock();
  turtle.select(16);
  os.sleep(2)
  t.useOnBlock();
  sendFormattedMessage({
    text = "ritual started!",
    color = 'yellow'
  })

  os.sleep(18);
  sendFormattedMessage({
    text = "ritual finished!",
    color = 'green'
  })
end

local function redstoneEasterEgg()
  local redstoneSignal = redstone.getInput('top');

  if not redstoneSignal then
    turtle.back();
    turtle.back();
    turtle.up();

    if not redstone.getInput('front') then
      t.useOnBlock();
    end

    turtle.down();
    turtle.forward();
    turtle.forward();

    if not redstone.getInput('top') then
      redstoneEasterEgg()
    end
  end
end

print('=> Rituals server started.')

while true do
  local event, username, message = os.pullEvent();
  if event == 'redstone' then
    redstoneEasterEgg();
  end

  if event == 'chat' and message == '!day' then
    print('=> day command received');
    doRitual(1);
  elseif event == 'chat' and message == '!stoprain' then
    print('=> stoprain command received');
    doRitual(2);
  elseif event == 'chat' and message == '!night' then
    print('=> night command received');
    doRitual(3);
  elseif event == 'chat' and message == '!help' then
    sendFormattedMessage({
      text = "\n`!day` start a sunrise ritual\n`!stoprain` start a cloudshaping ritual\n`!night` start a moonfall ritual",
      color = 'green'
    })
  end
end
