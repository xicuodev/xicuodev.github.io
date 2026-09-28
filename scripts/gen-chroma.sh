#!/usr/bin/env bash
# 生成 assets/css/chroma.css 的脚本
# 候选配色：https://gohugo.io/quick-reference/syntax-highlighting-styles/
# 用法：./scripts/gen-chroma.sh [浅色配色] [深色配色]
set -euo pipefail

LIGHT="${1:-solarized-light}"
DARK="${2:-solarized-dark}"

cd "$(dirname "$0")/.."

styles() {
  hugo gen chromastyles --style="$1" --omitClassComments | grep -vE '^(/\*|\.bg )'
}

{
  echo "/* 由 scripts/gen-chroma.sh 生成，请勿手改（${LIGHT} / ${DARK}） */"
  styles "$LIGHT"
  echo "@media (prefers-color-scheme: dark) {"
  styles "$DARK"
  echo "}"
} > assets/css/chroma.css

echo "已生成 assets/css/chroma.css（${LIGHT} / ${DARK}）"
