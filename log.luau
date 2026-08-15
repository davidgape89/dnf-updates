local function log(msg)
    local dataDir, _ = noctalia.pluginDataDir()
    if not dataDir then
        dataDir = noctalia.pluginDir() or "."
    end
    noctalia.mkdirAll(dataDir)
    local logsPath = dataDir .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = string.format("[ %s ]: %s\n", os.date(), tostring(msg))
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

return log
