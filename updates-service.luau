local hasShownUpdateNotification = false
local hasShownRestartNotification = false
local cacheRefreshTime = noctalia.getConfig("cache_refresh")
-- Setting it to the same as the cache so it runs on boot
local serviceUpdates = noctalia.getConfig("cache_refresh")
local serviceRefreshTime = noctalia.getConfig("service_refresh")

noctalia.setUpdateInterval(serviceRefreshTime * 60000)

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

function handleUpgrades(stdout: Stdout)
    if stdout.exitCode ~= 100 and stdout.exitCode > 0 then
        return
    end

    if stdout.exitCode == 0 then
        noctalia.state.set("isUpdated", true)
        noctalia.state.set("updates", nil)
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

function checkNeedsRestarting(withCache: boolean)
    if withCache then
        noctalia.runStream("dnf needs-restarting -C", handleNeedsRestartingStream)
        else
        noctalia.runStream("dnf needs-restarting --refresh", handleNeedsRestartingStream)
    end
end

function update()
    serviceUpdates = serviceUpdates + 1
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end
    if serviceUpdates * serviceRefreshTime > cacheRefreshTime then
        checkNeedsRestarting(false)
        checkUpgrades()
        serviceUpdates = 0
        else
        checkNeedsRestarting(true)
        checkUpgrades()
    end
end


-- function onIpc(event, payload)
--     noctalia.notify(noctalia.tr("Received message:"), noctalia.tr(event))
-- end
