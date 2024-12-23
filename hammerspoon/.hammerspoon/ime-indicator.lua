-- **************************************************
-- IME Indicator
-- Credit to https://github.com/xiaojundebug/hammerspoon-config
-- **************************************************

-- --------------------------------------------------
-- Indicator height
local HEIHGT = 5
-- Indicator transparency
local ALPHA = 1
-- Linear gradient between multiple colors
local ALLOW_LINEAR_GRADIENT = false
-- Indicator colors
local IME_TO_COLORS = {
  -- Squirrel Input Method
  ['im.rime.inputmethod.Squirrel.Hans'] = {
    -- { hex = '#dc2626' },
    -- { hex = '#eab308' },
    { hex = '#0ea5e9' }
  },
  ['im.rime.inputmethod.Squirrel.Hant'] = {
    { hex = '#0ea5e9' }
  }
}
-- --------------------------------------------------

local canvases = {}
local lastSourceID = nil

-- Draw indicator
local function draw(colors)
  local screens = hs.screen.allScreens()

  for i, screen in ipairs(screens) do
    local frame = screen:fullFrame()

    local canvas = hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = HEIHGT })
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:alpha(ALPHA)

    if ALLOW_LINEAR_GRADIENT and #colors > 1 then
      local rect = {
        type = 'rectangle',
        action = 'fill',
        fillGradient = 'linear',
        fillGradientColors = colors,
        frame = { x = 0, y = 0, w = frame.w, h = HEIHGT }
      }
      canvas[1] = rect
    else
      local cellW = frame.w / #colors

      for j, color in ipairs(colors) do
        local startX = (j - 1) * cellW
        local startY = 0
        local rect = {
          type = 'rectangle',
          action = 'fill',
          fillColor = color,
          frame = { x = startX, y = startY, w = cellW, h = HEIHGT }
        }
        canvas[j] = rect
      end
    end

    canvas:show()
    canvases[i] = canvas
  end
end

-- Clear canvas content
local function clear()
  for _, canvas in ipairs(canvases) do
    canvas:delete()
  end
  canvases = {}
end

-- Update canvas display
local function update(sourceID)
  clear()

  local colors = IME_TO_COLORS[sourceID or hs.keycodes.currentSourceID()]

  if colors then
    draw(colors)
  end
end

local function handleInputSourceChanged()
  local currentSourceID = hs.keycodes.currentSourceID()

  if lastSourceID ~= currentSourceID then
    update(currentSourceID)
    lastSourceID = currentSourceID
  end
end

-- Input method change event listener
-- Sometimes hs.keycodes.inputSourceChanged doesn't trigger, monitoring system events solves this
-- Reference: https://github.com/Hammerspoon/hammerspoon/issues/1499
imi_dn = hs.distributednotifications.new(
  handleInputSourceChanged,
  -- or 'AppleSelectedInputSourcesChangedNotification'
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
-- Sync every second to avoid state desync due to missed event listeners
imi_indicatorSyncTimer = hs.timer.new(1, handleInputSourceChanged)
-- Re-render when screen changes
imi_screenWatcher = hs.screen.watcher.new(update)

imi_dn:start()
imi_indicatorSyncTimer:start()
imi_screenWatcher:start()

-- Initial execution
update()
