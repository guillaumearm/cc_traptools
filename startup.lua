shell.setPath(shell.path(0) .. ":/bin")

os.loadAPI("apis/bapil")
bapil.hijackOSAPI()

assert(os.loadAPI("apis/daemon"))
daemon.install()

