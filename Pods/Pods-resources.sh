#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcassets)
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "OvershareKit/Overshare Kit/Images/1Password-Icon-120.png"
install_resource "OvershareKit/Overshare Kit/Images/1Password-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/1Password-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/1Password-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Chrome-Icon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/Chrome-Icon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Chrome-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Chrome-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/Chrome-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-120.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/Instapaper-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/link-button.png"
install_resource "OvershareKit/Overshare Kit/Images/link-button@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Omnifocus-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Omnifocus-Icon-72.png"
install_resource "OvershareKit/Overshare Kit/Images/Omnifocus-Icon-72@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-airDropIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-airDropIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-airDropIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appDotNetIcon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appDotNetIcon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appDotNetIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appDotNetIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appDotNetIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appStoreIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-appStoreIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-purple-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-purple-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-purple-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-purple-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-yellow-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-yellow-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-yellow-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-copyIcon-yellow-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-facebookIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-facebookIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-facebookIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-flickrIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-flickrIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-flickrIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iap-badge-60.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iap-badge-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iap-badge-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iap-badge-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-icon-border-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-icon-border-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-icon-border-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iconMask-bw-29.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iconMask-bw-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iconMask-bw-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iconMask-bw-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-iconMask-bw-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-mailIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-mailIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-mailIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-messagesIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-messagesIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-messagesIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton-disabled.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton-disabled@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton-highlighted.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton-highlighted@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-navbarButton@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-photosIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-photosIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-photosIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-pinboardIcon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-pinboardIcon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-pinboardIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-pinboardIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-pinboardIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-readabilityIcon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-readabilityIcon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-readabilityIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-readabilityIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-readabilityIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-safariIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-safariIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-safariIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-settingsPlaceholder@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-twitterIcon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-twitterIcon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/osk-twitterIcon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Pocket-Icon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/Pocket-Icon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Pocket-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Pocket-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/Pocket-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-29.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-29@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-60.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/ReadingList-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Riposte-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Riposte-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/Riposte-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Things-Icon-60@2x.png"
install_resource "OvershareKit/Overshare Kit/Images/Things-Icon-76.png"
install_resource "OvershareKit/Overshare Kit/Images/Things-Icon-76@2x.png"
install_resource "OvershareKit/Overshare Kit/OSKActivityCollectionViewCell.xib"
install_resource "OvershareKit/Overshare Kit/OSKActivityCollectionViewCell_Pad.xib"
install_resource "OvershareKit/Overshare Kit/OSKActivitySheetViewController.xib"
install_resource "OvershareKit/Overshare Kit/OSKFacebookPublishingViewController.xib"
install_resource "OvershareKit/Overshare Kit/OSKMicroblogPublishingViewController.xib"

rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ `xcrun --find actool` ] && [ `find . -name '*.xcassets' | wc -l` -ne 0 ]
then
  case "${TARGETED_DEVICE_FAMILY}" in 
    1,2)
      TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
      ;;
    1)
      TARGET_DEVICE_ARGS="--target-device iphone"
      ;;
    2)
      TARGET_DEVICE_ARGS="--target-device ipad"
      ;;
    *)
      TARGET_DEVICE_ARGS="--target-device mac"
      ;;  
  esac 
  find "${PWD}" -name "*.xcassets" -print0 | xargs -0 actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
