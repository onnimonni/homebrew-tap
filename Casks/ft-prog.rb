cask "ft-prog" do
  version "3.12.55.667"
  sha256 "fad11dd5f91a86961b2435798eeae8241dd3a69c92808f5b9eedfe35eac2a77c"

  # TODO: the uploads/2024/11 will probably not work with our livecheck
  url "https://ftdichip.com/wp-content/uploads/2024/11/FT_Prog_v#{version}-Installer.zip"
  name "FT_Prog"
  desc "EEPROM programming utility for use with FTDI devices"
  homepage "https://ftdichip.com/utilities/"

  livecheck do
    url "https://ftdichip.com/utilities/"
    regex(%r{href=.*FT_Prog_v(\d+(?:\.\d+)+)\-Installer\.zip})
  end

  auto_updates false
  depends_on macos: ">= :big_sur"
  # Since FT_Prog is made for Windows we need to install Wine to run it
  depends_on cask: "wine-stable"
  # These are needed for the MacOS host machine to detect the FTDI chip
  depends_on cask: "ftdi-vcp-driver"

  app "FT_Prog.app"
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
        do shell script "/opt/homebrew/bin/wine reg add 'HKLM\\\\Software\\\\Wine\\\\Ports' /f /v " & comPort & " /t REG_SZ /d " & serialDevicePath
      end repeat
    on error
      display dialog "Connect your FTDI device to MacOS first and re-open FT_Prog" with title "ERROR: No USB serial cables were found!" buttons {"Continue anyway", "Cancel"} default button "Cancel" cancel button "Cancel"
    end try

    -- Finally open the FORScan application itself through Wine
    do shell script "open -a 'Wine Stable' \\"$HOME/.wine/drive_c/Program Files (x86)/FTDI/FT_Prog/FT_Prog.exe\\""
  EOS

  # Source: https://www.artembutusov.com/how-to-wrap-wine-applications-into-macos-x-application-bundle/
  forscan_plist_content = <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>FT_Prog</string>
        <key>CFBundleGetInfoString</key>
        <string>FT_Prog</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleIconName</key>
        <string>AppIcon</string>
        <key>CFBundleName</key>
        <string>FT_Prog</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleSignature</key>
        <string>4242</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
    </plist>
  EOS

  # Runs the FT_Prog Windows installer
  installer script: {
    executable: "wine",
    args:       [
      "#{staged_path}/FT_Prog_v#{version} Installer.exe",
      # Windows EXE installer options here:
      # Run the forscan without user input
      "/SP-",
      "/VERYSILENT",
      # Default installation path is C:/Program Files (x86)/FORScan/
    ],
  }

  # Create the FT_Prog.app using ducktape
  preflight do
    FileUtils.mkdir_p "#{staged_path}/FT_Prog.app/Contents/MacOS"
    File.write "#{staged_path}/FT_Prog.app/Contents/MacOS/FORScan", forscan_launcher_content
    FileUtils.chmod 0755, "#{staged_path}/FT_Prog.app/Contents/MacOS/FORScan"
    FileUtils.mkdir_p "#{staged_path}/FT_Prog.app/Contents/Resources/image.iconset"
    File.write "#{staged_path}/FT_Prog.app/Contents/Resources/Info.plist", forscan_plist_content
  end

  # TODO: Maybe this could use the "unins000.exe" inside FORScan instead. The delete key requires password
  uninstall delete: [
    "~/.wine/drive_c/Program Files (x86)/FTDI/FT_Prog",
    "~/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/FTDI/FT_Prog",
  ]
end
