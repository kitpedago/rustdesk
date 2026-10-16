#!/bin/bash
# GD Remote fork: regenerate every icon from one geometry (ImageMagick 7).
# Run from the repository root: bash res/gen_gd_remote_icons.sh
set -e
BG='#1F4E79'
P1='M 478 362 A 212 212 0 1 0 478 662 L 478 532 L 376 532'   # G
P2='M 624 300 V 724 M 624 300 H 684 A 212 212 0 0 1 684 724 H 624'  # D
glyph() { # $1 color, $2 scale
  echo "-fill none -stroke $1 -strokewidth 112 -draw \"translate 512,512 scale $2,$2 translate -512,-512 path '$P1' path '$P2'\""
}
T=$(mktemp -d)
eval magick -size 1024x1024 xc:none -fill "'$BG'" -draw "'roundrectangle 0,0 1023,1023 220,220'" $(glyph white 0.92) $T/full.png
eval magick -size 1024x1024 xc:none -fill "'$BG'" -draw "'circle 512,512 512,0'" $(glyph white 0.92) $T/round.png
eval magick -size 1024x1024 xc:none $(glyph white 0.92) $T/glyph-white.png
eval magick -size 1024x1024 xc:none $(glyph black 0.92) $T/glyph-black.png
eval magick -size 1024x1024 xc:none $(glyph white 0.56) $T/foreground.png

cp $T/full.png res/icon.png
cp $T/full.png res/mac-icon.png
for s in 32 64 128; do magick $T/full.png -resize ${s}x${s} res/${s}x${s}.png; done
magick $T/full.png -resize 256x256 res/128x128@2x.png
magick $T/full.png -define icon:auto-resize=256,128,64,48,32,16 res/icon.ico
magick $T/full.png -resize 32x32 res/tray-icon.ico
magick $T/full.png -define icon:auto-resize=256,128,64,48,32,16 flutter/windows/runner/resources/app_icon.ico
magick $T/glyph-black.png -resize 60x60 res/mac-tray-dark-x2.png
magick $T/glyph-black.png -resize 48x48 res/mac-tray-light-x2.png

A=flutter/android/app/src/main/res
i=0
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  launcher=(48 72 96 144 192); fg=(108 162 216 324 432); stat=(24 36 48 72 96)
  magick $T/full.png -resize ${launcher[$i]}x${launcher[$i]} $A/mipmap-$d/ic_launcher.png
  magick $T/round.png -resize ${launcher[$i]}x${launcher[$i]} $A/mipmap-$d/ic_launcher_round.png
  magick $T/foreground.png -resize ${fg[$i]}x${fg[$i]} $A/mipmap-$d/ic_launcher_foreground.png
  magick $T/glyph-white.png -resize ${stat[$i]}x${stat[$i]} $A/mipmap-$d/ic_stat_logo.png
  i=$((i+1))
done

cat > flutter/assets/icon.svg <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
<rect width="1024" height="1024" rx="220" fill="$BG"/>
<g transform="translate(512 512) scale(0.92) translate(-512 -512)" fill="none" stroke="#FFFFFF" stroke-width="112">
<path d="$P1"/>
<path d="$P2"/>
</g>
</svg>
SVG
cp $T/full.png $T/round.png $T/foreground.png "${PREVIEW_DIR:-$T}/" 2>/dev/null || true
rm -rf $T
echo "icons generated"
