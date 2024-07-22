settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd.status",
    inotifyMode = "CloseWrite",
}

sync {
    default.rsync,
    source = "/var/lib/docker/volumes/st_statamic-root/_data",
    target = "mikeschinkel@containers.local",
    rsync = {
        archive = true,
        compress = false,
        verbose = true,
        _extra = {"--omit-dir-times"},
        ssh = {
            port = 22,
            _extra = {"-o StrictHostKeyChecking=no"},
        },
    },
}
