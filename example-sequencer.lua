local el = eventloop.create();
local seq = msequencer.create(el);

local function instrument(name, volume, pitch)
  return {
    instrument = name,
    volume = volume,
    pitch = pitch
  }
end

local kick = instrument('basedrum')
local snare = instrument('snare')
local hh = instrument('hat', 0.8, 21);

seq.setPattern({{kick}, {}, hh, {}, {kick, snare}, {}, hh, hh})

seq.setBpm(127);

seq.play();

seq.setHandler(function(step, numloop)
  print(step, numloop)
  if step == seq.getSteps() and numloop == 1 then
    seq.pause()
    el.setTimeout(function()
      seq.play();
    end, 1)
  elseif step == 1 and numloop == 6 then
    seq.stop();
  end
end)

el.startLoop();
