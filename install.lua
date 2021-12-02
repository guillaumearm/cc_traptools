local LIST_FILES = {'startup.lua', 'apis/bapil', 'apis/stacktrace', 'apis/eventloop', 'apis/colorutils', 'apis/rsw',
                    'apis/rsr', 'apis/rsclient', 'apis/net', 'apis/logger', 'apis/daemon', 'bin/cat.lua',
                    'bin/daemon.lua'}

local REPO_PREFIX = 'https://raw.githubusercontent.com/guillaumearm/cc_traptools/master/'

local previousDir = shell.dir()

shell.setDir('/')

fs.makeDir('/apis');
fs.makeDir('/daemons');
fs.makeDir('/bin');

for k, filePath in pairs(LIST_FILES) do
  fs.delete(filePath)
  shell.execute('wget', REPO_PREFIX .. filePath, filePath)
end

fs.delete('daemons/redserver')
fs.delete('daemons/redserver.disabled')
shell.execute('wget', REPO_PREFIX .. 'daemons/redserver.disabled', 'daemons/redserver.disabled')

print()
print('=> Execute startup.lua')
shell.execute('/startup.lua')

shell.setDir(previousDir)
