# ZoomShortcuts Spoon

这是一个 Hammerspoon Spoon，即常说的插件。用于为 Zoom 的 开启/关闭 Annotate 以及清屏等常用功能设置自定义的快捷键。感谢 Zoom 的常年不作为，让我有机会实现这个项目。

**注意：**

1. 目前只支持正在共享的使用者进行自定义操作，对于观看共享的 Zoom 使用者，功能暂不可用；
2. 目前支持的可自定义快捷键的功能有：
    1. 开启 Annotate；
    2. 关闭 Annotate；
    3. Toggle Annotate 的开闭；
    4. 清屏，即常用的 `Clear All Drowings`；
    5. 保存当前的 annotation 为 PNG 图片或 PDF 文件；

## 如何开始

1. 安装 [Homebrew](https://brew.sh/)：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
1. 安装 [Hammerspoon](https://www.hammerspoon.org/)：`brew install hammerspoon`
1. 配置 Hammerspoon：`mkdir -p ~/.hammerspoon/Spoons && touch ~/.hammerspoon/init.lua`
1. 运行 Hammerspoon，可能需要进行 Privacy 设置，请参考：![privacy-setting](/images/privacy-setting.jpg)
1. 下载 ZoomShortcuts Spoon：`git clone git@github.com:xfun68/ZoomShortcuts.spoon.git ~/.hammerspoon/Spoons/ZoomShortcuts.spoon`
1. 配置 ZoomShortcuts Spoon：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/xfun68/Zoomshortcuts.spoon/master/scripts/config.sh)`

## 如何自定义快捷键

按照上述步骤安装、设置后，默认的绑定的快捷键如下：

1. F8：切换 Annotate 功能的开启、关闭；
2. F7：关闭 Annotate 功能；
3. F9：开启 Annotate 功能；
4. F10：清屏，即 `Clear All Drowings`；
5. F4：保存当前 annotation 到本地文件；

如需自定义为其它快捷键，可以编辑文件 `$HOME/.hammerspoon/init.lua`，找到下图中的代码进行修改。

![demo-hotkey-binding](/images/demo-default-hotkey-binding.jpg)

如下代码会将对应功能的快捷键设置为组合式的快捷键：

```lua
spoon.ZoomShortcuts:bindHotKeys({
    toggleAnnotate = {{'ctrl', 'shift'}, 't'},
    turnOnAnnotate = {{'ctrl', 'shift'}, 'o'},
    turnOffAnnotate = {{'ctrl', 'shift'}, 'i'},
    clearAllDrawings = {{'ctrl', 'shift'}, 'c'},
    saveAnnotate = {{'ctrl', 'shift'}, 's'},
})
```

建议设置为更简洁的快捷键形式，以方便在会议中的使用。

## 设置 Zoom 确保功能正常

请按照下图所示对 Zoom 进行设置，以确保该插件能够工作正常。

![zoom-setting-1](/images/zoom-setting-1.jpg)
![zoom-setting-2](/images/zoom-setting-2.jpg)
![zoom-setting-3](/images/zoom-setting-3.jpg)

设置后入会并共享，共享工具栏应该看起来像下面这样：

![zoom-setting-4](/images/zoom-setting-4.jpg)

重点确认：

* 最后一个选项是 `More`；
* 倒数第二个选项是 `Annotate`；

否则会影响该插件功能的正常使用。

## 其它注意事项

1. 该插件通过模拟鼠标事件的方式来完成自动化，偶尔会发生操作无效的情况，请重复尝试即可；
2. 有时会有卡顿情况发生，通常会在 5 秒左右恢复，不常发生。如遇到卡顿，请耐心等待，避免反复敲击快捷键；

