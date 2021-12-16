-- Refuel turtle with RF
local left = peripheral.wrap('left');
local right = peripheral.wrap('right');

local leftIsValid = not not (left and left.chargeTurtle);
local rightIsValid = not not (right and right.chargeTurtle);

local charge = nil
if leftIsValid then
  charge = left.chargeTurtle;
elseif rightIsValid then
  charge = right.chargeTurtle;
end

if not turtle then
  error('this program should be run on a cc turtle')
end

if turtle.getFuelLevel() == turtle.getFuelLimit() then
  print('turtle already refueled!')
  return;
end

if not charge then
  error('no automata found on the current turtle')
end

print('Initial fuel: ', turtle.getFuelLevel(), '/', turtle.getFuelLimit())

while true do
  local ok, res = charge(1000000);

  if not ok then
    error(res)
  end

  if res == 0 then
    break
  end

  print('-> ', turtle.getFuelLevel(), '/', turtle.getFuelLimit())
end

if turtle.getFuelLevel() == turtle.getFuelLimit() then
  print('turtle refueled!');
else
  print('warning: turtle is not fully refueled!');
end

