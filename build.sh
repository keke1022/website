#!/bin/bash

set -e

# 🌟 Clean dist
rm -rf dist
mkdir -p dist

build_jekyll() {
  local name="$1"
  local baseurl="$2"
  echo "🔨 Building $name (Jekyll)"
  cd "$name"
  bundle install
  set +e
  bundle exec jekyll build --baseurl "$baseurl" --destination "../dist${baseurl}"
  BUILD_EXIT_CODE=$?
  set -e
  if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "❌ $name build failed."
    exit 1
  fi
  cd ..
}

build_react() {
  local name="$1"
  local baseurl="$2"
  echo "⚙️ Building $name (React)"
  cd "$name"
  npm install
  export PUBLIC_URL="$baseurl"
  npm run build
  cp -r build "../dist${baseurl}"
  cd ..
}

copy_static() {
  local name="$1"
  local baseurl="$2"
  echo "📦 Copying $name (static)"
  mkdir -p "dist${baseurl}"
  cp -r "$name"/* "dist${baseurl}/"
}

# Detect and build all subprojects
for dir in */ ; do
  dir=${dir%/}  # remove trailing slash
  [[ "$dir" == "dist" ]] && continue
  [[ "$dir" == .* ]] && continue
  [[ "$dir" == *.bak ]] && continue
  [[ "$dir" == "Blog" ]] && continue

  if [ -f "$dir/Gemfile" ] && grep -q jekyll "$dir/Gemfile"; then
    build_jekyll "$dir" "/$dir"
  elif [ -f "$dir/package.json" ]; then
    build_react "$dir" "/$dir"
  else
    copy_static "$dir" "/$dir"
  fi

done

# Optional root index
echo "<h1>Welcome to keke-hub.com</h1>" > dist/index.html

# Done
echo "🚀 All sites built in ./dist:"
find dist