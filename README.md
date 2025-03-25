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

#### How to update Forscan in this repository to latest version?
If you notice that there's a new version you can create a pull-request to update the version like this:
```sh
export NEW_FORSCAN_VERSION=$(brew livecheck forscan --json | jq -r '.[0].version.latest')
# This needs to use --no-audit flag because the downloaded file doesn't contain any MacOS binaries.
brew bump-cask-pr --no-audit --version $NEW_FORSCAN_VERSION onnimonni/tap/forscan
```

I will then merge the new version as soon as I can :heart: :ok_hand:.

After the version change is merged you can update your Forscan by running this:
```sh
brew update && brew upgrade onnimonni/tap/forscan
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
