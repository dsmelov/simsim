cd "`dirname "$0"`"
echo removing old files
echo `find . -name SimSim*.dmg -delete`
appver="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString"  "../../Build/Products/Release/SimSim.app/Contents/Info.plist")"
echo building dmg
appdmg dmg_config.json "SimSim_"$appver".dmg"
echo dmg done
