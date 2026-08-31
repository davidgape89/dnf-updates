local UPGRADE_MESSAGE = "noctalia msg plugin davidgape89/dnf-updates:service all upgrade"

local defaultState: UpdateState = {
    isUpdated = true,
    needsRestart = false,
    updates = {},
}

local function upgrade()
    noctalia.runInTerminal(UPGRADE_MESSAGE)
    panel.close()
end

local function render()
    local current = noctalia.state.get("updateState") or defaultState
    local updates = current.updates or {}
    local labelText = noctalia.trp("updates", #updates)
    local updateRows: {UiNode} = {}
    for index, package in ipairs(updates) do
        local packageRow: UiNode = ui.row({align = "center", justify = "space_between"}, {
            ui.row({}, {
                ui.glyph({name = "arrow-bar-up"}),
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
            #updates > 0 and ui.button({
                text = "Upgrade",
                glyph = "refresh",
                onClick = upgrade
            }) or nil
        }),
        #updates > 0 and ui.scroll({
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
