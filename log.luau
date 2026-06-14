function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

return log
