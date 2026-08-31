local log = require("../log.luau")

-- Force the service to check for cached updates after the upgrade is complete
local CHECK_UPDATES_MESSAGE = "noctalia msg plugin davidgape89/dnf-updates:updates-service all check > /dev/null"
local UPGRADE_COMMAND = "sudo dnf upgrade --refresh; " .. CHECK_UPDATES_MESSAGE .. "; read -p \"Press Enter to continue...\""
function handleUpgrades(updatesCallback)
    return function(result: CommandResult)
        local updateState = { isUpdated = true, updates = {} }

        if not result or result.stdout == "" then
            updatesCallback(updateState)
        end

        for line in string.gmatch(result.stdout, "[^\r\n]+") do
            if line ~= "Upgrades" then
                local packageIterator = string.gmatch(line, "[^%s]+")
                local name = packageIterator()
                local version = packageIterator()
                local repository = packageIterator()
                if name then
                    table.insert(updateState.updates, { name = name, version = version or "", repository = repository or "" })
                end
            end
        end

        updateState.isUpdated = (#updateState.updates == 0)
        updatesCallback(updateState)
    end
end

function checkUpdates(updatesCallback)
    noctalia.runAsync("dnf check-upgrade -C --color=never -q", handleUpgrades(updatesCallback))
end

function handleRefreshRepositories(updatesCallback)
    return function(line)
        if line == "Upgrades" then
            checkUpdates(updatesCallback)
        end
    end
end

local dnfAdapter: UpdateAdapter = {
    -- Refreshes the repositories and checks for updates
    refreshRepositories = function(updatesCallback)
        noctalia.runStream("dnf --refresh check-update --color=never", handleRefreshRepositories(updatesCallback))
    end,
    -- Checks for updates from cached repositories
    checkUpdates = function(updatesCallback)
        checkUpdates(updatesCallback)
    end,
    -- Launches the upgrade process in the terminal
    upgrade = function()
        noctalia.runInTerminal(UPGRADE_COMMAND)
    end,
}

return dnfAdapter
