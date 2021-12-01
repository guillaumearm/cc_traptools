local REPO_PREFIX = 'https://raw.githubusercontent.com/guillaumearm/cc_traptools/master'

fs.makeDir('/apis');
fs.makeDir('/daemons');
fs.makeDir('/lib');
fs.makeDir('/bin');

local LIST_FILES = {'/startup.lua', '/apis/bapil', 'apis/logger', '/apis/daemon', '/bin/daemon.lua'}

for k, filePath in pairs(LIST_FILES) do
    shell.execute('wget', REPO_PREFIX .. filePath, filePath)
end

shell.execute('/startup.lua')
