PLIST="./SimSim/Info.plist"

# Increment Build number
PLB=/usr/libexec/PlistBuddy
LAST_NUMBER=$($PLB -c "Print CFBundleVersion" "$PLIST")
NEW_VERSION=$(($LAST_NUMBER + 1))
$PLB -c "Set :CFBundleVersion $NEW_VERSION" "$PLIST"

# Build
xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# DMG
./Release/dmg/build.sh 

# ZIP
VERSION_STRING=$($PLB -c "Print CFBundleShortVersionString" $PLIST)
cd ./build/Release/
zip -r ../../Release/SimSim_${VERSION_STRING}.zip ./SimSim.app
cd ../../

echo "Done"