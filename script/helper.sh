#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

current_path=$PWD
app_name=$1
if [ -n "$2" ]; then
    inject_bin=$2
fi

printf "${YELLOW}🔎 app_name: ${app_name}${NC}\n"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

chmod a+x ${insert_dylib}
check_dylib_exist() {
    local app_path="$1"
    if otool -L "$app_path" | grep -q "${dylib_name}"; then
        return 0
    fi
    return 1
}

function resign_app() {
    sudo codesign --remove-signature "$1" >/dev/null 2>&1
    sudo xattr -cr "$1" >/dev/null 2>&1
    sudo codesign -f -s - --timestamp=none --all-architectures --deep "$1" >/dev/null 2>&1
}

BUILT_PRODUCTS_DIR="${current_path}/../release"

app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"
printf "${YELLOW}🔎 app_bundle_framework: ${app_bundle_framework}${NC}\n"

if [ ! -d "$app_bundle_framework" ]; then
    mkdir -p "$app_bundle_framework"
fi

if [ -n "$inject_bin" ]; then
    app_executable_path="$inject_bin"
else
    app_executable_path="${app_bundle_path}/${app_name}"
fi

if check_dylib_exist "$app_executable_path"; then
    printf "${RED}⛔️ The target program [${app_executable_path}] has already been patched. Overwriting now... 💉${NC}\n"
fi

app_executable_backup_path="${app_executable_path}_Backup"
printf "${YELLOW}🔎 app_executable_path: ${app_executable_path}${NC}\n"

if [ ! -f "$app_executable_backup_path" ]; then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

cp -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" "${app_bundle_framework}"
printf "${RED}⛔️ Checking the insert_dylib quarantine status...${NC}\n"
xattr "${insert_dylib}"

"${insert_dylib}" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"
printf "${GREEN}✅ [${app_name}] - dylib_dobby_hook Injection completed successfully.${NC}\n"

resign_app "/Applications/${app_name}.app"
printf "${GREEN}✅ [${app_name}] - Resigned successfully.${NC}\n"
