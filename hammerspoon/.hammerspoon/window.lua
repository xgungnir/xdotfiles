local obj = {}
obj.__index = obj
obj.hs = hs

-- Module state
obj.isMoving = false

-- Constants
local MOUSE_OFFSET_X = 5
local MOUSE_OFFSET_Y = 12
local RELEASE_DELAY = 0.6
local GAP = 8
local SPECIAL_APP_TITLES = {"Telegram"}  -- List of app names to match for special mouse adjustment

local function simulateKeyEvent(modifier, key)
   obj.hs.eventtap.event.newKeyEvent(modifier, true):post()
   obj.hs.eventtap.event.newKeyEvent(key, true):post()
   obj.hs.timer.doAfter(0, function() 
      obj.hs.eventtap.event.newKeyEvent(modifier, false):post()
      obj.hs.eventtap.event.newKeyEvent(key, false):post()
   end)
end

local function isSpecialApp(appName)
   if not appName then return false end
   local lowerAppName = appName:lower()
   for _, specialApp in ipairs(SPECIAL_APP_TITLES) do
      if lowerAppName:find(specialApp:lower(), 1, true) then
         return true
      end
   end
   return false
end

-- Shared helper to move window across spaces using coroutine + timer hybrid
local function moveWindowAcrossSpace(self, direction)
    if self.isMoving then return end
    self.isMoving = true

    -- Get current active window and make it frontmost
    local win = self.hs.window.focusedWindow()
    if not win then 
        self.isMoving = false
        return 
    end

    -- Guard: Finder Desktop pseudo-window can be larger than the screen resolution
    local app = win:application()
    local bundleID = app:bundleID()
    local screen = win:screen()
    local screenFrame = screen:frame()
    local winFrame = win:frame()
    if bundleID == "com.apple.finder" and 
       winFrame.w > screenFrame.w and 
       winFrame.h > screenFrame.h then
        self.isMoving = false
        return
    end

    win:unminimize()
    win:raise()

    -- Bounds check based on direction
    local spaces = self.hs.spaces.spacesForScreen()
    local currentSpace = self.hs.spaces.focusedSpace()
    if direction == "right" then
        if currentSpace == spaces[#spaces] then
            self.hs.alert.show("Already at the rightmost desktop.")
            self.isMoving = false
            return
        end
    else
        if currentSpace == spaces[1] then
            self.hs.alert.show("Already at the leftmost desktop.")
            self.isMoving = false
            return
        end
    end

    -- Positions and app info
    local frame = win:frame()
    local app = win:application()
    local appName = app and app:name() or ""
    local originalFrame = nil
    if isSpecialApp(appName) then
        originalFrame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
    end
    local clickPos = self.hs.geometry.point(frame.x + MOUSE_OFFSET_X, frame.y + MOUSE_OFFSET_Y)
    local centerPos = self.hs.geometry.point(frame.x + frame.w/2, frame.y + frame.h/2)


    -- Perform sequence in coroutine for reliable event processing
    local cr
    cr = coroutine.wrap(function()
        -- Move mouse to click position
        coroutine.applicationYield()
        self.hs.mouse.absolutePosition(clickPos)
        self.hs.timer.usleep(20000)

        -- mouseDown
        coroutine.applicationYield()
        self.hs.eventtap.event
          .newMouseEvent(self.hs.eventtap.event.types.leftMouseDown, clickPos)
          :post()
        self.hs.timer.usleep(30000)

        -- optional small drag for special apps
        if isSpecialApp(appName) then
            coroutine.applicationYield()
            local adjustedPos = self.hs.geometry.point(clickPos.x + 1, clickPos.y)
            self.hs.eventtap.event
              .newMouseEvent(self.hs.eventtap.event.types.leftMouseDragged, adjustedPos)
              :setProperty(self.hs.eventtap.event.properties.mouseEventDeltaX, 1)
              :post()
            self.hs.timer.usleep(20000)
        end

        -- trigger desktop switch immediately after initial sequence
        coroutine.applicationYield()
        if direction == "right" then
            simulateKeyEvent("ctrl", "right")
        else
            simulateKeyEvent("ctrl", "left")
        end

        cr = nil -- clear to avoid premature GC issues

        -- schedule release/restore after system animation period finishes
        self.hs.timer.doAfter(RELEASE_DELAY, function()
            local finalPos = self.hs.mouse.absolutePosition()
            self.hs.eventtap.event
              .newMouseEvent(self.hs.eventtap.event.types.leftMouseUp, finalPos)
              :post()
            if originalFrame then
                win:setFrame(originalFrame)
            end
            win:raise()
            win:focus()
            self.hs.mouse.absolutePosition(centerPos)
            self.hs.timer.doAfter(0.1, function()
                self.isMoving = false
            end)
        end)
    end)

    cr() -- start coroutine
end

function obj:move_window_to_next_desktop()
    moveWindowAcrossSpace(self, "right")
end

function obj:move_window_to_previous_desktop()
    moveWindowAcrossSpace(self, "left")
end

function obj:move_one_screen_north()
    local win = self.hs.window.focusedWindow()
    if win then
        win:moveOneScreenNorth(nil, true)
    end
end

function obj:move_one_screen_south()
    local win = self.hs.window.focusedWindow()
    if win then
        win:moveOneScreenSouth(nil, true)
    end
end

function obj:move_one_screen_west()
    local win = self.hs.window.focusedWindow()
    if win then
        win:moveOneScreenWest(nil, true)
    end
end

function obj:move_one_screen_east()
    local win = self.hs.window.focusedWindow()
    if win then
        win:moveOneScreenEast(nil, true)
    end
end

function obj:maximize_with_gap()
    local win = self.hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        if screen then
            local frame = screen:frame()
            local newFrame = {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = frame.w - 2 * GAP,
                h = frame.h - 2 * GAP
            }
            win:setFrame(newFrame)
            -- win:setFrameCorrectness(newFrame)
        end
    end
end

local function areFramesEqual(f1, f2)
    -- Using a small tolerance for floating point comparisons
    local tolerance = 1.5
    return math.abs(f1.x - f2.x) < tolerance and
           math.abs(f1.y - f2.y) < tolerance and
           math.abs(f1.w - f2.w) < tolerance and
           math.abs(f1.h - f2.h) < tolerance
end

function obj:resize_window(layouts)
    local win = self.hs.window.focusedWindow()
    if not win then return end

    local screen = win:screen()
    if not screen then return end

    local screenFrame = screen:frame()

    -- Calculate the target frames for the current screen
    local targetFrames = {}
    for i, layout_fn in ipairs(layouts) do
        targetFrames[i] = layout_fn(screenFrame)
    end

    local currentFrame = win:frame()

    -- Find if current window frame matches one of the layouts
    local currentLayoutIndex = -1
    for i, targetFrame in ipairs(targetFrames) do
        if areFramesEqual(currentFrame, targetFrame) then
            currentLayoutIndex = i
            break
        end
    end

    local nextFrame
    if currentLayoutIndex ~= -1 then
        -- Cycle to the next layout
        local nextLayoutIndex = (currentLayoutIndex % #targetFrames) + 1
        nextFrame = targetFrames[nextLayoutIndex]
    else
        -- Not in a known layout, so apply the first one
        nextFrame = targetFrames[1]
    end

    win:setFrame(nextFrame)
end

function obj:resize_left()
    local layouts = {
        -- 1/2 left
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = (frame.w / 2) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end,
        -- 1/3 left
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = (frame.w / 3) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end,
        -- 2/3 left
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = (frame.w * 2 / 3) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end
    }
    self:resize_window(layouts)
end

function obj:resize_right()
    local layouts = {
        -- 1/2 right
        function(frame)
            return {
                x = frame.x + (frame.w / 2) + (GAP / 2),
                y = frame.y + GAP,
                w = (frame.w / 2) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end,
        -- 1/3 right
        function(frame)
            return {
                x = frame.x + (frame.w * 2 / 3) + (GAP / 2),
                y = frame.y + GAP,
                w = (frame.w / 3) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end,
        -- 2/3 right
        function(frame)
            return {
                x = frame.x + (frame.w / 3) + (GAP / 2),
                y = frame.y + GAP,
                w = (frame.w * 2 / 3) - GAP - (GAP / 2),
                h = frame.h - (2 * GAP)
            }
        end
    }
    self:resize_window(layouts)
end

function obj:resize_up()
    local layouts = {
        -- 1/2 up
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = frame.w - (2 * GAP),
                h = (frame.h / 2) - GAP - (GAP / 2)
            }
        end,
        -- 1/3 up
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = frame.w - (2 * GAP),
                h = (frame.h / 3) - GAP - (GAP / 2)
            }
        end,
        -- 2/3 up
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + GAP,
                w = frame.w - (2 * GAP),
                h = (frame.h * 2 / 3) - GAP - (GAP / 2)
            }
        end
    }
    self:resize_window(layouts)
end

function obj:resize_down()
    local layouts = {
        -- 1/2 down
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + (frame.h / 2) + (GAP / 2),
                w = frame.w - (2 * GAP),
                h = (frame.h / 2) - (GAP / 2) - GAP
            }
        end,
        -- 1/3 down
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + (frame.h * 2 / 3) + (GAP / 2),
                w = frame.w - (2 * GAP),
                h = (frame.h / 3) - (GAP / 2) - GAP
            }
        end,
        -- 2/3 down
        function(frame)
            return {
                x = frame.x + GAP,
                y = frame.y + (frame.h / 3) + (GAP / 2),
                w = frame.w - (2 * GAP),
                h = (frame.h * 2 / 3) - (GAP / 2) - GAP
            }
        end
    }
    self:resize_window(layouts)
end

function obj:init()
    if not self.hs then
        error("Hammerspoon API not available")
        return
    end

    -- move window to next/previous desktop
    self.hs.hotkey.bind({"cmd", "ctrl"}, "i", function() self:move_window_to_next_desktop() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "u", function() self:move_window_to_previous_desktop() end)
    -- resize window
    self.hs.hotkey.bind({"cmd", "ctrl"}, "m", function() self:maximize_with_gap() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "h", function() self:resize_left() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "l", function() self:resize_right() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "k", function() self:resize_up() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "j", function() self:resize_down() end)
    -- move window to next screen
    self.hs.hotkey.bind({"cmd", "ctrl"}, "up", function() self:move_one_screen_north() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "down", function() self:move_one_screen_south() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "left", function() self:move_one_screen_west() end)
    self.hs.hotkey.bind({"cmd", "ctrl"}, "right", function() self:move_one_screen_east() end)
end

return obj
