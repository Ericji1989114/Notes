#!/bin/sh

DEVICE_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-device

# make sure the output directory exists
mkdir -p "${DEVICE_OUTPUTFOLDER}"

# Next, work out if we're in DEVICE
if [ "false" == ${ALREADYINVOKED:-false} ]
then

export ALREADYINVOKED="true"

# Step 1. Generate the framework
if [ ${PLATFORM_NAME} = "iphoneos" ]
then
xcodebuild -target "${PROJECT_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
else
xcodebuild -target "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
fi

# Step 2. Convert xib file into nib file
find "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/" -name "*.xib" -type f | awk '{sub(/.xib/,"");print}' | xargs -I % ibtool --compile %.nib %.xib

# Step 3. Remove xib file & assets file in the output
find "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/" -name "*.xib" |xargs rm -rf
find "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/" -name "*.xcassets" |xargs rm -rf

# Step 4. Move the language file into bundle
cd "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework"
cp -f en.lproj/* "./KitBundle.bundle/en.lproj/"
cp -f ja.lproj/* "./KitBundle.bundle/ja.lproj/"
rm -rf "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/en.lproj/"
rm -rf "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/ja.lproj/"

# Step 5. Copy the framework structure (from iphoneos build) to the device folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${DEVICE_OUTPUTFOLDER}/"

# Step 6. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${DEVICE_OUTPUTFOLDER}/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule"
fi

# Step 7. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${DEVICE_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}"


# Step 8. Convenience step to copy the framework to the project's directory
cp -R "${DEVICE_OUTPUTFOLDER}/${PROJECT_NAME}.framework" "${PROJECT_DIR}"

# Step 9. Clean up the build folder
rm -rf "${PROJECT_DIR}/build/"

# Step 10. Convenience step to open the project's directory in Finder
open "${PROJECT_DIR}"

fi
