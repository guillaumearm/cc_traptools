local LIST_FILES = {'startup.lua', 'apis/bapil', 'apis/events', 'apis/logger', 'apis/daemon', 'bin/daemon.lua'}

local REPO_PREFIX = 'https://raw.githubusercontent.com/guillaumearm/cc_traptools/master/'

fs.makeDir('/apis');
fs.makeDir('/daemons');
fs.makeDir('/lib');
fs.makeDir('/bin');

for k, filePath in pairs(LIST_FILES) do
  fs.delete(filePath)
  shell.execute('wget', REPO_PREFIX .. filePath, filePath)
end

print()

print('=> Execute startup.lua')
shell.execute('/startup.lua')
