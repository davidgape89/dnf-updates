local PLUGIN_NAME = "[dnf-updates-plugin]"

function log(message: string)
    noctalia.log(PLUGIN_NAME .. " " .. message)
end

return log
