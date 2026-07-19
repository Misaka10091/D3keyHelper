# 构建与发布规范

本目录描述 `scripts/` 和 `.github/workflows/build.yml` 的合同。

## 规范索引

| 文档 | 适用场景 |
|---|---|
| [构建与发布](./build-and-release.md) | 修改 Ahk2Exe 调用、版本注入、ZIP、GitHub Actions 或 Release |

## 开发前检查

- [ ] 确认修改面向 AutoHotkey v1.1 的 64 位 Unicode 编译器。
- [ ] 涉及版本时，同时检查 AHK 编译指令、`DISPLAY_VERSION`、PowerShell 校验、CI tag 校验和 README。
- [ ] 保持本地构建和 CI 都调用 `scripts/build.ps1`，不要复制第二套打包实现。

## 质量检查

- [ ] `scripts/build.cmd` 仍只是稳定的 cmd 入口，参数原样转交 PowerShell。
- [ ] 无版本构建与三段/四段版本构建均保持原有语义。
- [ ] 构建不修改受版本控制的源文件。
- [ ] EXE 元数据、ZIP 名称、Actions artifact 和 GitHub Release 使用同一版本。
- [ ] 发布包不包含 `settings.ini` 或 `profiles/`。

