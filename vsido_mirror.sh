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
# Fetch iso images from a sourceforge page and create torrent for it.
# The sourceforge page should also have md5 files for the images, otherwise you need to cut this stuff
# from the script.
#
# Happy image fetching!

TARGET_DIR='/srv/mirror.aibor.de:80/vsido/iso/'
TARGET_USER='www-data'
TARGET_GROUP='www-data'
PROJECT_PAGE='http://sourceforge.net/projects/vsido/files/' 
DOWNLOAD_URL='http://downloads.sourceforge.net/project/vsido/'
CHECKSUM_FILE_EXTENSION='.md5'
CHECKSUM_COMMAND='/usr/bin/md5sum -c'
MAKE_TORRENT_COMMAND="/usr/bin/btmakemetafile http://tracker.aibor.de:46969/announce \
    --announce_list http://tracker.aibor.de:46969/announce|http://bttracker.crunchbanglinux.org:6969/announce"

trap "{ quit 7; }" TERM INT KILL

# make temporary working dir
WORKING_DIR="$(/bin/mktemp -d)"

# map some exit messages to a return value
EXIT[1]='Unable to fetch project page'
EXIT[2]='No iso found'
EXIT[3]='Failed to fetch file'
EXIT[4]='Something went wrong, file isn`t here'
EXIT[5]='checksum doesn`t match'
EXIT[6]='Failed to create torrent'
EXIT[7]='Aborting.'
EXIT[8]='Failed to move files'

# graceful quitting function
quit() {
  [ -z "${EXIT[$1]}" ] || /bin/echo "${EXIT[${1}]}${2:+ --> ${2}} " 
  /bin/rm -r "${WORKING_DIR}"
  exit ${1}
}

fetch() {
  # fetch the passed file
  /usr/bin/wget -q "${1}" > /dev/null || quit 3 "${1##*/}"

  # check if download of the file succeeded
  [ -r "${1##*/}" ] || return 1
  return 0
}

# enter working dir
cd "${WORKING_DIR}"

# fetch project page
page=$(/usr/bin/curl "${PROJECT_PAGE}" 2>/dev/null) || quit 1

# parse project page for iso image urls
iso_files="$(/bin/egrep -io 'http[^ ]*\.iso' <<< "${page}" | /usr/bin/uniq )"

# quit if no isos have been found
[ -z "${iso_files}" ] && quit 2

# loop through every found iso image
for i in ${iso_files}
do
  # parse filename from urls and fill helpful variables
  image="${i##*/}"
  checksum_file="${image/%/${CHECKSUM_FILE_EXTENSION}}"

  # fetch checksum files for the images
  fetch "${DOWNLOAD_URL}${checksum_file}" || quit 4 "${checksum_file}"

  # delete checksum file and continue with next image, if the md5 is present and identical in target directory
  if /usr/bin/diff -N {./,"${TARGET_DIR}"}"${checksum_file}" >/dev/null 
  then
    rm -f "${checksum_file}"
    continue
  fi

  /bin/echo "Fetching and processing '${image}'"
  /bin/echo 'This may take some time.'

  # fetch the image 
  fetch "${DOWNLOAD_URL}${image}" || quit 4 "${image}"

  # check checksum of image
  ${CHECKSUM_COMMAND} "${checksum_file}" > /dev/null || quit 5 "${image}"

  # create torrent file for the freshly downloaded image
  ${MAKE_TORRENT_COMMAND} "${image}" > /dev/null || quit 6

  # check if torrent file is present
  [ -r "${image/%/.torrent}" ] || quit 4 "${image/%/.torrent}" 

  # change owner of all files and move them to the target dir
  /bin/chown "${TARGET_USER}":"${TARGET_USER}" "${image}"*
  /bin/mv "${image}"* "${TARGET_DIR}" || quit 8 "'${image}' to '${TARGET_DIR}'"

  # give response
  /bin/echo "downloaded '${image}', created torrent and moved all into '${TARGET_DIR}'"
done

quit
