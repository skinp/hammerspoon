-- VARIABLES
local caffeine = require("caffeine")
local reloadWatcher = nil
local appWatcher = nil
local screenWatcher = nil

hs.window.animationDuration = 0

hs.grid.MARGINX = 0
hs.grid.MARGINY = 0
hs.grid.GRIDWIDTH = 4
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

function applyDeskLayout(version)
  local macbookMonitor = "Built-in Retina Display"
  local centerMonitor = "LF32TU87"
  local rightMonitor = "S2719DGF"

  local deskLayoutWebFull = {
      {"Chrome", nil, centerMonitor, hs.layout.left75, nil, nil},
      -- {"iTerm2", nil, centerMonitor, hs.layout.right25, nil, nil},
      {"zoom.us", nil, centerMonitor, hs.layout.right25, nil, nil},
      {"iTerm2", nil, rightMonitor, hs.geometry.rect(0, 0, 1, 0.5), nil, nil},
      {"Mattermost", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"Google Chat", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"VS Code", nil, macbookMonitor, hs.layout.maximized, nil, nil},
  }

  local deskLayoutCodeFull = {
    {"Chrome", nil, macbookMonitor, hs.layout.maximized, nil, nil},
    -- {"iTerm2", nil, centerMonitor, hs.layout.right25, nil, nil},
    {"iTerm2", nil, rightMonitor, hs.geometry.rect(0, 0, 1, 0.5), nil, nil},
    {"Mattermost", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
    {"Google Chat", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
    {"VS Code", nil, centerMonitor, hs.layout.maximized, nil, nil},
  }

  local deskLayoutWebShort = {
      {"Chrome", nil, centerMonitor, hs.layout.left50, nil, nil},
      -- {"iTerm2", nil, centerMonitor, hs.layout.right25, nil, nil},
      {"iTerm2", nil, rightMonitor, hs.geometry.rect(0, 0, 1, 0.5), nil, nil},
      {"Mattermost", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"Google Chat", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
      {"VS Code", nil, macbookMonitor, hs.layout.maximized, nil, nil},
  }

  local deskLayoutCodeShort = {
    {"Chrome", nil, macbookMonitor, hs.layout.maximized, nil, nil},
    -- {"iTerm2", nil, centerMonitor, hs.layout.right25, nil, nil},
    {"iTerm2", nil, rightMonitor, hs.geometry.rect(0, 0, 1, 0.5), nil, nil},
    {"Mattermost", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
    {"Google Chat", nil, rightMonitor, hs.geometry.rect(0, 0.5, 1, 0.5), nil, nil},
    {"VS Code", nil, centerMonitor, hs.layout.left50, nil, nil},
  }

  if hs.screen.find(centerMonitor) ~= nil and hs.screen.find(rightMonitor) then
    -- mac
    hs.application.launchOrFocus("VS Code")
    -- right
    hs.application.launchOrFocus("Mattermost")
    hs.application.launchOrFocus("Google Chat")
    -- center
    hs.application.launchOrFocus("Google Chrome")
    hs.application.launchOrFocus("iTerm2")

    if version == "webfull" then
      hs.layout.apply(deskLayoutWebFull)
    end
    if version == "codefull" then
      hs.layout.apply(deskLayoutCodeFull)
    end
    if version == "webshort" then
      hs.layout.apply(deskLayoutWebShort)
    end
    if version == "codeshort" then
      hs.layout.apply(deskLayoutCodeShort)
    end

    vscode = hs.application.get("VS Code"):mainWindow():raise()
    chrome = hs.application.get("Google Chrome"):mainWindow():raise()
    chat = hs.application.get("Google Chat"):mainWindow():raise()
    mattermost = hs.application.get("Mattermost"):mainWindow():sendToBack()
  end

end

function applyDeskLayoutWebFull()
  applyDeskLayout("webfull")
end

function applyDeskLayoutCodeFull()
  applyDeskLayout("codefull")
end

function applyDeskLayoutWebShort()
  applyDeskLayout("webshort")
end

function applyDeskLayoutCodeShort()
  applyDeskLayout("codeshort")
end

-- WATCHERS + SERVICES
caffeine:start()

reloadWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
appWatcher = hs.application.watcher.new(appWatcherCallback):start()
screenWatcher = hs.screen.watcher.new(applyDeskLayoutCodeFull):start()

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

hs.hotkey.bind(fullmod, "1", applyDeskLayoutWebFull)
hs.hotkey.bind(fullmod, "2", applyDeskLayoutCodeFull)
hs.hotkey.bind(shortmod, "1", applyDeskLayoutWebShort)
hs.hotkey.bind(shortmod, "2", applyDeskLayoutCodeShort)
hs.hotkey.bind(fullmod, "L", hs.caffeinate.startScreensaver)
hs.hotkey.bind(fullmod, "S", spotifyTrack)
hs.hotkey.bind(fullmod, "K", toggleKeyboardLayout)
hs.hotkey.bind(fullmod, "C", function () hs.application.launchOrFocus("Google Chrome") end)
hs.hotkey.bind(fullmod, "I", function () hs.application.launchOrFocus("iTerm2") end)


-- YEY, everything's been loaded
hs.alert.show("hammerspoon ready!")
