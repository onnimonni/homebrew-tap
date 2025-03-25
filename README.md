# Onnimonni Homebrew taps

## How do I install these Casks?

### Forscan
This is most likely the easiest way to run Forscan on MacOS.

1. First install homebrew from: http://brew.sh
2. Then copy following command into Terminal:

```bash
brew install --no-quarantine --cask wine-stable onnimonni/tap/forscan
```

3. And after this plug your cable to the car and launch `FORScan.app` in your machine.

> [!NOTE]
> Homebrew doesn't allow `--no-quarantine` to be applied to child dependencies
> Even though `onnimonni/tap/forscan` requires Wine Stable.
> Because of this it's easiest to install this by running them both here

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

### Kitsas
Install Kitsas, Finnish bookkeeping software for small organisations through my custom homebrew tap by running:

```bash
brew install --cask onnimonni/tap/kitsas
```

#### Updating Kitsas
Similiarly as with Homebrew:
```sh
brew bump-cask-pr --no-audit --version $(brew livecheck kitsas --json | jq -r '.[0].version.latest') onnimonni/tap/kitsas
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
