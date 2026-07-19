# 配置与 Profile

## 两级配置模型

运行时配置分为两类：

- `settings.ini` 的 `[General]` 保存全局设置和当前激活的 Profile 文件名。
- `profiles/*.ini` 的 `[Profile]` 保存每个战斗配置的技能、间隔、优先级、触发键和 Profile 级行为。

`ReadCfgFile()` 会按文件名排序扫描 `profiles/*.ini`。Profile 显示名称来自去掉 `.ini` 后缀的文件名；`settings.ini` 不维护 Profile 清单。目录为空时创建 `profiles/配置1.ini`。这一自动发现行为由 `src/d3keyhelper.ahk` 的 `ReadCfgFile()` 和近期的 Profile 管理实现共同定义。

`settings.ini`、`profiles/`、编译产物均被 `.gitignore` 排除，属于用户本地状态。不要把个人配置提交到仓库或打进发布 ZIP。

## 新增或修改全局设置

一个全局字段通常需要形成以下闭环：

1. 在 `ReadCfgFile()` 开头的 `generals` 默认对象中给出无配置文件时的默认值。
2. 在已有配置分支中用 `IniRead` 提供兼容旧文件的默认值。
3. 将读取结果加入最终的 `generals` 对象。
4. 在 `GuiCreate()` 或 `ShowAppSettingsWindow()` 创建/回填对应控件。
5. 在 `ApplyAppSettings()` 或相关 `Set*` 函数中校验并应用界面值。
6. 在 `SaveCfgFile()` 中写回 `[General]`。
7. 若字段改变了持久化结构或旧配置解释方式，递增文件顶部的 `CONFIG_SCHEMA_VERSION`；它与应用发布版本无关。
8. 若用户可见，更新 `README.md` 的设置说明。

参考字段：`safezone`、`gameresolution`、`helperanimationdelay`、`helpermousespeed`。

## 新增或修改 Profile 字段

Profile 字段需要同步：

1. `ReadCfgFile()` 对每个 Profile 的 `IniRead` 与默认值。
2. `combats` 或 `others` 中的内存结构。
3. `GuiCreate()` 中每个 Tab 对应的控件和值。
4. `SaveCfgFile()` 对每个 `profileFiles[cSection]` 的写回。
5. `CreateDefaultProfileFile()` 的新 Profile 初始值。
6. 如果字段在“高级技能设置”中编辑，还要同步 `ShowSkillAdvancedWindow()` 与 `SaveSkillAdvanced:`。
7. 如果字段影响运行时热键/计时器，更新 `StartUp()` 调用的相应 `Set*` 函数。

参考字段：技能级 `priority_N`、`repeat_N`、`triggerbutton_N`，Profile 级 `useskillqueue`、`autostartmarco`。

## 文件格式与兼容性

- `createOrTruncateFile()` 使用 UTF-16 写入配置文件头；继续通过 AutoHotkey 的 `IniRead`/`IniWrite` 维护 INI，不要混用会改变编码或换行的通用文本写入。
- 读取旧配置时优先提供默认值并继续运行；当前行为是在 schema 不匹配时提示用户检查并重新保存，而不是拒绝启动。
- `CONFIG_SCHEMA_VERSION` 只在配置结构变化时递增。显示版本由 `DISPLAY_VERSION` 和构建脚本控制，不能用发布版本替代 schema 版本。
- Profile 文件名必须通过 `IsValidProfileName()` 的 Windows 文件名规则；新增、重命名、删除逻辑还要防止重名并保持至少一个 Profile。
- 在 Profile 文件操作前先调用 `SaveCfgFile()`，避免界面中尚未保存的数据丢失。`AddProfile:`、`RenameProfile:`、`DeleteProfile:` 已采用这一顺序。

## 禁止事项

- 不要重新在 `settings.ini` 中维护 Profile 数组或数量；目录扫描是唯一清单来源。
- 不要依赖 Profile 文件中的 `name` 字段作为显示名；当前读取逻辑以文件名为准。
- 不要只更新示例 `settings.ini` 或本地 `profiles/` 来实现默认值；这些文件不受版本控制，真正默认值在源码中。
- 不要静默覆盖无法解析的用户配置。对有风险的结构变化保留提示、默认值和重新保存路径。

