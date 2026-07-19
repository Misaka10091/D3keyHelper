# 质量检查

仓库目前没有自动化测试套件。质量门由静态检查、Ahk2Exe 构建校验和针对改动的 Windows/Diablo III 手工冒烟测试组成。

## 必做静态检查

```powershell
git diff --check
rg -n "CONFIG_SCHEMA_VERSION|DISPLAY_VERSION|ReadCfgFile|SaveCfgFile|CreateDefaultProfileFile" src/d3keyhelper.ahk
rg -n "SetTimer|Hotkey,|keysOnHold|helperBreak|helperRunning" src/d3keyhelper.ahk
```

根据改动检查：

- 配置字段在默认、读取、GUI、应用、保存、默认 Profile 之间是否闭环。
- 每个 `SetTimer ... on/周期/-1` 是否有停止或自然结束路径。
- 动态 `Hotkey` 是否先关闭旧值，停止宏时是否关闭触发型热键。
- 所有 `{key Down}` 是否能通过正常停止、暂停和失焦路径释放。
- 像素坐标是否按客户区缩放，GDI+ 截图是否转换为屏幕坐标并释放资源。
- 本地 `settings.ini`、`profiles/`、`dist/` 是否仍未进入版本控制。

## 构建验证

安装带 Ahk2Exe 的 AutoHotkey v1.1 后运行：

```powershell
.\scripts\build.cmd
```

涉及发布版本时再运行：

```powershell
.\scripts\build.cmd -Version v1.5.0
```

构建脚本会验证编译器、`Unicode 64-bit.bin`、源文件版本指令、EXE FileVersion/ProductVersion 和 ZIP 产物。缺少 AutoHotkey 编译器时，应明确记录构建未执行，不能把静态检查描述为完整通过。

## 手工冒烟范围

按改动选择最小但完整的验证集：

- 启动/退出：首次运行能创建配置；保存、托盘隐藏、退出后能重新读取。
- Profile：自动发现、切换、新增、重命名、删除，重启后顺序和当前 Profile 正确。
- 战斗宏：三种启动方式；停止、Tab 暂停、失焦后没有遗留按住键或计时器。
- 动态热键：修改后旧键失效、新键生效，不与鼠标右键/技能键产生重复绑定。
- 助手宏：正确页面才执行；再次按键可中断；鼠标归位；安全格和双格物品不被误处理。
- 像素识别：至少覆盖受影响的分辨率、窗口模式、语言或 Gamma 条件。
- 构建/发布：开发构建显示合理版本；带 tag 版本构建的 EXE 和 ZIP 名称一致。

## 审查原则

- 自动化速度不能以删除页面确认、超时、中断或安全格检查为代价。
- 不要把本地某次屏幕颜色或个人 INI 当成通用合同；规则应落在源码默认值和多点检测中。
- 对单文件中的重复代码，先确认是否属于六技能、六十格背包或多 Profile 的结构性循环，再决定抽取；不要为了形式上的复用隐藏 AutoHotkey v1 的动态变量语义。

