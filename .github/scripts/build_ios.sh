#!/bin/sh
cd ios

export XCARCHIVE_LOCATION=$PWD/build/mePrism.xcarchive
export IPA_LOCATION=$PWD/build/mePrism.ipa
# @Todo set bundle idenfier env variable based on environment PRODUCT_BUNDLE_IDENTIFIER
# only after we update React Native
if [ "$TARGET_REGION" == "development" ]
then
  PRODUCT_BUNDLE_IDENTIFIER=com.mePrism.client.development
  PROFILE_SUFFIX="-development"
  APPICON_SUFFIX="-development"
elif [ "$TARGET_REGION" == "staging" ]
then
  PRODUCT_BUNDLE_IDENTIFIER=com.mePrism.client.staging
  PROFILE_SUFFIX="-staging"
  APPICON_SUFFIX="-staging"
else
  export PRODUCT_BUNDLE_IDENTIFIER=com.meprism.privacy
fi

echo "PROFILE_SUFFIX=${PROFILE_SUFFIX}"
echo "PRODUCT_BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER}"

security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision >temp_profile.plist
PROFILE_UUID=`/usr/libexec/PlistBuddy -c "Print UUID" temp_profile.plist`
echo "PROFILE UUID = ${PROFILE_UUID}"
rm temp_profile.plist

# set a variable for the provisioning profile since it will change per environment

echo "Unlocking build keychain."
security unlock-keychain -p "$IOS_PROFILE_KEY" ~/Library/Keychains/build.keychain
security list-keychains -d user -s ~/Library/Keychains/build.keychain login.keychain

echo "Creating build archive"

# Explicitly set CCs to use a locally resolved CC
# to enable a cache to wrap compiler invocations
xcodebuild CC=clang \
  CPLUSPLUS=clang++ \
  LD=clang \
  LDPLUSPLUS=clang++ \
  archive \
  -workspace mePrism.xcworkspace \
  -scheme mePrism \
  -sdk iphoneos \
  -configuration Release \
  -archivePath $XCARCHIVE_LOCATION \
  -quiet \
  IPHONEOS_DEPLOYMENT_TARGET=15.0 \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=F76QBA9P66 \
  PROVISIONING_PROFILE="${PROFILE_UUID}" \
  PROVISIONING_PROFILE_SPECIFIER="${PROFILE_UUID}" \
  PRODUCT_BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER} \
  ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon${APPICON_SUFFIX}" \
  CODE_SIGN_IDENTITY="iPhone Distribution"

if [ ! -d $XCARCHIVE_LOCATION ]; then
  echo "Error: $XCARCHIVE_LOCATION not created."
  exit 1
fi

echo "Creating export from build archive $XCARCHIVE_LOCATION."
# Explicitly set CCs to use a locally resolved CC
# to enable a cache to wrap compiler invocations
xcodebuild \
  CC=clang \
  CPLUSPLUS=clang++ \
  LD=clang \
  LDPLUSPLUS=clang++ \
  -exportArchive \
  -archivePath $XCARCHIVE_LOCATION \
  -exportOptionsPlist $PWD/iOS-ExportOptions.plist \
  -exportPath $PWD/build

if [ ! -f $IPA_LOCATION ]; then
  echo "Error: $IPA_LOCATION not created."
  exit 1
fi
