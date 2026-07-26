local packages: {[number]: {name: string, version: string, status: string}} = {}

function log(msg)
    local logsPath = noctalia.pluginDir() .. "/dnf_logs"
    local logsContent = noctalia.readFile(logsPath) or ""
    local newLog = `[ {os.date()} ]: {msg}\n`
    noctalia.writeFile(logsPath, logsContent .. newLog)
end

local function render()
    log('rendering panel')
    local labelText = noctalia.trp("updates", #packages)
    local updateRows: {UiNode} = {}
    for index, package in ipairs(packages) do
        local packageUI: UiNode = ui.row({align = "center", justify = "space_between"}, {
            ui.label({ text = package.name }),
            ui.label({ text = package.version })
        })
        table.insert(updateRows, packageUI)
    end
    log(updateRows)
    panel.render(ui.scroll({ gap = 8 }, {
        ui.row({ align = "center", justify = "space_between" }, {
            ui.column({ align = "start" }, {
                ui.label({ text = "Upgrades available", fontSize = 16, fontWeight = "bold" }),
                ui.label({ text = labelText })
            }),            
            #packages > 0 and ui.button({ text = "Upgrade", glyph = "refresh" }) or nil
        }),
        ui.scroll({gap = 8}, updateRows)
        -- table.unpack(updateRows)
    }))
end

function onOpen(context)
    render()
end

function onCloseClicked()
    panel.close()
end

function update()
    log('panel update function')
    noctalia.setUpdateInterval(1000)
    render()
end

noctalia.state.watch("updates", function(value: {[number]: {name: string, version: string, status: string}})
    log('received update')
    log(#value)
    packages = value
    render()
end)
