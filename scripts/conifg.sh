#!/bin/bash

cat <<-EOF >> $HOME/.hammerspoon/init.lua

hs.loadSpoon("ZoomShortcuts")

spoon.ZoomShortcuts:bindHotKeys({
    toggleAnnotate = {{}, 'f8'},
    turnOnAnnotate = {{}, 'f9'},
    turnOffAnnotate = {{}, 'f7'},
    clearAllDrawings = {{}, 'f10'},
    saveAnnotate = {{}, 'f4'},
})

EOF

