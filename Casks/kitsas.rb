cask "kitsas" do
  version "5.11"
  sha256 "c2d339983bb044cc74dd21950f30315cb38754a06a1fba32c76e9e03d2acb91b"

  url "https://github.com/petriaarnio/kitupiikki/releases/download/mac-v#{version}/Kitsas-#{version}.dmg"
  name "Kitsas"
  desc "Finnish bookkeeping software for small organisations"
  homepage "https://github.com/artoh/kitupiikki"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :big_sur"

  app "Kitsas.app"

  uninstall quit: "fi.atfos.kitsas"
end
