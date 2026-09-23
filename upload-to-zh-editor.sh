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
gh release download "$SRC_TAG" --repo "$SRC_REPO" --dir "$TMP" --clobber
ls -lh "$TMP"/清一新教育-Mac-*.dmg

say "③ 把 macOS 打包改动推到 $DST_REPO"
git clone --quiet "https://github.com/$DST_REPO.git" zh-editor
cd zh-editor
git fetch --quiet "$TMP/mac-packaging.bundle" refs/heads/main:refs/remotes/bundle/main
git -c credential.helper='!gh auth git-credential' push origin refs/remotes/bundle/main:main
echo "   已推送：$(git log --oneline -1 refs/remotes/bundle/main)"
cd "$TMP"

say "④ 发 Release $DST_TAG（附两个 dmg）"
NOTES="macOS 预编译版一键程序：不用装 Python、不用终端。

- Apple Silicon（M 系列）：清一新教育-Mac-AppleSilicon.dmg
- Intel：清一新教育-Mac-Intel.dmg

用法：打开 dmg → 把 App 拖进「应用程序」→ 首次在它上面点右键 →「打开」。
前提：Chrome 已登录 zhihu.com。"
if gh release view "$DST_TAG" --repo "$DST_REPO" >/dev/null 2>&1; then
  gh release upload "$DST_TAG" --repo "$DST_REPO" --clobber \
    "$TMP/清一新教育-Mac-AppleSilicon.dmg" "$TMP/清一新教育-Mac-Intel.dmg"
else
  gh release create "$DST_TAG" --repo "$DST_REPO" \
    --title "macOS 版一键程序（Intel + Apple Silicon）" \
    --notes "$NOTES" \
    "$TMP/清一新教育-Mac-AppleSilicon.dmg" "$TMP/清一新教育-Mac-Intel.dmg"
fi

say "完成 ✅"
echo "代码：https://github.com/$DST_REPO"
echo "安装包：https://github.com/$DST_REPO/releases/tag/$DST_TAG"
