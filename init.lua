-- VARIABLES
local caffeine = require("caffeine")
local reloadWatcher = nil
local appWatcher = nil
local screenWatcher = nil

hs.window.animationDuration = 0

hs.grid.MARGINX = 0
hs.grid.MARGINY = 0
hs.grid.GRIDWIDTH = 6
hs.grid.GRIDHEIGHT = 2

-- FUNCTIONS
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

function spotifyTrack()
  if not hs.spotify.isPlaying() then
    return
  end

  local artist = hs.spotify.getCurrentArtist() or "Unknown artist"
  local album  = hs.spotify.getCurrentAlbum() or "Unknown album"
  local track  = hs.spotify.getCurrentTrack() or "Unknown track"
  local trackInfo = {
    title=track,
    subTitle=artist,
    informativeText=album,
  }

  local _cmd = 'tell application "Spotify" to artwork url of the current track'
  local ok, imageURL = hs.applescript.applescript(_cmd)
  if ok then
    trackInfo.contentImage = hs.image.imageFromURL(imageURL)
  end

  local notification = hs.notify.new(trackInfo)
  notification:send()
  hs.timer.doAfter(3, function () notification:withdraw() end)
end

function toggleKeyboardLayout()
  us = "U.S."
  ca = "Canadian French - CSA"
  if hs.keycodes.currentLayout() == us then
    hs.keycodes.setLayout(ca)
  else
    hs.keycodes.setLayout(us)
  end
end

function leftSplit()
  local win = hs.window.frontmostWindow()
  local w = hs.grid.GRIDWIDTH/2
  local h = hs.grid.GRIDHEIGHT
  hs.grid.set(win, hs.geometry(0, 0, w, h))
end

function rightSplit()
  local win = hs.window.frontmostWindow()
  local w = hs.grid.GRIDWIDTH/2
  local h = hs.grid.GRIDHEIGHT
  hs.grid.set(win, hs.geometry(w, 0, w, h))
end

function appWatcherCallback(name, event, app)
end

function applyDeskLayout()
  local macbookMonitor = "Built-in Retina Display"
  local centerMonitor = "LF32TU87"
  local rightMonitor = "S2719DGF"

  local deskLayout = {
      {"Chrome", nil, centerMonitor, hs.layout.left70, nil, nil},
      {"iTerm2", nil, centerMonitor, hs.layout.right30, nil, nil},
      {"Workplace Chat", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"WhatsApp", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"Mattermost", nil, rightMonitor, hs.geometry.rect(0, 0, 1, 0.5), nil, nil},
      {"VS Code", nil, macbookMonitor, hs.layout.maximized, nil, nil},
      {"Spotify", nil, macbookMonitor, hs.layout.maximized, nil, nil},
  }

  -- mac
  hs.application.launchOrFocus("Google Chrome")
  hs.application.launchOrFocus("iTerm2")
  -- center
  hs.application.launchOrFocus("WhatsApp")
  hs.application.launchOrFocus("Workplace Chat")
  hs.application.launchOrFocus("Mattermost")
  -- right
  hs.application.launchOrFocus("Spotify")
  hs.application.launchOrFocus("VS Code @ FB")

  if hs.screen.find(centerMonitor) ~= nil and hs.screen.find(rightMonitor) then
    hs.layout.apply(deskLayout)
  end
end

-- toggle an application: if frontmost: hide it. if not: activate/launch it
-- function toggleApplication(name)
--     local app = hs.application.find(name)
--     if not app or app:isHidden() then
--         hs.application.launchOrFocus(name)
--     elseif hs.application.frontmostApplication() ~= app then
--         app:activate()
--     else
--         app:hide()
--     end
-- end

-- WATCHERS + SERVICES
caffeine:start()

reloadWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
appWatcher = hs.application.watcher.new(appWatcherCallback):start()
screenWatcher = hs.screen.watcher.new(applyDeskLayout):start()

-- KEYS
shortmod = {"ctrl", "cmd"}
fullmod = {"ctrl", "alt", "cmd"}

-- BINDS
hs.hotkey.bind(shortmod, "M", hs.grid.maximizeWindow)
hs.hotkey.bind(shortmod, "H", hs.grid.pushWindowLeft)
hs.hotkey.bind(shortmod, "J", hs.grid.pushWindowDown)
hs.hotkey.bind(shortmod, "K", hs.grid.pushWindowUp)
hs.hotkey.bind(shortmod, "L", hs.grid.pushWindowRight)
hs.hotkey.bind(shortmod, "Y", hs.grid.resizeWindowThinner)
hs.hotkey.bind(shortmod, "U", hs.grid.resizeWindowShorter)
hs.hotkey.bind(shortmod, "I", hs.grid.resizeWindowTaller)
hs.hotkey.bind(shortmod, "O", hs.grid.resizeWindowWider)
hs.hotkey.bind(shortmod, "[", hs.grid.pushWindowPrevScreen)
hs.hotkey.bind(shortmod, "]", hs.grid.pushWindowNextScreen)
hs.hotkey.bind(shortmod, "A", leftSplit)
hs.hotkey.bind(shortmod, "D", rightSplit)

hs.hotkey.bind(fullmod, "D", applyDeskLayout)
hs.hotkey.bind(fullmod, "L", hs.caffeinate.startScreensaver)
hs.hotkey.bind(fullmod, "S", spotifyTrack)
hs.hotkey.bind(fullmod, "K", toggleKeyboardLayout)
hs.hotkey.bind(fullmod, "C", function () hs.application.launchOrFocus("Google Chrome") end)
hs.hotkey.bind(fullmod, "I", function () hs.application.launchOrFocus("iTerm2") end)


-- YEY, everything's been loaded
hs.alert.show("hammerspoon ready!")
