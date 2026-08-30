local log = require("../log.luau")
local CHECK_UPDATES = "zypper lu"
-- Force the service to check for cached updates after the upgrade is complete
local CHECK_UPDATES_MESSAGE = "noctalia msg plugin davidgape89/dnf-updates:updates-service all check > /dev/null"
local UPGRADE_COMMAND = "sudo zypper dup; " .. CHECK_UPDATES_MESSAGE .. "; read -p \"Press Enter to continue...\""
function handleUpgrades(updatesCallback)
    return function(result: CommandResult)
        local updateState = { isUpdated = true, updates = {} }

        if not result or result.stdout == "" then
            updatesCallback(updateState)
        end

        for line in string.gmatch(result.stdout, "[^\r\n]+") do
            if string.match(line, "^v") ~= nil then
                local packageIterator = string.gmatch(line, "|%s([^|]*)")
                local repository = packageIterator()
                local name = packageIterator()
                -- This is the current version of tha package
                local _ = packageIterator()
                local version = packageIterator()
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
    noctalia.runAsync(CHECK_UPDATES, handleUpgrades(updatesCallback))
end

local zypperAdapter: UpdateAdapter = {
    -- The repositories cannot be refreshed as a non-root user with zypper
    -- Refreshes the repositories and checks for updates
    refreshRepositories = function(updatesCallback)
        checkUpdates(updatesCallback)
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

return zypperAdapter
