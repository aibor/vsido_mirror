#!/bin/bash
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
# Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#
#
# @author: aibo ( arrrrr ) aibor ( dot ) de
#
# Fetch iso images from the VSIDO project download page and create
# torrents for all images. The page should also have md5 files for the
# images.
#
# Happy image fetching!
#

set -e
set -u


TARGET_DIR='/srv/mirror.aibor.de/vsido/iso/'
PROJECT_PAGE='http://www.nixnut.com/vsido/' 
CHECKSUM_FILE_EXTENSION='.md5'
CHECKSUM_COMMAND='md5sum -c'
MAKE_TORRENT_COMMAND="/usr/bin/btmakemetafile http://tracker.aibor.de:46969/announce \
  --announce_list http://tracker.aibor.de:46969/announce"


# map some exit messages to a return value
MSG[1]='wget not available in PATH'
MSG[2]='checksum command not available in PATH'
MSG[3]='Unable to sync project page'
MSG[4]='checksum doesn`t match'
MSG[5]='Failed to create torrent'


_warn() {
  (( $# )) || return
  if [[ -n "${MSG[$1]}" ]]
  then
    echo "${MSG[${1}]}${2+ --> ${2}}"
  fi
}


_quit() {
  (( $# )) && _warn $@
  exit ${1:-0}
}


# Check timestamps and load newer iso and checksum files.
_sync() {
  (( $# )) || return 1
  wget -A "*.iso,*${CHECKSUM_FILE_EXTENSION:-.md5}" -r -nd -N "$1" \
    &>/dev/null
}


_check_checksum() {
  (( $# )) || return 1
  local checksum_file="${1}.${CHECKSUM_FILE_EXTENSION/#./}"
  [[ -r "$checksum_file" ]] || return 2
  ${CHECKSUM_COMMAND} "${checksum_file}" &> /dev/null
}


_make_torrent() {
  (( $# )) || return 1
  local torrent=${1}.torrent
  [[ -e "${torrent}" ]] && [[ "${1}" -ot "${torrent}" ]] && return 0
  ${MAKE_TORRENT_COMMAND} "${1}"
}


which wget >/dev/null || _quit 1
which "${CHECKSUM_COMMAND%% *}" >/dev/null  || _quit 2

cd "${TARGET_DIR}"

_sync "${PROJECT_PAGE}" || _quit 3

shopt -s nullglob
for image in *.iso
do
  _check_checksum "${image}" || _warn 4 "${image}"
  _make_torrent "${image}" || _warn 5 "${image}"
done

_quit

