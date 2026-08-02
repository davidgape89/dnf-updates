local hasShownUpdateNotification = false
local hasShownRestartNotification = false
local cacheRefreshTime = noctalia.getConfig("cache_refresh")

noctalia.setUpdateInterval(cacheRefreshTime * 60000)

function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

type Stdout = {
    exitCode: number,
    stdout: string,
    stderr: string,
    stderrTruncated: boolean,
    timedOut: boolean,
}

function handleNeedsRestartingStream(line)
    if line == "Reboot is required to fully utilize these updates." then
        if not hasShownRestartNotification then
            noctalia.notify(noctalia.tr("rebootNecessary"), noctalia.tr("rebootNecessarySub"))
            hasShownRestartNotification = true
        end
        noctalia.state.set("needsRestarting", true)
    end
end

function handleRefreshRepositories(line)
    if line == "Metadata cache created." then
        checkUpgrades()
    end
end

function handleUpgrades(stdout: Stdout)
    if stdout.stdout == "" then
        log('inside if')
        noctalia.state.set("isUpdated", true)
        noctalia.state.set("updates", {})
        return
    end

    local packages: {[number]: {name: string, version: string, status: string}} = {}
    for line in string.gmatch(stdout.stdout, "[^\r\n]+") do
        if line == "Upgrades" then
            continue
        end
        local packageIterator = string.gmatch(line, "[^%s]+")
        table.insert(packages, {name = packageIterator(), version = packageIterator(), status = packageIterator()})
    end
    noctalia.state.set("isUpdated", false)
    noctalia.state.set("updates", packages)
    if not hasShownUpdateNotification then
        noctalia.notify(noctalia.tr("updatesAvailable"), noctalia.trp("updates", #packages))
    end
    hasShownUpdateNotification = true
end

function checkUpgrades()
    noctalia.runAsync("dnf check-upgrade -C --color=never -q", handleUpgrades)
end

function checkNeedsRestarting()
    noctalia.runStream("dnf needs-restarting -C --color=never", handleNeedsRestartingStream)
end

function refreshRepositories()
    noctalia.runStream("dnf --refresh makecache --color=never", handleRefreshRepositories)
end

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    refreshRepositories()
    checkNeedsRestarting()
end
