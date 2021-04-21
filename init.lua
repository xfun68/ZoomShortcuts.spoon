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
local zoomShareMinibarWindowTitle = ''
local zoomShareMinibarPopupMenuWindowTitle = ''
local zoomAnnotationPanelTitle = 'annotation panel'
local zoomAnnotationToolbarPopupMenuTitle = 'annotation toolbar popup menu'

_zsZoomApp = nil
_zsShareToolbarWindow = nil
_zsShareMinibarWindow = nil
_zsShareMinibarPopupMenuWindow = nil
_zsAnnotationPannelWindow = nil
_zsAnnotationToolbarPopupMenuWindow = nil

_zsLog = hs.logger.new('ZoomShortcuts','info')

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
        _zsLog.i('postcondition checking timeout for operation: '..target)
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
    _zsLog.i('execute operations['..index..']: '..operationName)

    if not operations[index].precondition or operations[index].precondition() then
        operations[index].action()
    else
        _zsLog.i('precondition not satisfied, skip action of operation: '..operationName)
    end

    if index == #operations then
        return
    end

    local function postcondition()
        if operations[index].skipOnFailedPrecondition then
            return true
        end
        if operations[index].predicate then
            return operations[index].predicate()
        end
        return true
    end

    local timer = hs.timer.waitUntil(
        postcondition,
        function () execOperationAsync(operations, index + 1) end,
        0.1)

    -- _zsLog.v('start new timer for "'..operationName..'": '..hs.inspect(timer))

    hs.timer.doAfter(5, function()
        hs.timer.doWhile(isTimerRunningFn(timer, operationName), stopTimerFn(timer, operationName))
    end)
end

local _zsOriginalMousePoint = hs.mouse.getAbsolutePosition()

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
    if not _zsZoomApp then
        error('Zoom Application is not running or cannot be found by name "'..zoomAppName..'"!')
    end
    return _zsZoomApp
end

local function zoomFindAnnotatePanel()
    return _zsAnnotationPannelWindow
end

local function zoomAnnotatePanelIsOn()
    return _zsAnnotationPannelWindow
end

local function zoomAnnotatePanelIsOff()
    return not _zsAnnotationPannelWindow
end

local function zoomShareMinibarPopupMenuIsOn()
    return _zsShareMinibarPopupMenuWindow
end

local function zoomShareMinibarPopupMenuIsOff()
    return not _zsShareMinibarPopupMenuWindow
end

local function needToRestoreAnnotatePanelFn(isAnnotateOriginalyOn)
    return function ()
        if isAnnotateOriginalyOn then
            return not zoomFindAnnotatePanel()
        else
            return zoomFindAnnotatePanel()
        end
    end
end

local function zoomFindAnnotatePopupMenu()
    return _zsAnnotationToolbarPopupMenuWindow
end

local function zoomShowAnnotateStatus()
    local hsColorCollection = hs.drawing.color.definedCollections.hammerspoon
    local status = 'OFF'
    local fillColor = hsColorCollection.osx_red
    if zoomFindAnnotatePanel() then
        status = 'ON'
        fillColor = hsColorCollection.osx_green
    end
    hs.alert('Zoom Annotate: '..status, {fillColor = fillColor}, 0.7)
end

local function zoomShareToolbarClickAnnotate()
    local annotateOffset = { x = -128, y = 30 }
    clickPoint(pointFromOffset(_zsShareToolbarWindow:frame(), annotateOffset))
end

local function zoomShareMinibarClickViewOptions()
    local offset = { x = -38, y = 11 }
    clickPoint(pointFromOffset(_zsShareMinibarWindow:frame(), offset))
end

local function zoomShareMinibarPopupMenuClickAnnotate()
    local offset = { x = 60, y = 206 }
    clickPoint(pointFromOffset(_zsShareMinibarPopupMenuWindow:frame(), offset))
end

local function zoomAnnotatePanelClickClear()
    local clearOffset = { x = -90, y = 30 }
    clickPoint(pointFromOffset(zoomFindAnnotatePanel():frame(), clearOffset))
end

local function zoomAnnotatePanelClickSave()
    local saveOffset = { x = -40, y = 30 }
    clickPoint(pointFromOffset(zoomFindAnnotatePanel():frame(), saveOffset))
end

local function zoomAnnotatePopupMenuClickClearAllDrawings()
    local clearAllDrawingsOffset = { x = 110, y = 22 }
    clickPoint(pointFromOffset(zoomFindAnnotatePopupMenu():frame(), clearAllDrawingsOffset))
end

local function zoomAssertInSharing()
    if _zsShareToolbarWindow or _zsShareMinibarWindow then
        return
    end

    local message = 'Please ensure you are in meeting and sharing something.'
    hs.alert(message, 4)
    error(message)
end

local function withPrecondition(precondition, operations)
    for i, operation in pairs(operations) do
        operation.precondition = precondition
    end
    return operations
end

local function wrapWithConditions(precondition, operations, postcondition)
    operations[1].precondition = precondition
    operations[#operations].predicate = postcondition
    return operations
end

local function opAssertInSharing()
    return { name = 'assert in sharing', action = zoomAssertInSharing }
end

local function opsToClickAnnotateButton()
    if _zsShareToolbarWindow then
        return {
            { name = 'ShareToolbar: click Annotate', action = zoomShareToolbarClickAnnotate }
        }
    elseif _zsShareMinibarWindow then
        return {
            {
                name = 'ShareMiniBar: click ViewOptions',
                skipOnFailedPrecondition = true,
                action = zoomShareMinibarClickViewOptions,
                predicate = zoomShareMinibarPopupMenuIsOn
            },
            {
                name = 'ShareMiniBarPopUpMenu: click Annotate',
                precondition = zoomShareMinibarPopupMenuIsOn,
                action = zoomShareMinibarPopupMenuClickAnnotate
            }
        }
    else
        local message = 'No one is sharing!'
        hs.alert(message, 4)
        error(message)
    end
end

local function opsToEnsureAnnotatePanelOpen()
    return wrapWithConditions(
        zoomAnnotatePanelIsOff,
        opsToClickAnnotateButton(),
        zoomAnnotatePanelIsOn
    )
end

local function opsToEnsureAnnotatePanelClosed()
    return wrapWithConditions(
        zoomAnnotatePanelIsOn,
        opsToClickAnnotateButton(),
        zoomAnnotatePanelIsOff
    )
end

local function opsAnnotatePanelClickClear()
    return {
        {
            name = 'AnnotatePanel: click Clear',
            action = zoomAnnotatePanelClickClear,
            predicate = zoomFindAnnotatePopupMenu
        }
    }
end

local function opsAnnotatePopupMenuSelectClearAllDrawings()
    return {
        {
            name = 'AnnotatePopupMenu: select Clear All Drawings',
            action = zoomAnnotatePopupMenuClickClearAllDrawings
        }
    }
end

local function opsAnnotatePanelClickSave()
    return {
        {
            name = 'AnnotatePanel: click Save',
            action = zoomAnnotatePanelClickSave
        }
    }
end

local function opsToShowAnnotateStatus()
    return {
        { name = 'Zoom: show Annotate status', action = zoomShowAnnotateStatus }
    }
end

local function isWindowShareToolbar(window)
    return  window:title() == zoomShareToolbarWindowTitle
end

local function isWindowShareMinibar(window)
    return  window:title() == zoomShareMinibarWindowTitle
        and window:size().h < 30
end

local function isWindowShareMinibarPopupMenu(window)
    return  window:title() == zoomShareMinibarPopupMenuWindowTitle
        and window:size().h > 100
end

local function isWindowAnnotatePanel(window)
    return  window:title() == zoomAnnotationPanelTitle
end

local function isWindowAnnotateToolbarPopupMenu(window)
    return  window:title() == zoomAnnotationToolbarPopupMenuTitle
end

local function bindWindow(window, appName)
    if isWindowShareToolbar(window) then
        _zsShareToolbarWindow = window
    end
    if isWindowShareMinibar(window) then
        _zsShareMinibarWindow = window
    end
    if isWindowShareMinibarPopupMenu(window) then
        _zsShareMinibarPopupMenuWindow = window
    end
    if isWindowAnnotatePanel(window) then
        _zsAnnotationPannelWindow = window
    end
    if isWindowAnnotateToolbarPopupMenu(window) then
        _zsAnnotationToolbarPopupMenuWindow = window
    end
end

local function unbindWindow(window, appName)
    if _zsShareToolbarWindow and _zsShareToolbarWindow:id() == window:id() then
        _zsShareToolbarWindow = nil
    end
    if _zsShareMinibarWindow and _zsShareMinibarWindow:id() == window:id() then
        _zsShareMinibarWindow = nil
    end
    if _zsShareMinibarPopupMenuWindow and _zsShareMinibarPopupMenuWindow:id() == window:id() then
        _zsShareMinibarPopupMenuWindow = nil
    end
    if _zsAnnotationPannelWindow and (_zsAnnotationPannelWindow:id() == window:id()) then
        _zsAnnotationPannelWindow = nil
    end
    if _zsAnnotationToolbarPopupMenuWindow and (_zsAnnotationToolbarPopupMenuWindow:id() == window:id()) then
        _zsAnnotationToolbarPopupMenuWindow = nil
    end
end

local _zsZoomAppWatcher = nil

function obj:init()
    _zsZoomApp = hs.application.find(zoomAppName)

    if _zsZoomApp then
        for key, window in pairs(_zsZoomApp:allWindows()) do
            bindWindow(window, zoomAppName)
        end
    end

    _zsZoomAppWatcher = hs.application.watcher.new(function (name, eventType, app)
        if eventType == hs.application.watcher.launched then
            _zsZoomApp = app
        elseif eventType == hs.application.watcher.terminated then
            _zsZoomApp = nil
        end
    end)

    _zsWindowFilter = hs.window.filter.new(function (window)
        return isWindowShareToolbar(window)
            or isWindowShareMinibar(window)
            or isWindowShareMinibarPopupMenu(window)
            or isWindowAnnotatePanel(window)
            or isWindowAnnotateToolbarPopupMenu(window)
    end)
end

function obj:start()
    _zsZoomAppWatcher:start()
    _zsWindowFilter:subscribe(hs.window.filter.windowCreated, bindWindow)
    _zsWindowFilter:subscribe(hs.window.filter.windowDestroyed, unbindWindow)
end

function obj:stop()
    _zsZoomAppWatcher:stop()
    _zsWindowFilter:unsubscribe({
        hs.window.filter.windowCreated,
        hs.window.filter.windowDestroyed
    })
end

function obj:zoomAnnotateToggle()
    local operations = { opAssertInSharing() }
    listPushAll(operations, opsToClickAnnotateButton())
    listPushAll(operations, opsToShowAnnotateStatus())
    zoomExecuteOperations('Zoom Toggle Annotate', operations)
end

function obj:zoomAnnotateTurnOn()
    local operations = { opAssertInSharing() }
    listPushAll(operations, opsToEnsureAnnotatePanelOpen())
    listPushAll(operations, opsToShowAnnotateStatus())
    zoomExecuteOperations('Zoom Turn On Annotate', operations)
end

function obj:zoomAnnotateTurnOff()
    local operations = { opAssertInSharing() }
    listPushAll(operations, opsToEnsureAnnotatePanelClosed())
    listPushAll(operations, opsToShowAnnotateStatus())
    zoomExecuteOperations('Zoom Turn Off Annotate', operations)
end

function obj:zoomAnnotateClearAllDrawings()
    local operations = { opAssertInSharing() }
    listPushAll(operations, opsToEnsureAnnotatePanelOpen())
    listPushAll(operations, opsAnnotatePanelClickClear())
    listPushAll(operations, opsAnnotatePopupMenuSelectClearAllDrawings())
    listPushAll(operations, withPrecondition(
        needToRestoreAnnotatePanelFn(zoomFindAnnotatePanel()),
        opsToClickAnnotateButton()))
    zoomExecuteOperations('Zoom ClearAllDrawings', operations)
end

function obj:zoomAnnotateSave()
    local operations = { opAssertInSharing() }
    listPushAll(operations, opsToEnsureAnnotatePanelOpen())
    listPushAll(operations, opsAnnotatePanelClickSave())
    listPushAll(operations, withPrecondition(
        needToRestoreAnnotatePanelFn(zoomFindAnnotatePanel()),
        opsToClickAnnotateButton()))
    zoomExecuteOperations('Zoom Save Annotate', operations)
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

