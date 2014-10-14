#!/bin/bash

declare -xi IN_ADMIN="$(/usr/bin/dscl /Search read /Groups/admin GroupMembership | /usr/bin/grep -c $USER)"
[ "$IN_ADMIN" != 1 ] &&    printf "%s\n" "This script requires admin access, you're logged in as $USER!" && exit 1

# Check OS to provide correct method/URL for CLI Tools installation
declare -x OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')

installDevTools(){
    # Wholeheartedly lifted from
    #  https://github.com/timsutton/osx-vm-templates/blob/master/scripts/xcode-cli-tools.sh
    if [ "$OSX_VERS" -ge 9 ]; then
        # create the placeholder file that's checked by the CLI updates .dist in Apple's SUS catalog
        /usr/bin/touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        # find the product id with "Developer" in the name
        PRODID=$(/usr/sbin/softwareupdate -l | awk '/Developer/{print x};{x=$0}' | awk '{print $2}')
        # install it (amazingly, it won't find the update if we put the update ID in double-quotes)
        /usr/sbin/softwareupdate -i $PRODID -v
    # on 10.7/10.8, we'd instead download from public download URLs, which can be found in
    # the dvtdownloadableindex:
    # https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
    else
        [ "$OSX_VERS" -eq 7 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
        [ "$OSX_VERS" -eq 8 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_osx_mountain_lion_april_2014.dmg
        TOOLSPATH="/tmp/clitools.dmg"
        /usr/bin/curl "$DMGURL" -o "$TOOLSPATH"
        TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
        /usr/bin/hdiutil attach "$TOOLSPATH" -mountpoint "$TMPMOUNT"
        /usr/sbin/installer -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
        /usr/bin/hdiutil detach "$TMPMOUNT"
        /bin/rm -rf "$TMPMOUNT"
        /bin/rm "$TOOLSPATH"
    fi
}
# Build array of most probable receipts from CLI tools for current & past OS versions, partially from
# https://github.com/Homebrew/homebrew/blob/208f963cf2/Library/Homebrew/os/mac/xcode.rb#L147-L150
declare -xa BUNDLE_IDS=('com.apple.pkg.DeveloperToolsCLI' \
    'com.apple.pkg.DeveloperToolsCLILeo' 'com.apple.pkg.CLTools_Executables' \
    'com.apple.pkg.XcodeMAS_iOSSDK_7_0')
# Set flag for the presence of a CLI tools receipt
declare -xi XCODE_CLI=0
# Iterate over array, break out and skip install if we get a zero return code
for id in ${BUNDLE_IDS[@]}; do
    /usr/sbin/pkgutil --pkg-info=$id > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        echo "Found "$id", Xcode Developer CLI Tools install not needed"
        echo ""
        echo ""
        ((XCODE_CLI++))
        break
    fi
done

if [[ $XCODE_CLI -ne 1 ]]; then
    echo "XCode Tools Installation"
    echo "------------------------"
    echo ""
    echo "Please wait while Xcode is installed"
    installDevTools
    if [[ $? -ne 0 ]]; then
        echo "Xcode installation failed" && exit 1
    fi
    echo ""
    echo ""
fi