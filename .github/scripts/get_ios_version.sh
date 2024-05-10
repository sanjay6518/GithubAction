set -e

cd ios
export APP_VERSION=$(xcodebuild -quiet -configuration Release -showBuildSettings 2> /dev/null | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION =')
echo $APP_VERSION
