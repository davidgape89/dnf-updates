local packages: {[number]: {name: string, version: string, status: string}} = {}

function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

local function upgrade()
    noctalia.runInTerminal("sudo dnf upgrade --refresh; read -p \"Press Enter to continue...\"")
    panel.close()
end

local function render()
    log('rendering panel')
    local labelText = noctalia.trp("updates", #packages)
    local updateRows: {UiNode} = {}
    for index, package in ipairs(packages) do
        local packageRow: UiNode = ui.row({align = "center", justify = "space_between"}, {
            ui.row({}, {
                ui.glyph({name = "arrow-bar-up", fontSize = 8}),
                ui.box({width = 8, height = 8, opacity = 0}),
                ui.label({ text = package.name })
            }),            
            ui.label({ text = package.version })
        })
        table.insert(updateRows, packageRow)
    end
    panel.render(ui.column({
        gap = 8,
        flexGrow = 1
    }, {
        ui.row({
            align = "center",
            justify = "space_between"
        }, {
            ui.column({ align = "start" }, {
                ui.label({ text = "Upgrades available", fontSize = 16, fontWeight = "bold" }),
                ui.label({ text = labelText })
            }),            
            #packages > 0 and ui.button({
                text = "Upgrade",
                glyph = "refresh",
                onClick = upgrade
            }) or nil
        }),
        #packages > 0 and ui.scroll({
            border = "outline",
            flexGrow = 1,
            gap = 16,
            radius = 8,
            padding = 16
        }, updateRows) or nil
    }))
end

function onOpen(context)
    render()
end

function update()
    noctalia.setUpdateInterval(5000)
    render()
end

noctalia.state.watch("updates", function(value: {[number]: {name: string, version: string, status: string}})
    packages = value
    render()
end)
