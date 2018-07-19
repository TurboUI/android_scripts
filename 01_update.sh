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


#repo init -u git@github.com:TurboUI/platform_manifest.git -b turbo_1.0 --depth=10 --groups=all,-notdefault,-device,-darwin,-x86,-mips,-exynos5,-intel
if [ "$1" == "sync" ]; then
	echo ""
	echo "[#] Syncing..."
	(
	cd "$SCRIPT_DIR/.."
	# 2DO - do a --force-sync, but warn user about checking repo status first
	repo sync -j8
	)
else
	echo "[i] repo sync skipped. Run again with 'sync' parameter to perform repo sync."
fi

echo "[#] Checking for updates..."
if [ ! -f "$SCRIPT_DIR/last_updated_ids" ]; then
	echo "    [!] last_updated_ids does not exist. Aborting."
	exit 1
fi

source "$SCRIPT_DIR/last_updated_ids"

for repoName in "treble_experimentations" "treble_manifest" "treble_patches"; do
	# ensure the ${repoName}_last and _branch value was specified in last_updated_ids
	keyNameLast="${repoName}_last"
	keyNameBranch="${repoName}_branch"
	if [ -z "${!keyNameLast}" ]; then
		echo "    [!] last_updated_ids is incomplete (missing $keyNameLast value). Aborting."
		exit 1
	fi
	# clone or update this repoName
	if [ -d "$SCRIPT_DIR/${repoName}" ]; then
		echo "[#] Updating cached repo phhusson/${repoName} ..."
		(
		cd "$SCRIPT_DIR/${repoName}"
		git fetch
		git reset --hard
		git checkout ${!keyNameBranch}
		)
	else
		echo "[#] Cloning repo phhusson/${repoName} for cache..."
		git clone https://github.com/phhusson/${repoName} "$SCRIPT_DIR/${repoName}" -b ${!keyNameBranch}
	fi
	# rewind the cached repo to the _last id
	echo "    [#] Rewinding cached repo to last_updated_ids entry (${!keyNameLast})..."
	(
	cd "$SCRIPT_DIR/${repoName}"
	git reset --hard ${!keyNameLast}
	)
	# compare to origin HEAD
	keyNameLatest=${repoName}_latest
	declare ${keyNameLatest}=`git ls-remote https://github.com/phhusson/${repoName} refs/heads/${!keyNameBranch} | awk '{print $1}'`
	if [ "${!keyNameLatest}" != "${!keyNameLast}" ]; then
		echo "    [!] $repoName branch ${!keyNameBranch} has updates (old id = ${!keyNameLast}; new id = ${!keyNameLatest}"
	else
		echo "    [i] $repoName branch ${!keyNameBranch} is up to date."
	fi
done

echo ""