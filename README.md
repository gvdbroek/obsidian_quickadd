# Obsidian Quick Add

A small KDE dialog tool that reads an input, sanitizes it and passes it to the obsidian CLI.  
Could have probably been simple bash script + alias. But felt like trying zig for fun.

## Might do later
- look into a UI dependency to get rid of `kdialog`
- Improve feedback
  - Show sanitized output before sending cli command
  - Validate length of input string
- Configurability
  - Dunno, something something allowing a choice of quickcommands as an input or something.

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
