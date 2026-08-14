#!/bin/bash
# publish.sh — یک پروژه را با یک دستور روی گیت‌هاب منتشر می‌کند/به‌روز می‌کند و Pages را فعال نگه می‌دارد.
#
# استفاده (پروژه‌ی جدید یا به‌روزرسانی پروژه‌ی قبلی — فرقی ندارد):
#   bash publish.sh نام-پروژه
#
# نیازمندی‌ها: git، gh (GitHub CLI) نصب و یک‌بار با gh auth login وارد شده باشد.

set -e

if [ -z "$1" ]; then
  echo "استفاده: bash publish.sh <نام-پروژه>"
  exit 1
fi

REPO_NAME="$1"
GITHUB_USER=$(gh api user --jq .login)

echo "→ در حال آماده‌سازی گیت محلی…"
if [ ! -d ".git" ]; then
  git init -q
fi
git add .
git commit -q -m "update: $(date +%Y-%m-%d_%H-%M)" || echo "  (تغییری برای commit جدید نبود، ادامه می‌دهیم)"
git branch -M main 2>/dev/null || true

if git remote get-url origin >/dev/null 2>&1; then
  echo "→ ریموت از قبل وصل است، فقط push می‌کنم…"
  git push -u origin main
elif gh repo view "$GITHUB_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "→ این ریپو از قبل روی گیت‌هاب هست، وصلش می‌کنم و به‌روزش می‌کنم…"
  git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
  git push -u origin main
else
  echo "→ در حال ساخت ریپوی جدید و push کردن…"
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
fi

echo "→ در حال فعال‌سازی GitHub Pages…"
gh api -X POST "repos/$GITHUB_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || \
gh api -X PUT "repos/$GITHUB_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1

echo ""
echo "✅ آماده شد!"
echo "   ریپو: https://github.com/$GITHUB_USER/$REPO_NAME"
if [ "$REPO_NAME" == "$GITHUB_USER.github.io" ]; then
  echo "   سایت: https://$GITHUB_USER.github.io/"
else
  echo "   سایت: https://$GITHUB_USER.github.io/$REPO_NAME/"
fi
echo "   (اگر تازه ساخته شده، ۱-۲ دقیقه طول می‌کشد تا واقعاً بالا بیاید)"
