#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ "$1" = "--help" ]; then
	echo "$0 <flashrom binary> <ec|host>"
	exit 0
fi

FLASHROM=$1

if [ ! -x "$FLASHROM" ]; then
	echo "Error: $FLASHROM is not valid"
	exit 1
fi

FLASHCHIP=$2
if [ "$FLASHCHIP" != "ec" ] && [ "$FLASHCHIP" != "host" ]; then
	echo "Error: '$FLASHCHIP' should either be 'ec' or 'host'"
	exit 1
fi

KNOWN_GOOD_ROM=$3

if [ "$EUID" != "0" ]; then
   echo "Error: This script must be run as root"
   exit 1
fi

LAYOUT_FILE=layout.txt
RANDOM_FILE=random_content.bin
ORIGINAL_FILE=original.rom

TESTS_FAILED=0
READ=""
ERASE_WRITE=""
LOCK_BOTTOM_QUAD=""
LOCK_BOTTOM_HALF=""
LOCK_TOP_HALF=""
LOCK_TOP_QUAD=""
UNLOCK=""


# Check that flashrom passes when it should
flash_test_pass () {
	local PARAMETERS=("${@}")
	local PRINT_PARAM="$(echo "${PARAMETERS[@]}" | tr '\n' ' ')"

	printf "\n%s -p %s %s\n" "$FLASHROM" "$FLASHCHIP" "$PRINT_PARAM"
	# shellcheck disable=SC2068
	$FLASHROM -p "$FLASHCHIP" ${PARAMETERS[@]} ; RET=$?
	if [ "$RET" != "0" ]; then
		echo "*********************************************************"
		printf "Error: %s -p %s %s failed.\n" "$FLASHROM" "$FLASHCHIP" "$PRINT_PARAM"
		echo "*********************************************************"
	fi

	return $RET
}

# Check that flashrom fails when it should
flash_test_fail () {
	local PARAMETERS=("${@}")
	local PRINT_PARAM="$(echo "${PARAMETERS[@]}" | tr '\n' ' ')"

	printf "\nThis next command is expected to fail."
	printf "\n%s -p %s %s\n" "$FLASHROM" "$FLASHCHIP" "$PRINT_PARAM"
	# shellcheck disable=SC2068
	$FLASHROM -p "$FLASHCHIP" ${PARAMETERS[@]} ; RET=$?
	if [ "$RET" = "0" ]; then
		echo "*********************************************************"
		printf "Error: %s -p %s %s passed, but should have failed.\n" "$FLASHROM" "$FLASHCHIP" "$PRINT_PARAM"
		echo "*********************************************************"
		return 1
	else
		printf "The previous command was expected to fail.\n"
		return 0
	fi
}

# Print the test results.
print_pass_fail() {
	local NAME=$1
	local VAL=$2

	if [ "$VAL" != "0" ] && [ "$VAL" != "00" ] && [ "$VAL" != "000" ]; then
		printf "%21s: FAILED\n" "$NAME text"
		TESTS_FAILED=1
	else
		printf "%21s: PASSED\n" "$NAME test"
	fi
}

printf "\n* Calculate ROM partition sizes & Create the layout file.\n"
export ROM_SIZE=$($FLASHROM -p "$FLASHCHIP" --get-size 2>/dev/null | grep -v coreboot)
export HALF_SIZE=$(( ROM_SIZE / 2 ))
export QUAD_SIZE=$(( ROM_SIZE / 4 ))
export ROM_TOP=$(( ROM_SIZE - 1 ))
export BOTTOM_HALF_TOP=$(( HALF_SIZE - 1 ))
export BOTTOM_QUAD_TOP=$(( QUAD_SIZE - 1 ))
export TOP_QUAD_BOTTOM=$(( QUAD_SIZE * 3 ))
{
	printf "000000:%x BOTTOM_QUAD\n" "$BOTTOM_QUAD_TOP"
	printf "000000:%x BOTTOM_HALF\n" "$BOTTOM_HALF_TOP"
	printf "%x:%x TOP_HALF\n" "$HALF_SIZE" "$ROM_TOP"
	printf "%x:%x TOP_QUAD\n" "$TOP_QUAD_BOTTOM" "$ROM_TOP"
} > $LAYOUT_FILE
cat "$LAYOUT_FILE"

printf "\n* Create a Binary with random contents\n"
dd if=/dev/urandom of=$RANDOM_FILE bs=1024 count=$((ROM_SIZE / 1024))

printf "\n* Gather system information for the logfile\n"
crossystem
flash_test_pass --version
flash_test_pass --flash-name

printf "\n* The wp-list command is not supported on all systems.\n"
printf "\n%s -p %s --wp-list\n" "$FLASHROM" "$FLASHCHIP"
$FLASHROM -p "$FLASHCHIP" --wp-list

printf "\n* See if write protect is enabled, disable it if it is.\n"
printf "\n%s -p host --wp-status\n" "$FLASHROM"
$FLASHROM -p host --wp-status | grep -q "write protect is disabled"; WP=$?
if [ "$WP" != "0" ]; then
	echo "ROM is write protected.  Attempting to disable."
	echo "$FLASHROM -p host --wp-status"
	$FLASHROM -p host --wp-disable
	$FLASHROM -p host --wp-status | grep -q "write protect is disabled"; WP=$?
	if [ "$WP" != "0" ]; then
		echo "Error: Cannot disable write protect."
		exit 1
	else
		echo "Successfully disable Write-protect"
	fi
fi

printf "\n* Read and Verify Original ROM\n"
if [ -f "$KNOWN_GOOD_ROM" ]; then
	flash_test_pass -v "$KNOWN_GOOD_ROM"
fi
flash_test_pass -r "$ORIGINAL_FILE"; READ+=$?
flash_test_pass -v "$ORIGINAL_FILE"; READ+=$?
flash_test_fail -v "$RANDOM_FILE"; READ+=$?

printf "\n* Write protect and test the top half\n"
flash_test_pass --wp-range $HALF_SIZE $HALF_SIZE --wp-enable; LOCK_TOP_HALF+=$?
flash_test_fail --ignore-fmap -l "$LAYOUT_FILE" -i TOP_HALF -w random_content.bin; LOCK_TOP_HALF+=$?
flash_test_pass -v "$ORIGINAL_FILE"; LOCK_TOP_HALF+=$?

printf "\n* Write protect and test the top quarter\n"
flash_test_pass --wp-range $TOP_QUAD_BOTTOM $QUAD_SIZE --wp-enable; LOCK_TOP_QUAD+=$?
flash_test_fail --ignore-fmap -l "$LAYOUT_FILE" -i TOP_QUAD -w random_content.bin; LOCK_TOP_QUAD+=$?
flash_test_pass -v "$ORIGINAL_FILE"; LOCK_TOP_QUAD+=$?

printf "\n* Write protect and test the bottom half\n"
flash_test_pass --wp-range 0 $HALF_SIZE --wp-enable; LOCK_BOTTOM_HALF+=$?
flash_test_fail --ignore-fmap -l "$LAYOUT_FILE" -i BOTTOM_HALF -w random_content.bin; LOCK_BOTTOM_HALF+=$?
flash_test_pass -v "$ORIGINAL_FILE"; LOCK_BOTTOM_HALF+=$?

printf "\n* Write protect and test the bottom quarter\n"
flash_test_pass --wp-range 0 $QUAD_SIZE --wp-enable; LOCK_BOTTOM_QUAD+=$?
flash_test_fail --ignore-fmap -l "$LAYOUT_FILE" -i BOTTOM_QUAD -w random_content.bin; LOCK_BOTTOM_QUAD+=$?
flash_test_pass -v "$ORIGINAL_FILE"; LOCK_BOTTOM_QUAD+=$?

printf "\n* Overwrite, test, and re-write the top quarter\n"
flash_test_pass --wp-disable; UNLOCK+=$?
flash_test_pass --wp-status
flash_test_pass -l "$LAYOUT_FILE" -i TOP_QUAD -w "$RANDOM_FILE" --fast-verify; ERASE_WRITE+=$?
flash_test_fail -v "$ORIGINAL_FILE"; ERASE_WRITE+=$?
flash_test_pass --ignore-fmap -l "$LAYOUT_FILE" -i TOP_QUAD -w "$ORIGINAL_FILE" --fast-verify
flash_test_pass -v "$ORIGINAL_FILE"

print_pass_fail "Read" "$READ"
print_pass_fail "Erase/Write" "$ERASE_WRITE"
print_pass_fail "Lock bottom quad" "$LOCK_BOTTOM_QUAD"
print_pass_fail "Lock bottom half" "$LOCK_BOTTOM_HALF"
print_pass_fail "Lock top half" "$LOCK_TOP_HALF"
print_pass_fail "Lock top quad" "$LOCK_TOP_QUAD"
print_pass_fail "Unlock:" "$UNLOCK"

exit $TESTS_FAILED
