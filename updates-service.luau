-- local noctalia = require('Noctalia')

noctalia.setUpdateInterval(10000)

function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

local hasShownNotification = false

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    noctalia.runAsync("dnf list --upgrades --color=never -q", function(stdout: {exitCode: number; stdout: string})
        if stdout.exitCode > 0 then return end

        if not stdout.stdout then
            noctalia.state.set("isUpdated", true)
            noctalia.state.set("updates", nil)
        end

        local packages: {[number]: {name: string, version: string, status: string}} = {}
        for line in string.gmatch(stdout.stdout, "[^\r\n]+") do
            if line == "Available upgrades" then
                continue
            end
            local packageIterator = string.gmatch(line, "[^%s]+")
            table.insert(packages, {name = packageIterator(), version = packageIterator(), status = packageIterator()})
        end
        noctalia.state.set("isUpdated", false)
        noctalia.state.set("updates", packages)
        if not hasShownNotification then
            noctalia.notify(noctalia.tr("updatesAvailable"), noctalia.trp("updates", #packages))
        end
        hasShownNotification = true
    end)
end

-- function onIpc(event, payload)
--     noctalia.notify(noctalia.tr("Received message:"), noctalia.tr(event))
-- end
