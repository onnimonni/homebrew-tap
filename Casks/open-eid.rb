cask "open-eid" do
  version "24.9.0.1949"
  sha256 "e9c83c37836d9d0b78d2867f978caae1bb781ffbf62e40559484f5fad400268e"

  url "https://installer.id.ee/media/osx/Open-EID_#{version}.dmg"
  name "open-eid"
  desc "Estonian ID-card drivers, authentication components & signing components"
  homepage "https://www.id.ee/en/article/install-id-software/"

  livecheck do
    url "https://www.id.ee/en/article/install-id-software/"
    regex(%r{href=.*/Open-EID_(\d+(?:\.\d+)+)\.dmg})
  end

  auto_updates true
  depends_on macos: ">= :big_sur"

  pkg "Open-EID.pkg"

  # Homebrew stores the uninstall script from Open-EID_#{version}.dmg in
  # /opt/homebrew/Caskroom/open-eid/#{version}/uninstall.sh
  uninstall script: {
    executable: "uninstall.sh",
    input:      ["y\n"],
    sudo:       true,
  }
end
