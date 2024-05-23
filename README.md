# Onnimonni Homebrew taps

## How do I install these formulae?

### Kitsas
Install Kitsas, Finnish bookkeeping software for small organisations through my custom homebrew tap by running:
```bash
brew install onnimonni/tap/kitsas
```

### Forscan
Install Forscan, Diagnostics software for Ford, Mazda, Lincoln and Mercury vehicles.

You need to install them in this order to unquarantine wine which is also needed in Forscan installer.
```bash
 brew install --no-quarantine --cask wine-stable ftdi-vcp-driver forscan
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
