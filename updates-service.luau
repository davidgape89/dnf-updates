local hasShownUpdateNotification = false
local hasShownRestartNotification = false
local cacheRefreshTime = noctalia.getConfig("cache_refresh")
local minutesElapsed = 0

noctalia.setUpdateInterval(60000)

local updateState: UpdateState = {
    isUpdated = true,
    needsRestart = false,
    updates = {},
}

function handleNeedsRestartingStream(line)
    if line == "Reboot is required to fully utilize these updates." then
        if not hasShownRestartNotification then
            noctalia.notify(noctalia.tr("rebootNecessary"), noctalia.tr("rebootNecessarySub"))
            hasShownRestartNotification = true
        end
        updateState.needsRestart = true
        noctalia.state.set("updateState", updateState)
    end
end

function checkNeedsRestarting()
    noctalia.runStream("dnf needs-restarting -C --color=never", handleNeedsRestartingStream)
end

function handleUpgrades(stdout: CommandResult)
    if stdout.stdout == "" then
        updateState.isUpdated = true
        updateState.updates = {}
        noctalia.state.set("updateState", updateState)
        checkNeedsRestarting()
        return
    end

    updateState.updates = {}
    for line in string.gmatch(stdout.stdout, "[^\r\n]+") do
        if line == "Upgrades" then
            continue
        end
        local packageIterator = string.gmatch(line, "[^%s]+")
        table.insert(updateState.updates, {name = packageIterator(), version = packageIterator(), status = packageIterator()})
    end

    if not hasShownUpdateNotification then
        noctalia.notify(noctalia.tr("updatesAvailable"), noctalia.trp("updates", #updateState.updates))
    end

    hasShownUpdateNotification = true
    updateState.isUpdated = false
    noctalia.state.set("updateState", updateState)
    checkNeedsRestarting()
end

function checkUpgrades()
    noctalia.runAsync("dnf check-upgrade -C --color=never -q", handleUpgrades)
end

function handleRefreshRepositories(line)
    if line == "Upgrades" then
        checkUpgrades()
    end
end

function refreshRepositories()
    noctalia.runStream("dnf check-upgrade --refresh --color=never", handleRefreshRepositories)
end

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    if math.fmod(minutesElapsed, cacheRefreshTime) == 0 then
        refreshRepositories()
    else
        checkUpgrades()
    end

    minutesElapsed = minutesElapsed + 1
end
