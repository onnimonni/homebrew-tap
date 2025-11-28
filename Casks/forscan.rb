cask "forscan" do
  version "2.3.68"

  if OS.mac?
    sha256 "c684ee00871d6039e931291d36134d9b9d977154cdb75087c999ec9f9d1d85e0"
    # Casks not supported on Linux: https://github.com/Linuxbrew/brew/issues/742
  end

  url "https://forscan.org/download/FORScanSetup#{version}.release.exe"
  name(name = "FORScan")
  desc "Software scanner for Ford, Mazda, Lincoln and Mercury vehicles"
  homepage "https://forscan.org/home.html"

  livecheck do
    url "https://forscan.org/changes_history.html"
    regex(%r{href=.*download/FORScanSetup(\d+(?:\.\d+)+)\.release\.exe})
  end

  # This is a Windows program on MacOS so it doesn't update itself
  auto_updates false
  # Use same Depends on as wine-stable
  # https://github.com/Homebrew/homebrew-cask/blob/master/Casks/w/wine-stable.rb#L39
  depends_on macos: ">= :catalina"
  # Since Forscan is made for Windows we need to install Wine to run it
  depends_on cask: "wine-stable"
  # Virtual COM Drivers which work for vLinker FS USB OBD2 reader
  # They also should work for the OBDLink EX which is the other recommended cable
  # These are needed for the MacOS host machine to detect the OBD2 reader
  depends_on cask: "ftdi-vcp-driver"

  app(app = "#{name}.app")
  # Intel Macs have homebrew in:   /usr/local/bin/brew
  # Apple Silicon Macs have it in: /opt/homebrew/bin/brew
  # This uses correct Wine path for both systems
  wine_executable = "#{HOMEBREW_PREFIX}/bin/wine"

  # Check if the homebrew install/uninstall wants to see the Wine output
  is_verbose_mode = ARGV.intersect?(%w[-v --verbose --debug -d])

  # Runs the Forscan Windows installer
  installer script: {
    executable:   wine_executable,
    # Wine output is confusing and not helpful for most of us
    print_stderr: is_verbose_mode,
    args:         [
      # You can find the exe installer flags by running:
      # $ wine FORScanSetup2.3.65.release.exe /help
      # Default installation path is C:/Program Files (x86)/FORScan/
      "#{staged_path}/FORScanSetup#{version}.release.exe",
      # Windows .exe installer flags here:
      "/SP-", # No questions for user
      *("/VERYSILENT" unless is_verbose_mode), # No output
    ],
  }

  preflight do
    # Creates the FORScan.app wrapper into the system
    FileUtils.cp_r File.expand_path("#{__dir__}/../#{app}"), "#{staged_path}/"

    # Replace the wine path to match current system to support Intel Macs as well
    launcher = "#{staged_path}/#{app}/Contents/MacOS/#{name}"
    File.write(launcher, File.read(launcher).gsub("/opt/homebrew/bin/wine", wine_executable))
  end

  # Casks don't support assertions so we will use postflight instead
  postflight do
    unless File.exist? "#{Dir.home}/.wine/drive_c/Program Files (x86)/FORScan/FORScan.exe"
      raise "FORScan.exe is missing from default location!"
    end
    if `defaults read /Applications/#{app}/Contents/Info CFBundleName`.strip != name
      raise "FORScan.app is not installed properly!"
    end
  end

  # This happens in every upgrade because homebrew audit verification is stupid:
  # - installer and pkg stanzas require an uninstall stanza
  # - only a single zap stanza is allowed
  uninstall trash: [
    # Remove the com ports created by the launcher
    "~/.wine/dosdevices/com*",
    "~/.wine/drive_c/Program Files (x86)/FORScan",
    "~/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/FORScan",
  ]

  # This currently opens interactive dialog which asks if user wants to remove or not
  zap script: {
    executable:   wine_executable,
    print_stderr: is_verbose_mode,
    args:         [
      # Homebrew escapes special characters here so ~ or $HOME won't work
      "#{Dir.home}/.wine/drive_c/Program Files (x86)/FORScan/unins000.exe",
    ],
  }
end
