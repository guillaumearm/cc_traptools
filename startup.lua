local APIS_TO_LOAD = {'apis/events', 'apis/colorutils', 'apis/rsw', 'apis/rsr', 'apis/rsclient'}

-- 0. add /bin in path
shell.setPath(shell.path(0) .. ":/bin")

-- 1. additional aliases
shell.setAlias("c", "clear")

-- 2. hijack os loadAPI
os.loadAPI("apis/bapil")
bapil.hijackOSAPI()

-- 3. load common apis
for _, apipath in ipairs(APIS_TO_LOAD) do
  print("=> loading ", apipath)
  assert(os.loadAPI(apipath))
end

-- 4. load and install daemon api
assert(os.loadAPI("apis/daemon"))
daemon.install()

