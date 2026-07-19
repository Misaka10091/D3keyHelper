# 架构与代码组织

## 实际架构

产品代码集中在 `src/d3keyhelper.ahk`。单文件结构是当前项目的明确选择：文件末尾只内嵌项目使用到的 GDI+ 函数，以便源码和编译产物不依赖额外运行时文件。不要按 Web 项目的方式人为拆成 frontend/backend/service 层。

主要运行区段如下：

1. 文件顶部的自动执行段设置 AutoHotkey 指令、工作目录、坐标模式、版本常量，并读取配置。
2. `OnLoad()` 通过静态初始化器在普通语句前建立共享状态、加载 DLL 并创建位图资源。
3. 自动执行段依次调用 `GuiCreate()`、`SetTrayMenu()`、`StartUp()`，必要时创建默认配置，再显示主窗口并注册 `OnExit()`。
4. 普通函数负责配置、宏执行、坐标/颜色检测和系统互操作。
5. `ShowAbout:` 至 `forceMoving:` 一带的标签子程序承接 GUI 事件、动态热键和计时器回调。
6. 文件末尾保留经过裁剪的 GDI+ 与显示器辅助函数。

来源：`src/d3keyhelper.ahk` 中的自动执行段、`OnLoad()`、`StartUp()`、`RunMarco:`、`StopMarco:` 和“GDIP库文件”区段。

## 组织新代码

- 将代码放在与职责相同的现有区段附近。页面识别函数应靠近 `isSalvagePageOpen()`、`isKanaiCubeOpen()` 等检测函数；坐标换算应靠近 `getInventorySpaceXY()`；GUI 回调应留在标签子程序区。
- 优先扩展已有入口和状态机，不要为同一热键或同一助手功能建立第二套并行流程。例如助手宏统一从 `UtilityHelper()` 做页面分派，战斗宏统一由 `MainMacro:`、`RunMarco:`、`StopMarco:` 管理。
- 新的普通函数应先使用 `local`，再显式列出所需 `Global`。只有 `GuiCreate()`、`Watchdog()` 这类确实依赖大量动态 GUI 变量的生命周期函数，才沿用宽泛的 `Global`。
- 保持函数注释包含用途、参数与返回值；项目中的 `ReadCfgFile()`、`skillKey()`、`getGameResulution()` 是可参考的格式。
- 不要仅为“模块化”把内嵌 GDI+ 拆成外部文件。若确需新增第三方代码，应同时设计源码运行、Ahk2Exe 编译和发布包中的依赖路径。

## 状态与控制流

AutoHotkey v1 的 GUI 变量和标签子程序天然依赖共享状态。当前核心状态包括：

- 战斗宏：`vRunning`、`vPausing`、`keysOnHold`、`skillQueue`、`syncTimer`、`syncDelay`。
- 助手宏：`helperRunning`、`helperBreak`、`helperDelay`、`mouseDelay`、`helperBagZone`。
- 配置/Profile：`currentProfile`、`profileFiles`、`combats`、`others`、`generals`、`safezone`。
- 游戏环境：`D3W`、`D3H`、`gameX`、`gameY`、`d3only`、`gameResolution`。

修改共享状态时必须同时追踪其创建、置位、消费和清理位置。特别是：

- `RunMarco:` 创建计时器、动态热键和按住状态；`StopMarco:` 必须关闭并释放它们。
- `UtilityHelper()` 设置 `helperRunning`/`helperBreak`；每个助手完成、取消或早退路径都要恢复可再次运行的状态。
- GUI 控件值通常由 `GuiControlGet` 在动作发生时读取，不要假定启动时的 `generals`/`others` 对象会持续反映界面最新值。

## 不要采用的模式

- 不要引入 AutoHotkey v2 的 `Map`、新式热键或函数调用语法。
- 不要在标签子程序与普通函数之间复制同一状态转换；先寻找已有 `Set*`、`RunMarco:`、`StopMarco:` 或检测函数。
- 不要在鼠标钩子回调中直接退出应用。`MouseMove()` 已说明直接退出会破坏钩子链；应通过一次性 `SetTimer` 调度 `GuiExit`。
- 不要把构建时版本写回 `src/d3keyhelper.ahk`；版本注入由 `scripts/build.ps1` 的临时源文件完成。

