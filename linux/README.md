# Linux build dependencies

Beyond Flutter's standard Linux desktop toolchain (`clang`, `cmake`,
`ninja-build`, `pkg-config`, `libgtk-3-dev`), this app pulls in two extra
native dependencies via a plugin:

- **`libsecret-1-dev`** (>= 0.18.4) — required by `flutter_secure_storage`'s
  Linux implementation (`flutter_secure_storage_linux`), which uses
  libsecret as the OS keyring backend for storing the user's Spotify Client
  ID / tokens (see `lib/data/spotify/`). 
- **`libwebkit2gtk`**

  Install on Debian/Ubuntu/Mint:

  ```
  sudo apt install libsecret-1-dev libwebkit2gtk
  ```

