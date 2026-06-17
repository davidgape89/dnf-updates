noctalia.setUpdateInterval(5 * 60000)

local hasShownUpdateNotification = false
local hasShownRestartNotification = false

type Stdout = {
    exitCode: number,
    stdout: string,
    stderr: string,
    stderrTruncated: boolean,
    timedOut: boolean,
}

function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

function handleNeedsRestarting(stdout: Stdout)
    if stdout.exitCode > 0 and not hasShownRestartNotification then
        hasShownRestartNotification = true
        noctalia.notify(noctalia.tr("rebootNecessary"), noctalia.tr("rebootNecessarySub"))
        noctalia.state.set("needsRestarting", true)
    end
end

function handleUpgrades(stdout: Stdout)
    if stdout.exitCode ~= 100 and stdout.exitCode > 0 then
        log(stdout.stderr)
        return
    end

    if stdout.exitCode == 0 then
        noctalia.state.set("isUpdated", true)
        noctalia.state.set("updates", nil)
        noctalia.runAsync("dnf needs-restarting", handleNeedsRestarting)
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

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    noctalia.runAsync("dnf check-upgrade --refresh --color=never -q", handleUpgrades)
end

-- function onIpc(event, payload)
--     noctalia.notify(noctalia.tr("Received message:"), noctalia.tr(event))
-- end
