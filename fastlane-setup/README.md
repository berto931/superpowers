# fastlane install

Install of [fastlane](https://github.com/fastlane/fastlane) (iOS/Android
release automation) as a Ruby gem.

Note: the folder is named `fastlane-setup/` (not `fastlane/`) because a
directory literally named `fastlane` at a repo root is fastlane's own
project-configuration convention and would be misleading.

## Usage

```bash
./setup.sh
fastlane --version
```

## What it does

1. `sudo gem install fastlane --no-document`.
2. If Ruby is rbenv-managed (as in this sandbox, where root's `gem` targets
   `/opt/rbenv/versions/3.3.6` while the shell's default `ruby` is a separate
   `/opt/ruby-3.3.6` install), the rbenv shims alone don't resolve — the shim
   errors with "command not found" because the active rbenv version is
   `system`. The script instead symlinks the versioned binstub
   (`/opt/rbenv/versions/<ver>/bin/fastlane`) to `/usr/local/bin/fastlane`;
   the binstub's shebang pins its own Ruby, so it works regardless of PATH.
3. Sets `LC_ALL`/`LANG` to `C.UTF-8` (persisted in `~/.bashrc`) — fastlane
   warns and can misbehave without a UTF-8 locale.

## Verified result (2026-07-30, sandboxed Linux container)

- Ruby 3.3.6, RubyGems 3.5.22.
- `fastlane 2.237.0` installed (85 gems) and runs cleanly from
  `/usr/local/bin/fastlane` with no locale warnings.

## Notes

- Actual iOS builds require macOS/Xcode; on Linux, fastlane is still useful
  for Android lanes (`supply`, `gradle`), screenshots upload, and CI tooling.
- Per-project use: create a `fastlane/Fastfile` in the project and run
  `fastlane <lane>`.
