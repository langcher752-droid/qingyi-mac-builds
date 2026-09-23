# 清一新教育 · Mac 版安装包暂存区

这个仓库只是**临时中转**：里面是已经打好的 macOS 安装包，
给有 `Arthurchen-01/zh-editor` 写权限的人下载后再上传过去。用完可以删。

## 一行命令（在你自己电脑上跑）

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main/upload-to-zh-editor.sh)"
```

前提：装了 GitHub CLI（`brew install gh`）并且 `gh auth login` 登录的账号
对 `Arthurchen-01/zh-editor` 有写权限。

它会：下载两个 dmg + 代码包 → 把 macOS 打包改动 fast-forward 推到 zh-editor →
在 zh-editor 上发一个 Release 并把两个 dmg 挂上去。

## 安装包

| 资源名 | 适用机型 |
| --- | --- |
| `Qingyi-Mac-AppleSilicon.dmg` | M1/M2/M3/M4 |
| `Qingyi-Mac-Intel.dmg` | Intel Mac |

> 资源名用英文是因为 GitHub 会把 Release 资源名里的中文剥掉；
> 下载后 App 本体仍叫「清一新教育一键修改.app」。

用法：打开 dmg → App 拖进「应用程序」→ 首次在 App 上点右键 →「打开」。
