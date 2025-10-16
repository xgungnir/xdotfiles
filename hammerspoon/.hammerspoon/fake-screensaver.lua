local obj = {}
obj.__index = obj
obj.hs = hs

obj.isActive = false
obj.canvases = {}
obj.blockerTap = nil
obj.lastLKeyTime = nil

local windowLevels = hs.canvas.windowLevels
local windowBehaviors = hs.canvas.windowBehaviors

local function getNow()
    return hs.timer.secondsSinceEpoch()
end

function obj:showOverlays()
    local screens = hs.screen.allScreens()
    for i, screen in ipairs(screens) do
        local frame = screen:fullFrame()
        local canvas = hs.canvas.new({ x = math.floor(frame.x), y = math.floor(frame.y), w = math.floor(frame.w), h = math.floor(frame.h) })

        -- Put above everything and on all spaces
        local level = (windowLevels and (windowLevels.screenSaver or windowLevels.overlay)) or hs.canvas.windowLevels.overlay
        canvas:level(level)
        canvas:behavior(windowBehaviors.canJoinAllSpaces)

        canvas[1] = {
            type = 'rectangle',
            action = 'fill',
            fillColor = { hex = '#000000', alpha = 1 },
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        }

        canvas:show()
        self.canvases[i] = canvas
    end
end

function obj:hideOverlays()
    for _, canvas in ipairs(self.canvases) do
        canvas:delete()
    end
    self.canvases = {}
end

function obj:startScreensaver()
    if self.isActive then return end
    self.isActive = true
    self.lastLKeyTime = nil

    -- Move cursor to bottom-right corner of the rightmost screen
    local screens = hs.screen.allScreens()
    local bestFrame = nil
    local bestRightEdge = nil
    for _, s in ipairs(screens) do
        local f = s:fullFrame()
        local rightEdge = f.x + f.w
        if not bestRightEdge or rightEdge > bestRightEdge then
            bestRightEdge = rightEdge
            bestFrame = f
        end
    end
    if bestFrame then
        local target = {
            x = math.floor(bestFrame.x + bestFrame.w - 1),
            y = math.floor(bestFrame.y + bestFrame.h - 1)
        }
        hs.mouse.absolutePosition(target)
    end

    self:showOverlays()

    local types = {
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.keyUp,
        hs.eventtap.event.types.flagsChanged,
        hs.eventtap.event.types.systemDefined,
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseUp,
        hs.eventtap.event.types.rightMouseDown,
        hs.eventtap.event.types.rightMouseUp,
        hs.eventtap.event.types.otherMouseDown,
        hs.eventtap.event.types.otherMouseUp,
        hs.eventtap.event.types.mouseMoved,
        hs.eventtap.event.types.scrollWheel,
    }

    local lKeyCode = hs.keycodes.map['l']

    self.blockerTap = hs.eventtap.new(types, function(event)
        if not self.isActive then return true end -- swallow just in case

        local etype = event:getType()

        -- Exit on left mouse double-click
        if etype == hs.eventtap.event.types.leftMouseDown then
            local clickStateProp = hs.eventtap.event.properties.mouseEventClickState
            local clickState = event:getProperty(clickStateProp)
            if clickState and clickState >= 2 then
                self:stopScreensaver()
                return true
            end
        end

        -- Exit on double-tap of 'l' with no modifiers
        if etype == hs.eventtap.event.types.keyDown then
            local flags = event:getFlags() or {}
            local hasMods = flags.cmd or flags.alt or flags.ctrl or flags.shift

            if not hasMods and event:getKeyCode() == lKeyCode then
                local isAutoRepeatProp = hs.eventtap.event.properties.keyboardEventAutorepeat
                local isRepeat = event:getProperty(isAutoRepeatProp) == 1
                if not isRepeat then
                    local now = getNow()
                    if self.lastLKeyTime and (now - self.lastLKeyTime) <= 0.35 then
                        self:stopScreensaver()
                        return true
                    else
                        self.lastLKeyTime = now
                    end
                end
            end
        end

        -- Swallow everything while active
        return true
    end)

    self.blockerTap:start()
end

function obj:stopScreensaver()
    if not self.isActive then return end
    self.isActive = false

    if self.blockerTap then
        self.blockerTap:stop()
        self.blockerTap = nil
    end

    self:hideOverlays()
    self.lastLKeyTime = nil
end

function obj:toggle()
    if self.isActive then
        self:stopScreensaver()
    else
        self:startScreensaver()
    end
end

function obj:init()
    if not self.hs then
        error("Hammerspoon API not available")
        return self
    end

    self.hs.hotkey.bind({ "ctrl", "shift", "alt", "cmd" }, "l", function()
        -- Only starts reliably; when active, events are swallowed intentionally
        if not self.isActive then
            self:startScreensaver()
        end
    end)

    return self
end

return obj
