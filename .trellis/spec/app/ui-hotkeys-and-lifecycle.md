# GUI、热键与生命周期

## GUI 控件约定

主界面由 `GuiCreate()` 构建。每个 Profile 对应一个 Tab，Profile 级控件使用动态变量名，例如：

```text
skillset%currentTab%s%A_Index%dropdown
skillset%currentTab%movingdropdown
skillset%currentTab%useskillqueueckbox
```

新增 Profile 控件时必须在所有 Tab 循环内创建，并检查这些消费点：初始化值、`Set*` 控件联动、`SaveCfgFile()`、运行时 `GuiControlGet`。不要只更新当前 Tab。

应用设置使用第二个 GUI（`Gui, 2:`）。新字段应在打开窗口时使用当前值回填，在 `ApplyAppSettings()` 中校验后再修改共享状态；无效输入应提示并保留可恢复的界面状态。

## 动态热键

动态热键遵循“先关闭旧绑定，再启用新绑定”的顺序：

- 助手键：`SetHelperKeybinding:`
- 战斗宏启动键：`SetStartRun:`
- 快速暂停：`SetQuickPause:`
- Profile 切换：`SetProfileKeybinding:`
- 技能触发键：`RunMarco:` / `StopMarco:`

继续使用项目现有的 `~*` 前缀语义，并在用 `A_ThisHotkey` 查表时像 `SwitchProfile:` 一样去掉 `~*`。空热键或禁用选项不能注册动态热键。

若一个控件选择会使另一个热键冲突或失效，应同步禁用相关控件。`SetStartRun:` 在鼠标右键作为启动键时禁用第六技能策略，是现有参考。

## 生命周期与保存

- 启动顺序由自动执行段固定：读取配置 → 创建 GUI → 托盘菜单 → `StartUp()` 注册联动/热键 → 必要时保存默认配置 → 显示窗口。
- 主窗口右上角左键路径调用 `GuiClose()`：保存并隐藏到托盘；右键路径通过一次性计时器调用 `GuiExit()`：保存并退出。
- 托盘的“保存所有设置”与 Profile 新增/重命名/删除前也会调用 `SaveCfgFile()`。任何新增退出入口或破坏性 Profile 操作都必须保持先保存的语义。
- `OnUnload()` 负责 GDI+、Shell Hook 和鼠标钩子清理。新增 DLL、钩子或原生资源必须在退出路径释放。

## 窗口钩子约束

`Watchdog()` 处理窗口创建/激活事件，并在主窗口前台时安装低级鼠标钩子，在失焦时卸载。`MouseMove()` 同时负责自绘标题栏悬停、按下、拖动和关闭动作。

- 不要重复安装未卸载的钩子；沿用 `hHookMouse` 句柄检查。
- 不要在低级鼠标钩子回调中直接 `ExitApp`。当前实现通过 `SetTimer, GuiExit, -1` 避免钩子链断裂。
- 修改标题栏尺寸或紧凑布局时，同步 `showMainWindow()` 中的控件移动和边框重绘。
- 修改 `d3only` 行为时，同时检查 `#If WinActive(...)`、`Watchdog()` 的失焦停止逻辑和标题文案。

## 常见遗漏

- 只注册新热键而没有关闭旧热键，导致一次操作触发多个回调。
- 只改变控件启用状态，没有更新保存值或运行时读取位置。
- 新增退出/隐藏路径但未保存配置，或新增原生资源但未在 `OnUnload()` 释放。
- 在当前 Profile 索引变化后仍使用旧的动态控件变量或 `profileFiles` 下标。

