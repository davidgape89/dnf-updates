local updatedGlyph = noctalia.getConfig("updated-glyph")
local notUpdatedGlyph = noctalia.getConfig("not-updated-glyph")
local needsRestartGlyph = noctalia.getConfig("needs-restart-glyph")
local showGlyph = noctalia.getConfig("show_glyph")
local showLabel = noctalia.getConfig("show_label")

noctalia.setUpdateInterval(1000)

local updateState: UpdateState = {
    isUpdated = true,
    needsRestart = false,
    updates = {},
}

local function render()
    if showGlyph then
        if updateState.isUpdated then
            if updateState.needsRestart then
                barWidget.setGlyph(needsRestartGlyph)
                else
                barWidget.setGlyph(updatedGlyph)
            end
            else
            barWidget.setGlyph(notUpdatedGlyph)
        end
    end

    if showLabel then
        if not updateState.isUpdated then
            barWidget.setText(tostring(#updateState.updates))
            else
            barWidget.setText("")
        end
    end

    if not updateState.updates then
        if updateState.needsRestart then
            barWidget.setTooltip(noctalia.tr("rebootNecessary"))
            else
            barWidget.setTooltip(noctalia.tr("updatedSystem"))
        end
        else
        barWidget.setTooltip(noctalia.trp("updates", #updateState.updates))
    end
end

function update()
    render()
end

function onClick()
    if not updateState.isUpdated then
        noctalia.togglePanel("davidgape89/dnf-updates:updates-panel")
    end
end

noctalia.state.watch("updateState", function(value: UpdateState)
    updateState = value
end)
