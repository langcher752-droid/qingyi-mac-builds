#!/usr/bin/env bash
# 清一新教育 · Mac 版安装包：下载 → 推代码 → 发 Release
#
# 一行命令（需要有 Arthurchen 仓库权限的人在自己的电脑上跑）：
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main/upload-to-zh-editor.sh)"
#
# 它会做四件事：
#   ① 检查 gh（GitHub CLI）有没有装、有没有登录；
#   ② 从公开暂存区下载两个 Mac 安装包 + 代码包；
#   ③ 把 macOS 打包改动推到 Arthurchen-01/zh-editor（fast-forward）；
#   ④ 在 Arthurchen-01/zh-editor 上发一个 Release，把两个 dmg 挂上去。
set -euo pipefail

SRC_REPO="${SRC_REPO:-langcher752-droid/qingyi-mac-builds}"
SRC_TAG="${SRC_TAG:-mac-v1.0.0}"
# 注意：GitHub 的 Release 资源名只保留 ASCII，中文会被剥掉，
# 所以这里用英文名（App 本身仍叫「清一新教育一键修改.app」）。
DMG_ARM="Qingyi-Mac-AppleSilicon.dmg"   # M1/M2/M3/M4
DMG_INTEL="Qingyi-Mac-Intel.dmg"        # Intel
DST_REPO="${DST_REPO:-Arthurchen-01/zh-editor}"
DST_TAG="${DST_TAG:-v1.0.0-mac}"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "① 检查工具链"
if ! command -v gh >/dev/null 2>&1; then
  echo "缺少 GitHub CLI(gh)。macOS 上先跑：brew install gh"
  echo "（Windows 上：winget install --id GitHub.cli）"
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "还没登录 GitHub，先跑：gh auth login"
  exit 1
fi
ME="$(gh api user -q .login)"
echo "   gh 已登录：$ME"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

say "② 下载两个 Mac 安装包 + 代码包"
# 直链下载（不依赖 gh 的 release 接口）
DL_BASE="https://github.com/$SRC_REPO/releases/download/$SRC_TAG"
for f in "$DMG_ARM" "$DMG_INTEL" mac-packaging.bundle; do
  curl -fsSL --retry 3 -m 900 -o "$TMP/$f" "$DL_BASE/$f"
  ls -lh "$TMP/$f"
done

say "③ 把 macOS 打包改动推到 $DST_REPO"
git clone --quiet "https://github.com/$DST_REPO.git" zh-editor
cd zh-editor
if git fetch --quiet "$TMP/mac-packaging.bundle" refs/heads/main:refs/remotes/bundle/main; then
  if git -c credential.helper='!gh auth git-credential' push origin refs/remotes/bundle/main:main; then
    echo "   已推送：$(git log --oneline -1 refs/remotes/bundle/main)"
  else
    echo "   [!] 推送失败（没权限或远端 main 变过），跳过代码推送，继续发 Release"
  fi
else
  echo "   [!] 代码包应用失败，跳过代码推送，继续发 Release"
fi
cd "$TMP"

# 发 Release / 推 workflow 文件都需要 workflow 权限
if ! gh auth status 2>&1 | grep -q workflow; then
  say "GitHub token 缺 workflow 权限，现在补上（会开浏览器让你确认）"
  gh auth refresh -h github.com -s workflow || \
    echo "   [!] 没加上 workflow 权限，Release 那步可能会失败"
fi

say "④ 发 Release ${DST_TAG}（附两个 dmg）"
NOTES="macOS 预编译版一键程序：不用装 Python、不用终端。

- Apple Silicon（M 系列）：$DMG_ARM
- Intel：$DMG_INTEL

用法：打开 dmg → 把「清一新教育一键修改.app」拖进「应用程序」→
首次在 App 上点右键 →「打开」（内部工具未公证，直接双击会被拦下）。
前提：Chrome 已登录 zhihu.com；首次会弹一次钥匙串授权，点「始终允许」。"
if gh release view "$DST_TAG" --repo "$DST_REPO" >/dev/null 2>&1; then
  gh release upload "$DST_TAG" --repo "$DST_REPO" --clobber \
    "$TMP/$DMG_ARM" "$TMP/$DMG_INTEL"
else
  gh release create "$DST_TAG" --repo "$DST_REPO" \
    --title "macOS 版一键程序（Intel + Apple Silicon）" \
    --notes "$NOTES" \
    "$TMP/$DMG_ARM" "$TMP/$DMG_INTEL"
fi

say "完成 ✅"
echo "代码：https://github.com/$DST_REPO"
echo "安装包：https://github.com/$DST_REPO/releases/tag/$DST_TAG"
