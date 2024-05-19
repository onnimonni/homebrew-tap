cask "forscan" do
    version "2.3.59"
    sha256 "5e98b1bb0df610ea755b186ebd48f0f04047507301474104b72b68ef3fdf6d97"

    url "https://forscan.org/download/FORScanSetup#{version}.release.exe"
    name "Forscan"
    desc "Software scanner for Ford, Mazda, Lincoln and Mercury vehicles"
    homepage "https://forscan.org/home.html"

    livecheck do
        url "https://forscan.org/changes_history.html"
        regex(/href=download\/FORScanSetup(\d+(?:\.\d+)+).release.exe/)
    end

    depends_on macos: ">= :big_sur"

    app "Forscan.exe"
end
  