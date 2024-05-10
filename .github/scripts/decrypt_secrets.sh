#!/bin/sh

# Decrypt the gpg encrypted keys, certs, profiles
# decrypt the correct provisioning profile based on the target environment (development, staging, or production for prod)
# once we can submit a new app
echo "Using APP_REGION value of ${TARGET_REGION}"
echo "Unpacking ./.github/secrets/profile.mobileprovision${TARGET_REGION}.gpg"
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_PROFILE_KEY" --output ./.github/secrets/profile.mobileprovision "./.github/secrets/profile.mobileprovision${TARGET_REGION}.gpg"
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_PROFILE_KEY" --output ./.github/secrets/Certificates.p12 ./.github/secrets/Certificates.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_PROFILE_KEY" --output ./.github/secrets/AuthKey.p8 ./.github/secrets/AuthKey.p8.gpg

echo "Showing output mobileprovision file"
ls -l ./.github/secrets/profile.mobileprovision

# Install the provisioning profile in default location
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp ./.github/secrets/profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

# Install the app store API key in default location
mkdir -p ~/.appstoreconnect/private_keys
cp ./.github/secrets/AuthKey.p8 ~/.appstoreconnect/private_keys/AuthKey_${APPSTORE_API_KEY}.p8

# Create a build keychain and set it as default for xcode to use for signing
echo "Building keychain"
security create-keychain -p "$IOS_PROFILE_KEY" ~/Library/Keychains/build.keychain
security set-keychain-settings -lut 21600 ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "$IOS_PROFILE_KEY" ~/Library/Keychains/build.keychain

# Add the signing certificate in to the build keychain
echo "Importing Certificates"
security import ./.github/secrets/Certificates.p12 -t agg \
  -k ~/Library/Keychains/build.keychain \
  -P "$IOS_PROFILE_KEY" \
  -A -T /usr/bin/codesign -T /usr/bin/security

# Do a weird thing that is required for Xcode to be able to find the right certificate
echo "Setting key partition list for Xcode"
security set-key-partition-list -S apple-tool:,apple: -s -k "$IOS_PROFILE_KEY" ~/Library/Keychains/build.keychain
