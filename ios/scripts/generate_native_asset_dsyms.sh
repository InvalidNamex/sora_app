#!/bin/sh

set -eu

# Flutter 3.41 packages Dart native assets as dynamic frameworks, but does not
# copy their dSYMs into the Xcode archive. objective_c includes DWARF line data,
# so generate its matching dSYM after Flutter embeds the framework.
: "${TARGET_BUILD_DIR:?}"
: "${FRAMEWORKS_FOLDER_PATH:?}"
: "${DWARF_DSYM_FOLDER_PATH:?}"

framework_name="objective_c"
framework_binary="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/${framework_name}.framework/${framework_name}"

if [ ! -f "${framework_binary}" ]; then
	exit 0
fi

dsym_path="${DWARF_DSYM_FOLDER_PATH}/${framework_name}.framework.dSYM"
/bin/rm -rf "${dsym_path}"
/bin/mkdir -p "${DWARF_DSYM_FOLDER_PATH}"
/usr/bin/xcrun dsymutil "${framework_binary}" -o "${dsym_path}"

echo "Generated ${dsym_path}"
