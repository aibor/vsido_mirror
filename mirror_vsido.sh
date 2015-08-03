#!/usr/local/bin/bash
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
# Fetch iso images from the VSIDO project download page. The page should
# also have md5 files for the images.
#
# Happy image fetching!
#

set -e
set -u


TARGET_DIR='/srv/mirror.aibor.de/vsido/iso/'
PROJECT_PAGE='http://www.nixnut.com/vsido/' 

WGET_PATH=/usr/local/bin/wget
MD5SUM_PATH=/usr/bin/md5sum
MD5_PATH=/sbin/md5

# map some exit messages to a return value
declare -a MSG
MSG[1]='wget not available in PATH'
MSG[2]='checksum command not available in PATH'
MSG[3]='Unable to sync project page'
MSG[4]='checksum doesn`t match'
MSG[5]='checksum checking not available'


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


_md5_check() {
  (( $# )) || return 1
  local -a sumfile_line=($(<$1))
  local -a checksum_line=($($MD5_PATH "${sumfile_line[@]:1}"))
  [[ "${sumfile_line[0]}" == "${checksum_line[-1]}" ]] || return 2
}


# Check timestamps and load newer iso and checksum files.
_sync() {
  (( $# )) || return 1
  $WGET_PATH -A "*.iso,*.md5" -r -nd -N "$1" &> /dev/null
}


_check_checksum() {
  (( $# )) || return 1
  local checksum_file="${1}.md5"
  [[ -r "$checksum_file" ]] || return 2

  if [[ -x $MD5SUM_PATH ]]
  then
    $MD5SUM_PATH -c "${checksum_file}" &> /dev/null || return 3
  elif [[ -x $MD5_PATH ]]
  then
    _md5_check "${checksum_file}" || return 3
  else
    _warn 5
    return 0
  fi
}


cd "${TARGET_DIR}"

_sync "${PROJECT_PAGE}" || _quit 3

shopt -s nullglob
for image in *.iso
do
  _check_checksum "${image}" || _warn 4 "${image}"
done

_quit

