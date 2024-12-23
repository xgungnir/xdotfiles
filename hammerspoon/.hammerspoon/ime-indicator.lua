-- **************************************************
-- IME Indicator
-- Credit to https://github.com/xiaojundebug/hammerspoon-config
-- **************************************************

local obj = {
  hs = hs
}
obj.__index = obj

-- Module level variables
obj.canvases = {}
obj.lastSourceID = nil
obj.distributedNotification = nil
obj.indicatorSyncTimer = nil
obj.screenWatcher = nil

-- --------------------------------------------------
-- Configuration
obj.config = {
  -- Indicator height
  HEIGHT = 5,
  -- Indicator transparency
  ALPHA = 1,
  -- Linear gradient between multiple colors
  ALLOW_LINEAR_GRADIENT = false,
  -- Indicator colors
  IME_TO_COLORS = {
    -- Squirrel Input Method
    ['im.rime.inputmethod.Squirrel.Hans'] = {
      -- { hex = '#dc2626' },
      -- { hex = '#0ea5e9' },
      { hex = '#0ea5e9' }
    },
    ['im.rime.inputmethod.Squirrel.Hant'] = {
      { hex = '#0ea5e9' }
    }
  }
}

-- Draw indicator
function obj:draw(colors)
  local screens = self.hs.screen.allScreens()

  for i, screen in ipairs(screens) do
    local frame = screen:fullFrame()

    local canvas = self.hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = self.config.HEIGHT })
    canvas:level(self.hs.canvas.windowLevels.overlay)
    canvas:behavior(self.hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:alpha(self.config.ALPHA)

    if self.config.ALLOW_LINEAR_GRADIENT and #colors > 1 then
      local rect = {
        type = 'rectangle',
        action = 'fill',
        fillGradient = 'linear',
        fillGradientColors = colors,
        frame = { x = 0, y = 0, w = frame.w, h = self.config.HEIGHT }
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
          frame = { x = startX, y = startY, w = cellW, h = self.config.HEIGHT }
        }
        canvas[j] = rect
      end
    end

    canvas:show()
    self.canvases[i] = canvas
  end
end

-- Clear canvas content
function obj:clear()
  for _, canvas in ipairs(self.canvases) do
    canvas:delete()
  end
  self.canvases = {}
end

-- Update canvas display
function obj:update(sourceID)
  self:clear()

  local colors = self.config.IME_TO_COLORS[sourceID or self.hs.keycodes.currentSourceID()]

  if colors then
    self:draw(colors)
  end
end

function obj:handleInputSourceChanged()
  local currentSourceID = self.hs.keycodes.currentSourceID()

  if self.lastSourceID ~= currentSourceID then
    self:update(currentSourceID)
    self.lastSourceID = currentSourceID
  end
end

function obj:init()
  -- Input method change event listener
  -- Sometimes hs.keycodes.inputSourceChanged doesn't trigger, monitoring system events solves this
  -- Reference: https://github.com/Hammerspoon/hammerspoon/issues/1499
  self.distributedNotification = self.hs.distributednotifications.new(
    function() self:handleInputSourceChanged() end,
    -- or 'AppleSelectedInputSourcesChangedNotification'
    'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
  )

  -- Sync every second to avoid state desync due to missed event listeners
  self.indicatorSyncTimer = self.hs.timer.new(
    1,
    function() self:handleInputSourceChanged() end
  )

  -- Re-render when screen changes
  self.screenWatcher = self.hs.screen.watcher.new(
    function() self:update() end
  )

  -- Start all watchers
  self:start()

  -- Initial execution
  self:update()

  return self
end

-- Start all watchers
function obj:start()
  self.distributedNotification:start()
  self.indicatorSyncTimer:start()
  self.screenWatcher:start()
end

-- Stop all watchers
function obj:stop()
  self.distributedNotification:stop()
  self.indicatorSyncTimer:stop()
  self.screenWatcher:stop()
end

return obj
