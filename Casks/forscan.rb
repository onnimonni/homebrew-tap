cask "forscan" do
    version "2.3.59"
    sha256 "15e717877acff5dafd2f6a36ce467f2a2e06e1cd0a61480994e9c6b2ed45f7be"

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
  