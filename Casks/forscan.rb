# Great example where to learn more: https://github.com/krehel/homebrew-cask/blob/cfa829188a9a67f3f10f023b148e0caa576fc7ba/Casks/g/ghidra.rb#L31
cask "forscan" do
  version "2.3.59"
  sha256 "15e717877acff5dafd2f6a36ce467f2a2e06e1cd0a61480994e9c6b2ed45f7be"

  url "https://forscan.org/download/FORScanSetup#{version}.release.exe"
  name "Forscan"
  desc "Software scanner for Ford, Mazda, Lincoln and Mercury vehicles"
  homepage "https://forscan.org/home.html"

  livecheck do
    url "https://forscan.org/changes_history.html"
    regex(/href=.*download\/FORScanSetup(\d+(?:\.\d+)+)\.release\.exe/)
  end

  depends_on macos: ">= :big_sur"
  
  # Since Forscan is made for Windows we need to install Wine to run it
  depends_on cask: "wine-stable"

  # Virtual COM Drivers which work for vLinker FS USB OBD2 reader
  # They also should work for the OBDLink EX which is the other recommended cable
  # These are needed for the MacOS host machine to detect the OBD2 reader
  depends_on cask: "ftdi-vcp-driver"

  # Runs the Forscan Windows installer
  installer script: {
    executable: "wine",
    args: [
      "#{staged_path}/FORScanSetup#{version}.release.exe",
      # Windows EXE installer options here:
      # Run the forscan without user input
      '/SP-',
      '/VERYSILENT',
      # Default installation path is C:/Program Files (x86)/FORScan/
    ],
  }

  forscan_launcher_content = <<~EOS
    #!/bin/zsh

    # Check that the drivers have been installed
    if systemextensionsctl list | grep com.ftdi.vcp.dext
    then 
        echo "Drivers have already been installed"
    else
        osascript -e 'display dialog "Install USB Drivers and reboot your machine" with title "ERROR: USB FTDI drivers not found!" buttons {"Continue"} default button "Continue"'
        open -a "FTDIUSBSerialDextInstaller.app"
    fi
    # Check all USB serial devices
    usb_serial_devices=($(ls /dev/cu.usbserial*))
    
    # Connect the USB serial devices to Forscan
    if [ ${#usb_serial_devices[@]} -eq 0 ]; then
        osascript -e 'display dialog "Connect your USB cable to MacOS first and re-open Forscan" with title "ERROR: No USB serial cables were found!" buttons {"Continue anyway", "OK"} default button "OK" cancel button "Continue anyway"'
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            exit $RESULT
        else
            echo "Continuing without USB devices"
        fi
    else
        local com_device_index=1
        for usb_serial_device in $usb_serial_devices; do
            echo "USB Serial found: $usb_serial_device"
            # Symlink the needed usb serial devices inside wine
            ln -sf $usb_serial_device ~/.wine/dosdevices/com$com_device_index
    
            # Add Windows registries for the symlinked com ports
            /opt/homebrew/bin/wine reg add "HKEY_LOCAL_MACHINESoftwareWinePorts" /f /v com$com_device_index /t REG_SZ /d $usb_serial_device
            ((++com_device_index))
        done
    fi
    
    open -a "Wine Stable" "$HOME/.wine/drive_c/Program Files (x86)/FORScan/FORScan.exe"
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

  # Create the Forscan.app using ducktape
  preflight do
    FileUtils.mkdir_p "#{staged_path}/FORScan.app/Contents/MacOS"
    File.write "#{staged_path}/FORScan.app/Contents/MacOS/FORScan", forscan_launcher_content
    FileUtils.chmod 0755, "#{staged_path}/FORScan.app/Contents/MacOS/FORScan"
    FileUtils.mkdir_p "#{staged_path}/FORScan.app/Contents/Resources/image.iconset"
    File.write "#{staged_path}/FORScan.app/Contents/Resources/Info.plist", forscan_plist_content
  end

  
  # TODO: App icon is not working
  #postflight do
    ## Extract the application image with Wine
    ## Source: https://unix.stackexchange.com/a/510631
    ## TODO: Find a better way to find wine than to hardcode it like this
    #system "/opt/homebrew/bin/wine winemenubuilder -t ~/.wine/drive_c/ProgramData/Microsoft/Windows/Start\\ Menu/Programs/FORScan/FORScan.lnk /Applications/FORScan.app/Contents/Resources/image.iconset/icon_128x128.png"
    ## Create icns file to show the image
    #system "iconutil -c icns /Applications/FORScan.app/Contents/Resources/image.iconset --output /Applications/FORScan.app/Contents/Resources/AppIcon.icns"
  #end

  # In case wine was installed without FORScan
  zap trash: "~/.wine/drive_c/Program\ Files\ \(x86\)/FORScan"
  zap trash: "~/.wine/drive_c/ProgramData/Microsoft/Windows/Start\ Menu/Programs/FORScan"
  
  auto_updates false

  app "FORScan.app"
end
