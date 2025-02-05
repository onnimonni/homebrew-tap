cask "open-eid" do
  version "24.9.0.1949"
  sha256 "e9c83c37836d9d0b78d2867f978caae1bb781ffbf62e40559484f5fad400268e"

  url "https://installer.id.ee/media/osx/Open-EID_#{version}.dmg"
  name "open-eid"
  desc "Estonian ID-card drivers, authentication components & signing components"
  homepage "https://www.id.ee/en/article/install-id-software/"

  livecheck do
    url "https://www.id.ee/en/article/install-id-software/"
    regex(%r{href=.*?/Open-EID_(\d+(?:\.\d+)+)\.dmg}i)
  end

  depends_on macos: ">= :big_sur"
  auto_updates false

  app "EstEIDTokenApp.app"

  # Documentation: https://docs.brew.sh/Cask-Cookbook#stanza-zap
  zap trash: ""
end
