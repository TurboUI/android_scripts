#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo() {
	msgId=`builtin echo "$@" | xargs`
	msgId=${msgId:1:1}
	endColor='\033[0m'
	if [ "$msgId" == "!" ]; then
		# red
		builtin echo -e -n "\033[1;31m"
	elif [ "$msgId" == "i" ]; then
		# green
		builtin echo -e -n "\033[1;32m"
	elif [ "$msgId" == "#" ]; then
		# blue
		builtin echo -e -n "\033[1;34m"
	fi
	builtin echo -e "$@${endColor}";
}

echo "[#] Cleaning and (re)generating GSI device tree... "
(cd $SCRIPT_DIR/../device/phh/treble; git clean -fdx > /dev/null; bash generate.sh)

sed -i -e 's/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1610612736/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648/g' $SCRIPT_DIR/../device/phh/treble/phhgsi_arm64_a/BoardConfig.mk
echo "    [i] Patched phhgsi_arm64_a system image size"
