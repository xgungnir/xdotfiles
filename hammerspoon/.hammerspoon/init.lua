--
local function focus_other_screen() -- focuses the other screen
   local screen = hs.mouse.getCurrentScreen()
   local nextScreen = screen:next()
   local rect = nextScreen:fullFrame()
   local center = hs.geometry.rectMidPoint(rect)
   -- hs.mouse.setAbsolutePosition(center)
   hs.mouse.absolutePosition(center)
end

function get_window_under_mouse() -- from https://gist.github.com/kizzx2/e542fa74b80b7563045a
   local my_pos = hs.geometry.new(hs.mouse.absolutePosition())
   local my_screen = hs.mouse.getCurrentScreen()
   return hs.fnutils.find(hs.window.orderedWindows(), function(w)
      return my_screen == w:screen() and my_pos:inside(w:frame())
   end)
end

function activate_other_screen()
   focus_other_screen()
   local win = get_window_under_mouse()
   -- now activate that window
   win:focus()
end

hs.hotkey.bind({ "ctrl", "cmd" }, "s", function() -- does the keybinding
   activate_other_screen()
end)

-----
-----
-- -- Variables to manage double tap
local escapeKeyCode = 53      -- The keycode for the escape key
local lastEscPress = 0
local doubleTapInterval = 250 -- Time in milliseconds to consider for double tap

function switchToEnglishABC()
   -- Get current input source
   local currentSource = hs.keycodes.currentSourceID()

   -- Check if the current source is not English ABC, then switch
   if currentSource ~= "com.apple.keylayout.ABC" then
      hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
   end
end

-- Function to handle key tap event
-- local function handleKeyEvent(tapEvent)
local function handleKeyEvent(tapEvent)
   local event = hs.eventtap.event.types.keyUp
   local keyCode = tapEvent:getKeyCode()
   if keyCode == escapeKeyCode then
      local timeNow = hs.timer.secondsSinceEpoch() * 1000 -- Get time in milliseconds
      -- print("123123")
      if timeNow - lastEscPress < doubleTapInterval then
         -- Double tap detected within the interval
         switchToEnglishABC()
      end
      -- Update the last pressed time
      lastEscPress = timeNow
      return false -- Allow the event to propagate (this keeps the default behavior of the escape key)
   end

   return false -- Allow all other key events to propagate
end

-- Start listening for keyUp events
escTapEvent = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, handleKeyEvent)
escTapEvent:start()

-- Ensure the event tap is stopped when the Hammerspoon reloads or quits
hs.shutdownCallback = function()
   if escTapEvent then escTapEvent:stop() end
end
-----
-----
