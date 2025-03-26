# This installs a Windows Program FORScan into MacOS
# It uses Wine and creates a MacOS app bundle for it in pretty unorthodox way
cask "forscan" do
  version "2.3.65"
  sha256 "d16c86878e7e758db92dc4b695d7e3b25cd36d04ecfd8ed62c8135dae5bd524c"

  url "https://forscan.org/download/FORScanSetup#{version}.release.exe"
  
  # Also store the names into variables for easier reuse later
  name (name = "FORScan")
  app (app = "#{name}.app")

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

  # Intel Macs have homebrew in:   /usr/local/bin/brew
  # Apple Silicon Macs have it in: /opt/homebrew/bin/brew
  # This uses correct Wine path for both systems
  wine_executable = "#{HOMEBREW_PREFIX}/bin/wine"

  # Check if the homebrew install/uninstall wants to see the Wine output
  is_verbose_mode = (ARGV & %w[-v --verbose --debug -d]).any?

  # Runs the Forscan Windows installer
  installer script: {
    executable: wine_executable,
    # Wine output is confusing and not helpful for most of us
    print_stderr: is_verbose_mode,
    args: [
      # You can find the exe installer flags by running:
      # $ wine FORScanSetup2.3.65.release.exe /help
      # Default installation path is C:/Program Files (x86)/FORScan/
      "#{staged_path}/FORScanSetup#{version}.release.exe",
      # Windows .exe installer flags here:
      "/SP-", # No questions for user
      *("/VERYSILENT" unless is_verbose_mode) # No output
    ]
  }

  # This currently opens interactive dialog which asks if user wants to remove or not
  zap script: {
    executable: wine_executable,
    print_stderr: is_verbose_mode,
    args: [
      # Homebrew escapes special characters here so ~ or $HOME won't work
      "#{Dir.home}/.wine/drive_c/Program\ Files\ \(x86\)/FORScan/unins000.exe",
      # FIXME: The unins000.exe doesn't have flags which would allow silent uninstall
    ]
  }

  zap trash: [
    "~/.wine/drive_c/Program Files (x86)/FORScan",
    "~/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/FORScan",
    # Remove the com ports created by the launcher
    "~/.wine/dosdevices/com*",
  ]

  # Contents for the executable script inside the .app folder
  # Remember to escape the backslash '\' properly inside this script
  launcher_content = <<~EOS
    #!/usr/bin/osascript

    -- Ensure that the USB drivers have been installed already
    try
      do shell script "systemextensionsctl list | grep com.ftdi.vcp.dext > /dev/null"
    on error
      -- Install the USB driver system extension
      activate application "FTDIUSBSerialDextInstaller"
      repeat until application "FTDIUSBSerialDextInstaller" is running
        delay 0.1
      end repeat
      activate application "FTDIUSBSerialDextInstaller"
      tell application "System Events" to tell process "FTDIUSBSerialVCPDextInstaller"
        click button "Install FTDI USB Serial Dext VCP" of window 1
      end tell
      quit application "FTDIUSBSerialDextInstaller"
    end try

    -- Ensure that the USB device is connected and connect them to Wine
    try
      set serialDeviceLSOutput to (do shell script "ls /dev/cu.usbserial*")
      set serialDeviceList to paragraphs of serialDeviceLSOutput
      repeat with listIndex from 1 to length of serialDeviceList
        set serialDevicePath to item listIndex of serialDeviceList
        set comPort to "com" & listIndex
        -- Symlink the found serial devices to Wine
        do shell script "ln -sf " & serialDevicePath & " ~/.wine/dosdevices/" & comPort
        -- Add Windows registries for the symlinked com ports
        do shell script "#{wine_executable} reg add 'HKLM\\\\Software\\\\Wine\\\\Ports' /f /v " & comPort & " /t REG_SZ /d " & serialDevicePath
      end repeat
    on error
      display dialog "Connect your USB cable to MacOS first and re-open FORScan" with title "ERROR: No USB serial cables were found!" buttons {"Continue anyway", "Cancel"} default button "Cancel" cancel button "Cancel"
    end try

    -- Finally open the FORScan application itself through Wine
    do shell script "#{wine_executable} $HOME'/.wine/drive_c/Program Files (x86)/FORScan/FORScan.exe'"
  EOS

  # Source: https://www.artembutusov.com/how-to-wrap-wine-applications-into-macos-x-application-bundle/
  plist_content = <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>#{name}</string>
      <key>CFBundleIconFile</key>
      <string>AppIcon</string>
      <key>CFBundleIconName</key>
      <string>AppIcon</string>
      <key>CFBundleName</key>
      <string>#{name}</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>#{version}</string>
      <key>CFBundleSupportedPlatforms</key>
      <array>
        <string>MacOSX</string>
      </array>
    </dict>
    </plist>
  EOS

  # Create the Forscan.app using ducktape which homebrew then moves to /Applications
  # /Applications/Forscan.app
  # └── Contents
  #     ├── Info.plist <-- MacOS app bundle metadata from plist_content variable
  #     ├── MacOS
  #     │   └── FORScan <-- Executable from launcher_content variable
  #     └── Resources
  #         ├── AppIcon.icns <-- Converted with sips from AppIcon.png
  #         └── AppIcon.png <-- Extracted from Forscan.lnk Windows shortcut
  preflight do
    # Create the app bundle structure
    FileUtils.mkdir_p "#{staged_path}/#{app}/Contents/MacOS"
    Dir.chdir("#{staged_path}/#{app}/Contents") do
      # Create the executable script
      File.write "MacOS/#{name}", launcher_content
      FileUtils.chmod 0755, "MacOS/#{name}"

      # Create the Info.plist
      File.write "Info.plist", plist_content
    end
  end

  # The FORScan.lnk shortcut in drive_c is not available preflight
  # because the installer.exe has not been used yet
  postflight do
    # Create the FORScan.app icon
    FileUtils.mkdir "#{staged_path}/#{app}/Contents/Resources"
    Dir.chdir("#{staged_path}/#{app}/Contents/Resources") do
      # Use Wine utility to extract icon from the Windows shortcut
      win_shortcut = '~/.wine/drive_c/ProgramData/Microsoft/Windows/Start\ Menu/Programs/FORScan/FORScan.lnk'
      `#{HOMEBREW_PREFIX}/bin/wine winemenubuilder -t #{win_shortcut} AppIcon.png`
      # Convert the icon using sips which is always available on MacOS
      `sips -s format icns AppIcon.png -o AppIcon.icns`
    end
    # Force MacOS to refresh the icon cache
    FileUtils.touch "#{staged_path}/#{app}"
  end
end
