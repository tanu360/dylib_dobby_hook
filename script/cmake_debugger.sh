#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

current_path=$PWD

app_name="DevUtils"

printf "\n${YELLOW}🔎 app_name: ${app_name}${NC}\n"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

chmod a+x ${insert_dylib}

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

app_executable_backup_path="${app_executable_path}_Backup"
printf "${YELLOW}🔎 app_executable_path: ${app_executable_path}${NC}\n"

if [ ! -f "$app_executable_backup_path" ]; then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

"${insert_dylib}" --weak --all-yes "${current_path}/../release/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"

printf "${GREEN}✅ [${app_name}] - dylib_dobby_hook Injection completed successfully.${NC}\n"
