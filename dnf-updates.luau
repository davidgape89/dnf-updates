-- local noctalia = require('Noctalia')
-- local barWidget = require('BarWidget')
local label = barWidget.getConfig("label")
local updatedGlyph = barWidget.getConfig("updated-glyph")
local notUpdatedGlyph = barWidget.getConfig("not-updated-glyph")
local showGlyph = barWidget.getConfig("show_glyph")
local showLabel = barWidget.getConfig("show_label")

local isUpdated = true
local updates = nil

local function render()
    if showGlyph then
        if isUpdated then
            barWidget.setGlyph(updatedGlyph)
            else
            barWidget.setGlyph(notUpdatedGlyph)
        end
    end

    if showLabel and not isUpdated then
        barWidget.setText(#updates)
    end

    if not updates then
        barWidget.setTooltip("Your system is up to date.")
        else
        barWidget.setTooltip(`There are {#updates} updates available.`)
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
