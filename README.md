vsido_mirror
============

This script fetches .md5 files from the vsido sourceforge files page and checks if an identical file is present. If not it fetches the according .iso image and creates a torrent metafile for it. Aftwerwards it changes the owner and moves all files into a directoy which is served by a webserver, rsync and a torrent tracker.

It is intended to be run regularly (eg. by a cronjob).
