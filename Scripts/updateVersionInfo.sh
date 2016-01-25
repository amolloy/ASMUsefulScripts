#!/bin/bash

appBuild=`git rev-list --all |wc -l`

revision_no="$(git symbolic-ref HEAD 2> /dev/null | cut -b 12-)-$(git log --pretty=format:'%h, %ad' -1)"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $appBuild" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Set RevisionNumber ${revision_no//\'/}" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
