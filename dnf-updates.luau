local updatedGlyph = barWidget.getConfig("updated-glyph")
local notUpdatedGlyph = barWidget.getConfig("not-updated-glyph")
local needsRestartGlyph = barWidget.getConfig("needs-restart-glyph")
local showGlyph = barWidget.getConfig("show_glyph")
local showLabel = barWidget.getConfig("show_label")

local isUpdated = true
local updates = nil
local needsRestarting = false

local function render()
    if showGlyph then
        if isUpdated then
            if needsRestarting then
                barWidget.setGlyph(needsRestartGlyph)
                else
                barWidget.setGlyph(updatedGlyph)
            end
            else
            barWidget.setGlyph(notUpdatedGlyph)
        end
    end

    if showLabel then
        if not isUpdated then
            barWidget.setText(#updates)
            else
            barWidget.setText("")
        end
    end

    if not updates then
        if needsRestarting then
            barWidget.setTooltip(noctalia.tr("rebootNecessary"))
            else
            barWidget.setTooltip(noctalia.tr("updatedSystem"))
        end
        else
        barWidget.setTooltip(noctalia.trp("updates", #updates))
    end
end

function update()
  noctalia.setUpdateInterval(1000)
  render()
end

noctalia.state.watch("isUpdated", function(value: boolean)
    isUpdated = value
    render()
end)

noctalia.state.watch("updates", function(value: string)
    updates = value
    render()
end)

noctalia.state.watch("needsRestarting", function(value: boolean)
    needsRestarting = value
    render()
end)
