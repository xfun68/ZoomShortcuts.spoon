--- === ZoomShortcuts ===
---
--- Give you an chance to customize shortcuts for Zoom Annotate related operations.
---
--- git clone git@github.com:xfun68/ZoomShortcuts.spoon.git ~/.hammerspoon/Spoons/ZoomShortcuts.spoon

local obj = {}
obj.__index = obj

-- Metadata
obj.name = 'Zoom'
obj.version = '1.0'
obj.author = 'panda.wong <xfun68@gmail.com> <wechat@lazyist>'
obj.homepage = 'https://github.com/xfun68/ZoomShortcuts.spoon'
obj.license = 'https://en.wikipedia.org/wiki/Beerware#License'

local zoomAppName = 'zoom.us'
local zoomShareToolbarWindowTitle = 'zoom share toolbar window'
local zoomAnnotationPanelTitle = 'annotation panel'
local zoomAnnotationToolbarPopupMenuTitle = 'annotation toolbar popup menu'

zoomClickDelay = 50

-- _zsLog = hs.logger.new('ZoomShortcuts','info')

local function listPrint(list)
    list = list or {}
    for i = 1, #list do
        print('list['..i..'] = '..list[i])
    end
end

local function listPush(originList, item)
    originList[#originList + 1] = item
    return originList
end

local function listPushAll(originList, newList)
    newList = newList or {}
    hs.fnutils.ieach(newList, function (item)
        originList[#originList + 1] = item
    end)
    return originList
end

local function pointFromOffset(rect, offset)
    return {
        x = rect.x + (offset.x >= 0 and offset.x or (rect.w + offset.x)),
        y = rect.y + (offset.y >= 0 and offset.y or (rect.w + offset.y))
    }
end

local function pointsFromOffsets(rect, offsets)
    local points = {}
    for i, offset in pairs(offsets) do
        points[i] = {
            x = rect.x + (offset.x >= 0 and offset.x or (rect.w + offset.x)),
            y = rect.y + (offset.y >= 0 and offset.y or (rect.w + offset.y))
        }
    end
    return points
end

local function isTimerRunningFn(timer, target)
    return function()
        local isRunning = timer:running()
        -- _zsLog.v('timer for "'..target..'" is: '..hs.inspect(timer))
        return isRunning
    end
end

local function stopTimerFn(timer, target)
    return function()
        -- _zsLog.e('stop timer for "'..target..'": '..hs.inspect(timer))
        timer:stop()
    end
end

local function clickPoint(point)
    hs.mouse.setAbsolutePosition(point)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, point):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, point):post()
end

local function clickPoints(points, options)
    options = options or {}
    setmetatable(options, {__index = { interval = 100000 }})
    local interval = options.interval

    for i, point in pairs(points) do
        if i > 1 then
            -- _zsLog.d('Sleep click interval: '..interval)
            hs.timer.usleep(interval)
        end
        clickPoint(point)
        -- _zsLog.d('Clicked point['..i..']: '..hs.inspect(point))
    end
end

local function execOperationAsync(operations, index)
    index = index or 1
    local operationName = operations[index].name
    -- _zsLog.d('execute operations['..index..']: '..operationName)
    operations[index].action()

    if index == #operations then
        return
    end

    local timer = hs.timer.waitUntil(
        operations[index].predicate or function () return true end,
        function () execOperationAsync(operations, index + 1) end,
        0.1)

    -- _zsLog.v('start new timer for "'..operationName..'": '..hs.inspect(timer))

    hs.timer.doAfter(5, function()
        hs.timer.doWhile(isTimerRunningFn(timer, operationName), stopTimerFn(timer, operationName))
    end)
end

_zsOriginalMousePoint = hs.mouse.getAbsolutePosition()

local function zoomExecuteOperations(name, operations)
    operations = operations or {}

    _zsOriginalMousePoint = hs.mouse.getAbsolutePosition()

    local function restore()
        hs.mouse.setAbsolutePosition(_zsOriginalMousePoint)
    end

    local function showStartedAlert()
        hs.alert(name..' STARTED...')
    end

    local function showDoneAlert()
        hs.alert(name..' DONE')
    end

    local opShowStartedAlert = {name = 'showStartedAlert', action = showStartedAlert}
    local opRestore = {name = 'restore', action = restore}
    local opShowDoneAlert = {name = 'showDoneAlert', action = showDoneAlert}

    local extendedOperations = {}
    -- listPush(extendedOperations, opShowStartedAlert)
    listPushAll(extendedOperations, operations)
    listPush(extendedOperations, opRestore)
    -- listPush(extendedOperations, opShowDoneAlert)

    for i = 1, #extendedOperations do
        -- _zsLog.d('operations['..i..']: '..extendedOperations[i].name)
    end

    execOperationAsync(extendedOperations)
end

local function findZoomApplication()
    return hs.application.find(zoomAppName)
end

local function zoomFindShareToolbar()
    -- _zsLog.d('Find window "'..zoomShareToolbarWindowTitle..'"')
    local win = findZoomApplication():findWindow(zoomShareToolbarWindowTitle)
    -- _zsLog.d(win)
    return win
end

local function zoomFindAnnotatePanel()
    -- _zsLog.d('Find window "'..zoomAnnotationPanelTitle..'"')
    local win = findZoomApplication():findWindow(zoomAnnotationPanelTitle)
    -- _zsLog.d(win)
    return win
end

local function zoomFindAnnotatePopupMenu()
    -- _zsLog.d('Find window "'..zoomAnnotationToolbarPopupMenuTitle..'"')
    local win = findZoomApplication():findWindow(zoomAnnotationToolbarPopupMenuTitle)
    -- _zsLog.d(win)
    return win
end

local function zoomShowAnnotateStatus()
    local status = zoomFindAnnotatePanel() and "ON" or "OFF"
    hs.alert("Zoom annotate: "..status)
end

local function zoomShareToolbarClickAnnotate()
    local annotateOffset = { x = -128, y = 30 }
    clickPoint(pointFromOffset(zoomFindShareToolbar():frame(), annotateOffset))
end

local function zoomEnsureAnnotatePanelOpen()
    if zoomFindAnnotatePanel() then
        return
    end
    zoomShareToolbarClickAnnotate()
end

local function zoomEnsureAnnotatePanelClosed()
    if not zoomFindAnnotatePanel() then
        return
    end
    zoomShareToolbarClickAnnotate()
end

local function zoomShareToolbarClickAnnotateFn(isAnnotateOriginalyOn)
    return function()
        if not isAnnotateOriginalyOn then
            zoomShareToolbarClickAnnotate()
        end
    end
end

local function zoomRestoreAnnoatePanelFn(isAnnotateOriginalyOn)
    return function()
        if not isAnnotateOriginalyOn and zoomFindAnnotatePanel() then
            zoomShareToolbarClickAnnotate()
        end
    end
end

local function zoomAnnotatePanelClickClear()
    local clearOffset = { x = 590, y = 30 }
    clickPoint(pointFromOffset(zoomFindAnnotatePanel():frame(), clearOffset))
end

local function zoomAnnotatePanelClickSave()
    local saveOffset = { x = 640, y = 30 }
    clickPoint(pointFromOffset(zoomFindAnnotatePanel():frame(), saveOffset))
end

local function zoomAnnotatePopupMenuClickClearAllDrawings()
    local clearAllDrawingsOffset = { x = 110, y = 22 }
    clickPoint(pointFromOffset(zoomFindAnnotatePopupMenu():frame(), clearAllDrawingsOffset))
end

local function zoomWrapOpsWithinAnnotatePanel(operations)
    local isAnnotateOriginalyOn = zoomFindAnnotatePanel()
    local ensureAnnotatePanelOpen = {name = 'Ensure Annotate Panel Open', action = zoomShareToolbarClickAnnotateFn(isAnnotateOriginalyOn), predicate = zoomFindAnnotatePanel}
    local restoreAnnotatePanel = {name = 'Restore Annotate Panel', action = zoomRestoreAnnoatePanelFn(isAnnotateOriginalyOn)}

    local wrappedOps = {}
    listPush(wrappedOps, ensureAnnotatePanelOpen)
    listPushAll(wrappedOps, operations)
    listPush(wrappedOps, restoreAnnotatePanel)
    return wrappedOps
end

local function zoomAssertInSharing()
    if not zoomFindShareToolbar() then
        local message = 'Please ensure you are in meeting and sharing something.'
        hs.alert(message, 4)
        error(message)
    end
end

local function zoomAssertInSharingAndThen(operations)
    local opAssertInSharing = {name = 'ShareToolbar: assert present', action = zoomAssertInSharing}

    local wrappedOps = {}
    listPush(wrappedOps, opAssertInSharing)
    listPushAll(wrappedOps, operations)
    return wrappedOps
end

local zoomOpShowAnnotateStatus = {name = 'Zoom: show Annotate status', action = zoomShowAnnotateStatus}
local zoomOpEnsureAnnotatePanelOpen = {name = 'ShareToolbar: ensure annotate panel open', action = zoomEnsureAnnotatePanelOpen, predicate = zoomFindAnnotatePanel}
local zoomOpEnsureAnnotatePanelClosed = {name = 'ShareToolbar: ensure annotate panel closed', action = zoomEnsureAnnotatePanelClosed, predicate = function () return not zoomFindAnnotatePanel() end}
local zoomOpShareToolbarClickAnnotate = {name = 'ShareToolbar: click Annotate', action = zoomShareToolbarClickAnnotate}
local zoomOpAnnotatePanelClickClear = {name = 'AnnotatePanel: click Clear', action = zoomAnnotatePanelClickClear, predicate = zoomFindAnnotatePopupMenu}
local zoomOpAnnotatePanelClickSave = {name = 'AnnotatePanel: click Save', action = zoomAnnotatePanelClickSave}
local zoomOpAnnotatePopupMenuSelectClearAllDrawings = {name = 'AnnotatePopupMenu: select Clear All Drawings', action = zoomAnnotatePopupMenuClickClearAllDrawings}

function obj:zoomAnnotateToggle()
    zoomExecuteOperations('Zoom Toggle Annotate',
        zoomAssertInSharingAndThen({
            zoomOpShareToolbarClickAnnotate,
            zoomOpShowAnnotateStatus
    }))
end

function obj:zoomAnnotateTurnOn()
    zoomExecuteOperations('Zoom Turn On Annotate',
        zoomAssertInSharingAndThen({
            zoomOpEnsureAnnotatePanelOpen,
            zoomOpShowAnnotateStatus
    }))
end

function obj:zoomAnnotateTurnOff()
    zoomExecuteOperations('Zoom Turn Off Annotate',
        zoomAssertInSharingAndThen({
            zoomOpEnsureAnnotatePanelClosed,
            zoomOpShowAnnotateStatus
    }))
end

function obj:zoomAnnotateClearAllDrawings()
    zoomExecuteOperations('Zoom ClearAllDrawings',
        zoomAssertInSharingAndThen(
            zoomWrapOpsWithinAnnotatePanel({
                zoomOpAnnotatePanelClickClear,
                zoomOpAnnotatePopupMenuSelectClearAllDrawings
    })))
end

function obj:zoomAnnotateSave()
    zoomExecuteOperations('Zoom Save Annotate',
        zoomAssertInSharingAndThen(
            zoomWrapOpsWithinAnnotatePanel({
                zoomOpAnnotatePanelClickSave
    })))
end

function obj:bindHotKeys(mapping)
  local spec = {
    toggleAnnotate = hs.fnutils.partial(self.zoomAnnotateToggle, self),
    turnOnAnnotate = hs.fnutils.partial(self.zoomAnnotateTurnOn, self),
    turnOffAnnotate = hs.fnutils.partial(self.zoomAnnotateTurnOff, self),
    clearAllDrawings = hs.fnutils.partial(self.zoomAnnotateClearAllDrawings, self),
    saveAnnotate = hs.fnutils.partial(self.zoomAnnotateSave, self),
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end

return obj

