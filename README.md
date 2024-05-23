# Onnimonni Homebrew taps

## How do I install these Casks?

### Kitsas
Install Kitsas, Finnish bookkeeping software for small organisations through my custom homebrew tap by running:
```bash
brew install --cask onnimonni/tap/kitsas
```

### Forscan
Install Forscan, Diagnostics software for Ford, Mazda, Lincoln and Mercury vehicles.

Homebrew doesn't allow `--no-quarantine` to child dependencies so you need to install and unquarantine Wine first since Forscan installer needs this
```bash
brew install --no-quarantine --cask wine-stable onnimonni/tap/forscan
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
