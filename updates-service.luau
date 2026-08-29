local log = require("./log.luau")
local dnfAdapter = require("./adapters/dnf.luau")

local hasShownUpdateNotification = false
local hasShownRestartNotification = false
local firstRun = true
local cacheRefreshTime = tonumber(noctalia.getConfig("cache_refresh")) or 5
local minutesElapsed = 0
local pluginDataDir, _ = noctalia.pluginDataDir()
if not pluginDataDir then
    pluginDataDir = noctalia.pluginDir() or "."
end
-- Ensure the data directory exists
noctalia.mkdirAll(pluginDataDir)
local statePath = pluginDataDir .. "/last-state.json"

noctalia.setUpdateInterval(60000)

local updateState: UpdateState = {
    isUpdated = true,
    needsRestart = false,
    updates = {},
}

function storeState(state: UpdateState)
    local encoded, err = noctalia.json.encode(state)
    if encoded then
        noctalia.writeFile(statePath, encoded)
    else
        log("dnf-updates: failed to encode state: " .. tostring(err))
    end
end

function restoreState()
    local raw, readErr = noctalia.readFile(statePath)

    if raw then
        local decoded, decErr = noctalia.json.decode(raw)
        if decoded and type(decoded) == "table" then
            return decoded
        else
            log("dnf-updates: failed to decode state file: " .. tostring(decErr))
        end
    elseif readErr then
        log("dnf-updates: failed to read state file: " .. tostring(readErr))
    end
    return updateState
end

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

function publishState(state: UpdateState)
    noctalia.state.set("updateState", state)
    storeState(state)
end

function handleUpdates(updateState: UpdateState)
    log("handleUpgrades called")
    if not hasShownUpdateNotification and #updateState.updates > 0 then
        noctalia.notify(noctalia.tr("updatesAvailable"), noctalia.trp("updates", #updateState.updates))
        hasShownUpdateNotification = true
    end

    publishState(updateState)
    checkNeedsRestarting()
end

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    -- Restore the persisted state on first run while the repositories are being refreshed
    if firstRun then
        updateState = restoreState()
        publishState(updateState)
        firstRun = false
    end

    if math.fmod(minutesElapsed, cacheRefreshTime) == 0 then
        log("Refreshing repositories")
        dnfAdapter.refreshRepositories(handleUpdates)
    else
        -- Check upgrades seems to be buggy for now when run periodically
        -- Sometimes it will inconsistently report no updates when there are
        -- checkUpgrades()
    end

    minutesElapsed = minutesElapsed + 1
end

function onIpc(event, payload)
    if event == "check" then
        dnfAdapter.checkUpdates(handleUpdates)
        return
    end
    if event == "refresh" then
        log("Refreshing repositories")
        dnfAdapter.refreshRepositories(handleUpdates)
        return
    end
    if event == "upgrade" then
        dnfAdapter.upgrade()
        return
    end
    log("Unknown event: " .. event)
end
