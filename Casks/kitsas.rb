cask "kitsas" do
  version "5.9"
  sha256 "10551f3640e0adcdc8177a6980540be8f20913c70a8e56f56dd55abf748df7aa"

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
