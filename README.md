# 清一新教育 · Mac 版安装包暂存区

这个仓库只是**临时中转**：里面是已经打好的 macOS 安装包，
给有 `Arthurchen-01/zh-editor` 写权限的人下载后再上传过去。用完可以删。

## 一行命令

**Windows（在 PowerShell 里跑）**

```powershell
irm https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main/upload-to-zh-editor.ps1 | iex
```

**macOS / Linux（在终端里跑）**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main/upload-to-zh-editor.sh)"
```

两条命令做的是同一件事，都会自己完成：

1. 检查 `gh`（GitHub CLI）和 `git`，缺了就用 `winget` 自动装（Windows）；
2. 检查有没有登录 GitHub，没登录就直接拉起 `gh auth login`；
3. 从本仓库下载两个 dmg + 代码包；
4. 把 macOS 打包改动 fast-forward 推到 `Arthurchen-01/zh-editor`；
5. 在 zh-editor 上发 Release `v1.0.0-mac`，把两个 dmg 挂上去。

> 只需要：登录的账号对 `Arthurchen-01/zh-editor` 有写权限。
> 第 4 步失败（没权限 / 远端 main 变过）不会中断，第 5 步照样执行。

## 安装包

| 资源名 | 适用机型 |
| --- | --- |
| `Qingyi-Mac-AppleSilicon.dmg` | M1/M2/M3/M4 |
| `Qingyi-Mac-Intel.dmg` | Intel Mac |

> 资源名用英文是因为 GitHub 会把 Release 资源名里的中文剥掉；
> 下载后 App 本体仍叫「清一新教育一键修改.app」。

用法：打开 dmg → App 拖进「应用程序」→ 首次在 App 上点右键 →「打开」。
