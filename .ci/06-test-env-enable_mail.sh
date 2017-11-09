#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
FLAVOUR="${2}"
TYPE="${3}"

# shellcheck disable=SC1090
. "${CWD}/.lib.sh"



############################################################
# Tests
############################################################

###
### 06. ENABLE_MAIL
###
if [ "${TYPE}" = "prod" ] || [ "${TYPE}" = "work" ]; then

	MOUNTPOINT="$( mktemp --directory )"

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e NEW_UID=$(id -u) -e NEW_GID=$(id -g) -e ENABLE_MAIL=1 -v ${MOUNTPOINT}:/var/mail" )"

	sleep 5

	if [ ! -f "${MOUNTPOINT}/devilbox" ]; then
		echo "Mail file does not exist: ${MOUNTPOINT}/devilbox"
		ls -lap ${MOUNTPOINT}/
		false
	fi
	if [ ! -r "${MOUNTPOINT}/devilbox" ]; then
		echo "Mail file is not readable"
		ls -lap ${MOUNTPOINT}/
		false
	fi

	docker_exec "${did}" "php -r \"mail('mailtest@devilbox.org', 'the subject', 'the message');\""
	sleep 2

	if ! run "grep 'the subject' ${MOUNTPOINT}/devilbox"; then
		"run cat ${MOUNTPOINT}/devilbox"
		false
	fi

	docker_stop "${did}"
	rm -r "${MOUNTPOINT}"

fi