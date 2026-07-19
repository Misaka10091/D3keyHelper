# 应用开发规范

本目录描述 `src/d3keyhelper.ahk` 的运行时约定。D3KeyHelper 是 AutoHotkey v1.1 单脚本 Windows 桌面工具，不存在前端、后端或数据库分层。

## 规范索引

| 文档 | 适用场景 |
|---|---|
| [架构与代码组织](./architecture.md) | 修改启动流程、函数、标签子程序、全局状态或内嵌 GDI+ 代码 |
| [配置与 Profile](./configuration-and-profiles.md) | 新增或修改设置项、Profile 字段、配置迁移或文件管理 |
| [自动化与安全约束](./automation-and-safety.md) | 修改按键发送、鼠标操作、像素识别、背包批处理或计时器 |
| [GUI、热键与生命周期](./ui-hotkeys-and-lifecycle.md) | 修改控件、动态热键、窗口钩子、保存/退出行为 |
| [质量检查](./quality-guidelines.md) | 完成任何应用代码变更后进行验证 |

## 开发前检查

- [ ] 使用 AutoHotkey v1.1 语法；本项目不兼容 v2，最低版本由 `src/d3keyhelper.ahk` 中的 `AHK_MIN_VERSION` 声明。
- [ ] 先定位变更所属的现有区段：自动执行段、用户函数、辅助宏、检测/坐标函数、GUI 标签子程序、系统函数或内嵌 GDI+。
- [ ] 涉及配置字段时，阅读 [配置与 Profile](./configuration-and-profiles.md) 的读写闭环清单。
- [ ] 涉及自动点击或按键时，阅读 [自动化与安全约束](./automation-and-safety.md)，确认中断、超时、焦点和安全格逻辑。
- [ ] 涉及多个区域时，同时阅读 [`../guides/change-impact-checklist.md`](../guides/change-impact-checklist.md)。

## 质量检查

- [ ] 没有引入 AutoHotkey v2 专用语法或依赖。
- [ ] 所有新计时器、动态热键和按住的键都有对应的关闭/释放路径。
- [ ] 像素与鼠标坐标按游戏客户区和 `3440x1440` 基准缩放，没有直接使用未经换算的屏幕坐标。
- [ ] 配置字段的默认值、读取、界面状态、保存和必要的 schema 版本同步完成。
- [ ] 可用时运行 `scripts/build.cmd`；至少运行文档中的静态检查并完成与改动相称的手工冒烟验证。

