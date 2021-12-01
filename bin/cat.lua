local given_filepath = ...;

if not given_filepath then
  error('usage: cat <filepath>');
end

-- TODO: autocompletion

local filepath = shell.dir() .. '/' .. given_filepath;

if not fs.exists(filepath) then
  error("'" .. filepath .. "' does not exists");
end

if fs.isDir(filepath) then
  error("'" .. filepath .. "' is a directory");
end

local handler = fs.open(filepath, "r");
local data = handler.readAll();
handler.close();

print(data);
