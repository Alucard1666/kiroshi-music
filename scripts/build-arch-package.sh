#!/bin/sh
# Build script for kiroshi-music Arch Linux package

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
packaging_dir="$repo_root/packaging/arch"
output_dir="$repo_root/artifacts/arch"

version=$(node -p "require('$repo_root/package.json').version")
arch_version=$(printf '%s' "$version" | tr '-' '.')
pkgname="kiroshi-music"
source_name="$pkgname-$arch_version"
source_archive="$packaging_dir/$source_name.tar.zst"
temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/kiroshi-music-arch.XXXXXX")

cleanup() {
  rm -rf -- "$temp_dir"
}
trap cleanup EXIT HUP INT TERM

echo "Building native addons and frontend..."
npm --prefix "$repo_root" run build:native
npm --prefix "$repo_root" run build:frontend

payload="$temp_dir/$source_name"
mkdir -p "$payload"

echo "Staging application payload..."
# Core application code
cp -a "$repo_root/dist" "$payload/"
cp -a "$repo_root/electron" "$payload/"
cp -a "$repo_root/shared" "$payload/"
cp -a "$repo_root/models" "$payload/"
cp -a "$repo_root/packages" "$payload/"
cp -a "$repo_root/package.json" "$payload/"
cp -a "$repo_root/LICENSE" "$payload/"
mkdir -p "$payload/build" "$payload/resources"
cp -a "$repo_root/build/icon.png" "$payload/build/"
cp -a "$repo_root/build/icon.ico" "$payload/build/"
cp -a "$repo_root/build/icon.png" "$payload/resources/icon.png"
cp -a "$repo_root/build/icon.ico" "$payload/resources/icon.ico"

# Native addons & loaders
mkdir -p "$payload/native-media/build" "$payload/native-audio-rust/build"
cp -a "$repo_root/native-media/index.cjs" "$payload/native-media/"
cp -a "$repo_root/native-media/build/orchard-system-media-linux-x64.node" "$payload/native-media/build/"
cp -a "$repo_root/native-audio-rust/index.cjs" "$payload/native-audio-rust/"
cp -a "$repo_root/native-audio-rust/build/orchard-audio-linux-x64.node" "$payload/native-audio-rust/build/"

# Icons
icons_dir="$payload/resources/icons"
mkdir -p "$icons_dir"
svg_source="/home/kiroshi/code/KiroshiOS/logo.svg"
if [ -f "$svg_source" ]; then
  cp "$svg_source" "$icons_dir/scalable.svg"
  for sz in 16 32 48 64 128 256 512 1024; do
    rsvg-convert -w "$sz" -h "$sz" "$svg_source" -o "$icons_dir/${sz}x${sz}.png"
  done
elif [ -f "$repo_root/build/icon.png" ]; then
  for sz in 16 32 48 64 128 256 512 1024; do
    magick "$repo_root/build/icon.png" -resize "${sz}x${sz}" "$icons_dir/${sz}x${sz}.png"
  done
fi

# Node modules
echo "Staging production node_modules..."
mkdir -p "$payload/node_modules"
cp -a "$repo_root/node_modules/." "$payload/node_modules/"

# Clean up dev / bulky runtime files from payload
rm -rf "$payload/node_modules/.bin"
rm -rf "$payload/node_modules/electron/dist"
rm -f "$payload"/node_modules/onnxruntime-node/bin/napi-v6/linux/x64/libonnxruntime_providers_*.so
rm -rf "$payload/node_modules/onnxruntime-node/bin/napi-v6/linux/arm64"
rm -rf "$payload/node_modules/onnxruntime-node/bin/napi-v6/darwin"
rm -rf "$payload/node_modules/onnxruntime-node/bin/napi-v6/win32"
find "$payload/node_modules" -type f -name "*.map" -delete
find "$payload/node_modules" -type d \( -name "test" -o -name "tests" -o -name "docs" -o -name "example" -o -name "examples" \) -exec rm -rf {} + 2>/dev/null || true

echo "Creating source archive $source_archive..."
rm -f -- "$source_archive"
ZSTD_CLEVEL=6 tar \
  --sort=name \
  --mtime=@0 \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --zstd \
  -cf "$source_archive" \
  -C "$temp_dir" \
  "$source_name"

echo "Updating PKGBUILD..."
source_sha256=$(sha256sum "$source_archive" | awk '{print $1}')
desktop_sha256=$(sha256sum "$packaging_dir/kiroshi-music.desktop" | awk '{print $1}')
launcher_sha256=$(sha256sum "$packaging_dir/kiroshi-music.sh" | awk '{print $1}')

sed -i \
  -e "s/^pkgver=.*/pkgver=$arch_version/" \
  -e "s/^sha256sums=.*/sha256sums=('$source_sha256' '$desktop_sha256' '$launcher_sha256')/" \
  "$packaging_dir/PKGBUILD"

echo "Running makepkg..."
cd "$packaging_dir"
makepkg --force --cleanbuild --clean --nodeps

mkdir -p "$output_dir"
find "$output_dir" -maxdepth 1 -type f -name 'kiroshi-music-*.pkg.tar.zst' -delete
package_file=$(makepkg --packagelist | sed -n '1p')
if [ -z "$package_file" ] || [ ! -f "$package_file" ]; then
  package_file=$(find "$packaging_dir" -maxdepth 1 -type f -name 'kiroshi-music-*.pkg.tar.zst' -print -quit)
fi

test -n "$package_file"
test -f "$package_file"
cp "$package_file" "$output_dir/"

result_pkg="$output_dir/$(basename -- "$package_file")"
printf '\nPackage built successfully: %s\n' "$result_pkg"
