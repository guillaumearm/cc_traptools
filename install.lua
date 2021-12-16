local LIST_FILES = {'startup.lua', 'apis/bapil', 'apis/stacktrace', 'apis/eventloop', 'apis/colorutils', 'apis/rsw',
                    'apis/rsr', 'apis/rsclient', 'apis/net', 'apis/chatbox', 'apis/mclock', 'apis/msequencer',
                    'apis/logger', 'apis/daemon', 'bin/cat.lua', 'bin/daemon.lua', 'bin/seq.lua', 'bin/collect.lua',
                    'bin/ritual.lua', 'bin/trefuel.lua'};

local DAEMON_LIST = {'redserver', 'sdoors', 'emoji', 'rspeaker', 'cowjar'}

local REPO_PREFIX = 'https://raw.githubusercontent.com/guillaumearm/cc_traptools/master/'

local previousDir = shell.dir()

shell.setDir('/')

fs.makeDir('/apis');
fs.makeDir('/daemons');
fs.makeDir('/bin');

for _, filePath in pairs(LIST_FILES) do
  fs.delete(filePath)
  shell.execute('wget', REPO_PREFIX .. filePath, filePath)
end

for _, daemonName in pairs(DAEMON_LIST) do
  fs.delete('daemons/' .. daemonName)
  fs.delete('daemons/' .. daemonName .. '.disabled')
  shell.execute('wget', REPO_PREFIX .. 'daemons/' .. daemonName .. '.disabled', 'daemons/' .. daemonName .. '.disabled')
end

print()
print('=> Execute startup.lua')
shell.execute('/startup.lua')

shell.setDir(previousDir)
