#!/bin/sh

#  bump_build_on_archive.sh
#  HSPreassessment
#
#  Created by Chris Hardin on 11/26/12.
#  Copyright (c) 2012 HealthSouth. All rights reserved.


if [ $CONFIGURATION == Release ]; then
echo "Bumping build number..."
plist=${PROJECT_DIR}/${INFOPLIST_FILE}

# increment the build number (ie 115 to 116)
buildnum=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${plist}")
if [[ "${buildnum}" == "" ]]; then
echo "No build number in $plist"
exit 2
fi

buildnum=$(expr $buildnum + 1)
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "${plist}"
echo "Bumped build number to $buildnum"

else
echo $CONFIGURATION " build - Not bumping build number."
fi