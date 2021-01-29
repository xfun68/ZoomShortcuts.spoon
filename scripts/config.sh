#!/bin/bash

cat <<-EOF >> $HOME/.hammerspoon/init.lua

hs.loadSpoon("ZoomShortcuts")

spoon.ZoomShortcuts:bindHotKeys({
    turnOnAnnotate = {{}, 'f1'},
    turnOffAnnotate = {{}, 'f2'},
    saveAnnotate = {{}, 'f3'},
    toggleAnnotate = {{}, 'f4'},
    clearAllDrawings = {{}, 'f5'},
})

spoon.ZoomShortcuts:start()

EOF

