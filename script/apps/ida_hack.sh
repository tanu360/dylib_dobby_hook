current_path=$PWD
mac_patch_helper="$PWD/../tools/mac_patch_helper"
mac_patch_helper_config="$PWD/../tools/patch.json"

sudo chmod a+x $mac_patch_helper
ida_path="/Applications/IDA Professional 9.0.app"

$mac_patch_helper "IDA" $mac_patch_helper_config
cp -f "$PWD/apps/IDA/ida.hexlic" "$ida_path/Contents/MacOS/"
if [ "$(uname -m)" = "arm64" ]; then
    plugin_path="$ida_path/Contents/MacOS/plugins/arm_mac_user64.dylib"
    if [ -f "$plugin_path" ]; then
        sudo mv "$plugin_path" "${plugin_path}.Backup"
    fi
fi
