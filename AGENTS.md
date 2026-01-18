# tldr

- **Build**: `xcodebuild -scheme tldr -destination 'generic/platform=iOS' build -showBuildSettings | grep -m1 'BUILT_PRODUCTS_DIR'` to find output path, then build with `xcodebuild -scheme tldr -destination 'generic/platform=iOS' build`
- **Run on device**: Use `xcrun devicectl list devices` to get device UUID, then `xcrun devicectl device install app --device <UUID> <BUILT_PRODUCTS_DIR>/tldr.app && xcrun devicectl device process launch --device <UUID> DestinerLabs.tldr`
