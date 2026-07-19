# 变更影响检查表

## 按变更类型检查

| 变更类型 | 必查位置与合同 |
|---|---|
| 全局设置 | `ReadCfgFile()` 默认对象与 `IniRead`、`generals`、应用设置 GUI、`ApplyAppSettings()`、`SaveCfgFile()`、`CONFIG_SCHEMA_VERSION`、README |
| Profile 字段 | `ReadCfgFile()`、`combats`/`others`、每个 Tab 控件、`SaveCfgFile()`、`CreateDefaultProfileFile()`、高级设置与运行时 `Set*` |
| Profile 文件管理 | 自动目录扫描/排序、`profileFiles` 与当前索引、保存前置、文件名校验、重名、至少保留一个 Profile、重载后的激活项 |
| 动态热键 | 旧绑定关闭、新绑定开启、`~*` 语义、空值、冲突控件、停止宏时注销、README 快捷键说明 |
| 战斗宏策略 | `MainMacro:` 三种启动方式、`RunMarco:`、`skillKey()`、队列、优先级/延迟、`StopMarco:`、Tab 暂停、失焦停止 |
| 新助手/自动点击 | `UtilityHelper()` 页面分派、页面多点识别、`helperRunning`/`helperBreak`、超时、鼠标归位、安全格、双格物品、确认框 |
| 像素或坐标 | `3440x1440` 基准缩放、左/中/右锚点、客户区与屏幕转换、Gamma、语言/覆盖层、截图资源释放、支持分辨率 |
| GUI 布局 | 完整/紧凑宽度、动态 Profile 控件、`showMainWindow()` 移动/重绘、保存与回填、标题栏鼠标钩子 |
| 原生资源/钩子 | `OnLoad()` 初始化、重复注册保护、回调限制、`OnUnload()` 释放、错误/早退路径 |
| 版本与发布 | AHK 版本指令、`DISPLAY_VERSION`、`build.ps1` 替换与校验、workflow tag/artifact/release、README 示例 |

## 数据流提问

对每个用户可见字段或动作，依次回答：

1. 用户从哪里输入或触发？
2. 输入在哪里校验，旧配置缺失时默认值是什么？
3. 值存放在 GUI 动态变量、对象还是全局状态中？
4. 哪个标签、函数、热键或计时器消费它？
5. 动作被取消、暂停、失焦或退出时如何清理？
6. 值何时保存，重启后如何恢复？
7. README、截图、构建或发布合同是否需要同步？

## 修改前搜索示例

```powershell
rg -n "字段名|控件变量|函数名|标签名" src README.md scripts .github
rg -n "SetTimer|Hotkey,|keysOnHold|helperBreak" src/d3keyhelper.ahk
rg -n "3440|1440|PixelGetColor|Gdip_BitmapFromScreen" src/d3keyhelper.ahk
```

不要只搜索一个拼写。AHK 动态变量可能把页码、技能号拼进名称，INI key 也可能使用小写或 `_N` 后缀。

## 完成前回看

- 配置：默认、读、显示、改、存、迁移是否闭环？
- 自动化：识别、动作、中断、超时、恢复是否闭环？
- 热键：解绑、绑定、触发、停止是否闭环？
- 构建：源标记、临时注入、元数据、文件名、artifact、release 是否闭环？

