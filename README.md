# Chromium with Widevine for aarch64 (16K page size)

Automated GitHub Actions build of Chromium with Widevine DRM support, targeting **aarch64 Linux with 16K page size** (Apple Silicon / Asahi Linux).

## What this does

Debian's stock Chromium is built with `proprietary_codecs=false` and `enable_widevine=false`, which disables Widevine/EME support entirely. This repository builds Chromium from source with both flags enabled, then applies the `widevine_fixup.py` patch to the CDM binary for 16K page alignment.

## Features

- **Widevine DRM** — Netflix, Disney+, Apple Music, Spotify, etc.
- **Proprietary codecs** — H.264, H.265, AAC
- **EME** — Encrypted Media Extensions API
- **16K page size** — Properly aligned for Apple Silicon

## Installation

Download the latest release and run:

```bash
tar xzf chromium-widevine-linux-arm64-*.tar.gz
cd chromium-widevine-linux-arm64-*
sudo ./install.sh
```

Then launch:
```bash
chromium-widevine
```

## Building locally

If you prefer to build locally (requires ~100GB disk, ~16GB RAM, 4+ hours):

```bash
# Install depot_tools
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$(pwd)/depot_tools"

# Fetch Chromium
mkdir chromium && cd chromium
fetch --no-history chromium
cd src

# Configure
gn gen out/Release --args='
  target_cpu="arm64"
  is_debug=false
  is_official_build=true
  proprietary_codecs=true
  enable_widevine=true
  ffmpeg_branding="Chrome"
'

# Build
autoninja -C out/Release chrome

# Fixup Widevine CDM
python3 widevine_fixup.py out/Release/libwidevinecdm.so out/Release/libwidevinecdm_fixed.so
```

## How it works

1. GitHub Actions fetches Chromium source (shallow clone)
2. Cross-compiles for aarch64 from x86_64 runner
3. Applies `widevine_fixup.py` to the Widevine CDM binary
4. Packages everything into a tarball
5. Publishes as a GitHub Release

## Schedule

Builds run automatically every Monday at 03:00 UTC. You can also trigger a manual build from the Actions tab.

## Credits

- [widevine-installer](https://github.com/nicman23/widevine-installer) — CDM fixup script
- [@DavidBuchanan314](https://github.com/DavidBuchanan314) — Original fixup script
- [@marcan](https://github.com/marcan) — Asahi Linux Widevine support

## License

The build scripts are MIT licensed. Chromium and Widevine are subject to their own licenses.
