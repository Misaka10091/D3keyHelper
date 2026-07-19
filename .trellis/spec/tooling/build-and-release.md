# 构建与发布

## 单一构建入口

`scripts/build.ps1` 是构建和打包的唯一实现，`scripts/build.cmd` 只负责用 Windows PowerShell 调用它并透传参数。GitHub Actions 也直接调用 `build.ps1`。

不要在 workflow、cmd 文件或其他脚本中复制编译、版本注入或压缩逻辑。需要新行为时先扩展 `build.ps1`，CI 只负责准备依赖和验证流水线结果。

## 编译器发现与目标

`Find-Ahk2Exe` 的优先级为：

1. `-CompilerPath`
2. `AHK2EXE` 环境变量
3. `Program Files` / `Program Files (x86)` 默认位置
4. `PATH` 中的 `Ahk2Exe.exe`

编译必须使用 AutoHotkey v1 的 `Unicode 64-bit.bin`。找不到编译器、基文件或 `src/d3keyhelper.ahk` 时立即失败，不要静默切换 AutoHotkey v2 或其他位数。

默认产物为：

- `dist/D3keyHelper.exe`
- `dist/D3keyHelper-v<version>-windows-x64.zip`

ZIP 当前只包含 EXE。用户配置由应用首次运行生成，不进入发布包。

## 版本合同

`-Version` 接受可选 `v` 前缀以及三段或四段纯数字版本：

```text
v1.5.0
v1.4.2026.718
```

- 每段必须在 `0..65535`，满足 Windows 文件版本限制。
- 三段 ProductVersion（如 `1.5.0`）对应四段 FileVersion（`1.5.0.0`）。
- 四段版本的 ProductVersion 与 FileVersion 相同。
- 构建脚本必须验证 AHK 源中存在 FileVersion、ProductVersion 指令和 `DISPLAY_VERSION:="development"`，缺一即失败。

版本注入只作用于系统临时目录中的源文件：读取 `src/d3keyhelper.ahk`，替换三个标记，以 UTF-8 BOM 写入临时 `.ahk`，编译后在 `finally` 中删除。不要原地修改源文件，也不要让发布构建留下脏工作树。

编译后必须读取 EXE 的 `VersionInfo`，验证 FileVersion/ProductVersion 的格式和请求值，再创建 ZIP。

## CI 与 Release

`.github/workflows/build.yml` 在 `windows-latest` 上：

- 下载固定版本 AutoHotkey v1，并校验 SHA-256。
- 对普通 branch/PR 构建开发包；对 tag 将 `github.ref_name` 传给 `-Version`。
- 要求 `dist/` 中恰好存在一个匹配的版本 ZIP。
- 验证 tag、EXE 版本和 ZIP 文件名一致，再上传 artifact。

tag 发布仅接受 `vMAJOR.MINOR.PATCH` 或 `vMAJOR.MINOR.BUILD.REVISION`。release job 下载同一个 artifact；已有 GitHub Release 时覆盖上传 ZIP，否则创建 Release。Release 只发布 ZIP，不再单独上传 EXE。

## 变更联动

| 变更 | 必查位置 |
|---|---|
| AHK 编译目标/架构 | `src/d3keyhelper.ahk` 的 Ahk2Exe 指令、`scripts/build.ps1`、workflow 下载内容、README |
| 版本格式 | `scripts/build.ps1` 正则与映射、workflow tag 正则与预期文件名、README 发布示例 |
| 产物名称/内容 | `build.ps1`、workflow artifact 解析/上传、release job、README |
| AutoHotkey 版本 | `AHK_MIN_VERSION`、workflow 固定版本与哈希、本地构建要求 |
| 显示版本 | `DISPLAY_VERSION`、临时替换规则、窗口标题构造、EXE 元数据验证 |

## 禁止事项

- 不要仅修改 GitHub Actions 而让本地 `build.cmd` 产生不同结构的包。
- 不要放宽为任意 `v*` tag 后跳过严格版本验证。
- 不要从未校验哈希的网络下载直接执行编译器。
- 不要把本地 `settings.ini`、`profiles/`、调试文件或裸 EXE 加入 Release。
- 不要删除编译后的元数据验证；Ahk2Exe 退出码为零不代表版本注入正确。

