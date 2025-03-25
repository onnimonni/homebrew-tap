cask "forscan" do
  version "2.3.65"
  sha256 "d16c86878e7e758db92dc4b695d7e3b25cd36d04ecfd8ed62c8135dae5bd524c"

  url "https://forscan.org/download/FORScanSetup#{version}.release.exe"
  name "FORScan"
  desc "Software scanner for Ford, Mazda, Lincoln and Mercury vehicles"
  homepage "https://forscan.org/home.html"

  livecheck do
    url "https://forscan.org/changes_history.html"
    regex(%r{href=.*download/FORScanSetup(\d+(?:\.\d+)+)\.release\.exe})
  end

  auto_updates false
  depends_on macos: ">= :big_sur"
  # Since Forscan is made for Windows we need to install Wine to run it
  depends_on cask: "wine-stable"
  # Virtual COM Drivers which work for vLinker FS USB OBD2 reader
  # They also should work for the OBDLink EX which is the other recommended cable
  # These are needed for the MacOS host machine to detect the OBD2 reader
  depends_on cask: "ftdi-vcp-driver"

  app "FORScan.app"
  # Remember to escape the backslash properly inside this script \
  forscan_launcher_content = <<~EOS
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
        do shell script "#{HOMEBREW_PREFIX}/bin/wine reg add 'HKLM\\\\Software\\\\Wine\\\\Ports' /f /v " & comPort & " /t REG_SZ /d " & serialDevicePath
      end repeat
    on error
      display dialog "Connect your USB cable to MacOS first and re-open FORScan" with title "ERROR: No USB serial cables were found!" buttons {"Continue anyway", "Cancel"} default button "Cancel" cancel button "Cancel"
    end try

    -- Finally open the FORScan application itself through Wine
    do shell script "#{HOMEBREW_PREFIX}/bin/wine $HOME'/.wine/drive_c/Program Files (x86)/FORScan/FORScan.exe'"
  EOS

  # Source: https://www.artembutusov.com/how-to-wrap-wine-applications-into-macos-x-application-bundle/
  forscan_plist_content = <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>FORScan</string>
        <key>CFBundleGetInfoString</key>
        <string>FORScan</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleIconName</key>
        <string>AppIcon</string>
        <key>CFBundleName</key>
        <string>FORScan</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleSignature</key>
        <string>4242</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
    </plist>
  EOS

  # Runs the Forscan Windows installer
  installer script: {
    executable: "wine",
    args:       [
      "#{staged_path}/FORScanSetup#{version}.release.exe",
      # Windows EXE installer options here:
      # Run the forscan without user input
      "/SP-",
      "/VERYSILENT",
      # Default installation path is C:/Program Files (x86)/FORScan/
    ],
  }

  # Create the Forscan.app using ducktape
  preflight do
    FileUtils.mkdir_p "#{staged_path}/FORScan.app/Contents/MacOS"
    File.write "#{staged_path}/FORScan.app/Contents/MacOS/FORScan", forscan_launcher_content
    FileUtils.chmod 0755, "#{staged_path}/FORScan.app/Contents/MacOS/FORScan"
    FileUtils.mkdir_p "#{staged_path}/FORScan.app/Contents/Resources/image.iconset"
    File.write "#{staged_path}/FORScan.app/Contents/Resources/Info.plist", forscan_plist_content
  end

  # TODO: Maybe this could use the "unins000.exe" inside FORScan instead. The delete key requires password
  uninstall delete: [
    "~/.wine/drive_c/Program Files (x86)/FORScan",
    "~/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/FORScan",
  ]
end
