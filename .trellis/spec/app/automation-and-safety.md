# 自动化与安全约束

本项目会发送键盘/鼠标输入并批量处理游戏物品。安全条件是功能合同的一部分，不是可选优化。

## 动作前置条件

- 战斗宏启动前通过 `getGameResulution()` 获取客户区尺寸；`d3only` 开启时获取失败必须停止并提示。
- `UtilityHelper()` 在战斗宏运行时直接返回，并先识别当前页面，再分派赌博、分解、魔盒、丢弃或拾取操作。
- 新的页面动作至少使用多个像素或区域特征确认页面状态。参考 `isSalvagePageOpen()`、`isKanaiCubeOpen()`、`isInventoryOpen()`，不要用单个脆弱像素直接触发破坏性操作。
- 页面识别要考虑语言、Gamma、覆盖层和按钮禁用态。`splitRGB()` 负责 Gamma 修正；`isKanaiCubeOpen()` 对非英文客户端使用 Y 偏移；分解流程会重新读取按钮颜色并跳过灰色按钮。

## 坐标系统

文件顶部把 Pixel 和 Mouse 坐标模式设为游戏客户区。现有游戏 UI 坐标以 `3440x1440` 为基准，主要按 `D3H/1440` 缩放：

- 左侧控件通常直接缩放 X/Y。
- 右侧背包使用 `D3W - ((3440 - baseX) * D3H / 1440)` 右对齐。
- 中央技能栏使用 `D3W/2` 相对定位。
- GDI+ 截图需要先由 `getGameXYonScreen()` 把客户区原点换成屏幕坐标。

新坐标必须放进命名明确的坐标/检测函数，并用 `Round()` 转成像素。不要把为某个分辨率临时测得的屏幕绝对坐标直接传给 `MouseMove` 或 `PixelGetColor`。

参考：`getSkillButtonBuffPos()`、`getInventorySpaceXY()`、`getKanaiCubeButtonPos()`、`scanInventorySpaceGDIP()`。

## 中断、超时与资源清理

- 再次触发助手或窗口焦点变化会设置 `helperBreak`。长循环和每个关键点击阶段都应检查它，并把 `helperRunning` 恢复为 `False`。
- 所有轮询都必须有时间或次数上限。现有模式包括 `A_TickCount` 与 `helperDelay` 的超时、`w>200` 防卡死、`skillQueue.Count()<1000` 的队列上限。
- 助手移动鼠标前记录位置，正常完成和中断路径应尽量恢复。参考 `oneButtonSalvageHelper()`、`oneButtonReforgeHelper()`。
- `RunMarco:` 创建的计时器、触发型动态热键和按住键必须在 `StopMarco:` 关闭或释放；新增动作也要接入同一清理路径。
- GDI+ 位图扫描必须成对执行锁定/解锁与释放。优先截取最小所需区域；`scanInventorySpaceGDIP()` 只抓取背包矩形，避免复制整个游戏画面。

## 物品安全

- `safezone` 是背包格编号集合。`scanInventorySpaceGDIP()` 在内容识别前先把安全格标记为 `0`，批处理函数必须跳过这些格子。
- 双格物品需要同步标记下半格，避免把下半格误认为独立物品。分解、升级/转化和丢弃逻辑中已有颜色变化检测。
- 破坏性操作必须区分页面、品质、禁用按钮和确认框。不要为追求速度跳过 `isDialogBoXOnScreen()`、空格检测或品质判断。
- 白/蓝/黄批量分解按钮可能被禁用；必须像 `UtilityHelper()` 当前逻辑一样检测高亮颜色后再点击。

## 按键发送

- 普通技能发送沿用 `{Blind}`，避免破坏用户当前修饰键状态。
- 左键技能在需要强制站立时，按下与释放 `forceStandingKey` 和鼠标键要成对执行。
- `keysOnHold` 是所有长按键的清理账本。新增长按动作必须登记，暂停/停止时才能可靠释放和恢复。
- 焦点保护由 `#If WinActive(...)` 与 `Watchdog()` 共同完成；`d3only` 开启时，游戏失去前台应停止战斗宏。

