cask "gol" do
  version "2.2.2"
  sha256 "7eba831cdc18190e129c10754053da9ccbe50242c4eb50c4f47c1bc20229b8ba"

  url "https://github.com/clarisma/geodesk-gol/releases/download/v#{version}/gol-#{version}-macos.zip",
      verified: "github.com/clarisma/geodesk-gol/"
  name "GOL"
  desc "Command-line tool for querying and exporting OpenStreetMap data"
  homepage "https://docs.geodesk.com/gol"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "gol"
end
