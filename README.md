# Obsidian Quick Add

A small KDE dialog tool that reads an input, sanitizes it and passes it to the obsidian CLI
Could have probably been a convoluted alias in .bashrc, but felt was curious to try zig


## Dependencies
- Obsidian + Obsidian CLI (registered)
- kdialog ~25.12.3
- Built binary in $PATH

## Build

```bash
git clone https://github.com/gvdbroek/obsidian_quickadd
cd obsidian_quickadd
# (Ensure zig 0.15.2)
zig build -Doptimize=ReleaseFast
```


Place built binary `zig-out/bin/obsidian_quickadd` somewhere where you wish to call it
