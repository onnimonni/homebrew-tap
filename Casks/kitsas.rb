cask "kitsas" do
  version "5.5.2"
  sha256 "100d47acb35a32482afcbc7bf9d435ea813296c853b6f7b5440869c4329b7827"

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
