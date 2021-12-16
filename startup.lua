local APIS_TO_LOAD = {'apis/eventloop', 'apis/net', 'apis/colorutils', 'apis/rsw', 'apis/rsr', 'apis/rsclient',
                      'apis/chatbox', 'apis/mclock', 'apis/msequencer'}

-- 0. add /bin in path
shell.setPath(shell.path(0) .. ":/bin")

-- 1. additional aliases
shell.setAlias("c", "clear")

-- 2. hijack os loadAPI
os.loadAPI("apis/bapil")
bapil.hijackOSAPI()

-- Load stacktrace API and install tpcall as replacement for pcall.
assert(os.loadAPI("apis/stacktrace"))
_G.pcall = stacktrace.tpcall

-- 3. load common apis
for _, apipath in ipairs(APIS_TO_LOAD) do
  print("=> loading ", apipath)
  assert(os.loadAPI(apipath))
end

-- 4. load and install daemon api
assert(os.loadAPI("apis/daemon"))
daemon.install()

-- 5. shell autocompletions
local completion = require "cc.shell.completion"

-- completion: cat.lua
local cat_complete = completion.build({completion.file});
shell.setCompletionFunction("bin/cat.lua", cat_complete);

-- completion: tplay.lua
local tplay_complete = completion.build({completion.file});
shell.setCompletionFunction("bin/tplay.lua", tplay_complete);

-- global utils
_G.events = eventloop.create(); -- main event loop
