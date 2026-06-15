noctalia.setUpdateInterval(5 * 60000)

local hasShownUpdateNotification = false
local hasShownRestartNotification = false

type Stdout = {
    exitCode: number,
    stdout: string,
}

function update()
    if not noctalia.commandExists("dnf") then
        noctalia.notify(noctalia.tr("dnfMissing"), noctalia.tr("dnfMissingSub"))
        return
    end

    noctalia.runAsync("dnf list --upgrades --color=never -q", function(stdout: Stdout)
        if stdout.exitCode > 0 then return end
        if stdout.stdout == "" then
            noctalia.state.set("isUpdated", true)
            noctalia.state.set("updates", nil)
            return
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
        if not hasShownUpdateNotification then
            noctalia.notify(noctalia.tr("updatesAvailable"), noctalia.trp("updates", #packages))
        end
        hasShownUpdateNotification = true
    end)

    noctalia.runAsync("dnf needs-restarting", function(stdout:Stdout)
        if stdout.exitCode > 0 and not hasShownRestartNotification then
            hasShownRestartNotification = true
            noctalia.notify(noctalia.tr("rebootNecessary"), noctalia.tr("rebootNecessarySub"))
            noctalia.state.set("needsRestarting", true)
        end
    end)
end

-- function onIpc(event, payload)
--     noctalia.notify(noctalia.tr("Received message:"), noctalia.tr(event))
-- end
