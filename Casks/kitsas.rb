cask "kitsas" do
  version "5.10"
  sha256 "ebeb087ec42133ec414c20c4e5c8e9852f73427dfdfe8d793dc07156c5bdf749"

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
