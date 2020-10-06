#!/bin/bash

# original based on: https://gist.github.com/imkarthikk/2fe9053f0aef275f5527
# Run it from the root of your Jekyll site

##
# Configuration options
##
STAGING_BUCKET='s3://<YOUR-S3-BUCKET-NAME>'
LIVE_BUCKET='s3://taooffoo.com'
SITE_DIR='_site/'

##
# Usage
##
usage() {
cat << _EOF_
Usage: ${0} [staging | live]
    
    staging		Deploy to the staging bucket
    live		Deploy to the live (www) bucket
_EOF_
}
 
##
# Color stuff
##
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2; tput bold)
YELLOW=$(tput setaf 3)

function red() {
    echo "$RED$*$NORMAL"
}

function green() {
    echo "$GREEN$*$NORMAL"
}

function yellow() {
    echo "$YELLOW$*$NORMAL"
}

##
# Actual script
##

# Expecting at least 1 parameter
if [[ "$#" -ne "1" ]]; then
    echo "Expected 1 argument, got $#" >&2
    usage
    exit 2
fi

if [[ "$1" = "live" ]]; then
	BUCKET=$LIVE_BUCKET
	green 'Deploying to live bucket'
else
	BUCKET=$STAGING_BUCKET
	green 'Deploying to staging bucket'
    exit 2
fi


red '--> Running Jekyll'
bundle exec jekyll build


#red '--> Gzipping all html, css and js files'
#find $SITE_DIR \( -iname '*.html' -o -iname '*.css' -o -iname '*.js' \) -exec gzip -9 -n {} \; -exec mv {}.gz {} \;
#find $SITE_DIR \( -iname '*.html' -o -iname '*.css' -o -iname '*.js' \) -exec gzip -9 {} \; -exec mv {}.gz {} \;


yellow '--> Uploading css files'
#s3cmd sync --exclude '*.*' --include '*.css' --add-header='Content-Type: text/css' --add-header='Cache-Control: max-age=604800' $SITE_DIR $BUCKET
s3cmd sync --exclude '*.*' --include '*.css' --add-header='Content-Type: text/css' --add-header='Cache-Control: max-age=604800' $SITE_DIR $BUCKET
yellow '--> Uploading map files'
s3cmd sync --exclude '*.*' --include '*.map' --add-header='Cache-Control: max-age=604800' $SITE_DIR $BUCKET
# --add-header='Content-Type: text/css'


yellow '--> Uploading js files'
#s3cmd sync --exclude '*.*' --include '*.js' --add-header='Content-Type: application/javascript' --add-header='Cache-Control: max-age=604800' $SITE_DIR $BUCKET
s3cmd sync --exclude '*.*' --include '*.js' --add-header='Content-Type: application/javascript' --add-header='Cache-Control: max-age=604800' $SITE_DIR $BUCKET
# --add-header='Content-Type: application/javascript' 

# Sync media files first (Cache: expire in 10weeks)
yellow '--> Uploading images (jpg, png, ico, gif)'
#s3cmd sync --exclude '*.*' --include '*.png' --include '*.jpg' --include '*.ico' --include '*.gif' --add-header='Expires: Sat, 20 Nov 2020 18:46:39 GMT' --add-header='Cache-Control: max-age=6048000' $SITE_DIR $BUCKET
s3cmd sync --exclude '*.*' --include '*.png' --include '*.jpg' --include '*.ico' --include '*.gif' --add-header='Cache-Control: max-age=6048000' $SITE_DIR $BUCKET


# Sync html files (Cache: 2 hours)
yellow '--> Uploading html files'
#s3cmd sync --exclude '*.*' --include '*.html' --add-header='Content-Type: text/html' --add-header='Cache-Control: max-age=7200, must-revalidate' $SITE_DIR $BUCKET
s3cmd sync --exclude '*.*' --include '*.html' --add-header='Content-Type: text/html' --add-header='Cache-Control: max-age=7200, must-revalidate' $SITE_DIR $BUCKET
# --add-header='Content-Type: text/html'

# Sync html files (Cache: 2 hours)
yellow '--> Uploading xml files'
s3cmd sync --exclude '*.*' --include '*.xml'  --add-header='Content-Type: application/xml' --add-header='Cache-Control: max-age=7200, must-revalidate' $SITE_DIR $BUCKET

# Until sccmd 2.2.0 comes out we have to fix it manually: https://github.com/s3tools/s3cmd/issues/643
red '--> Modifying Content-Type headers manually because s3cmd 2.1.0 is dumb'
cd $SITE_DIR;
for f in $(find . -name '*.css' -or -name '*.map'); do s3cmd modify --add-header='Content-Type: text/css' $BUCKET/${f:2} ; done
for f in $(find . -name '*.js'); do s3cmd modify --add-header='Content-Type: application/javascript' $BUCKET/${f:2} ; done
for f in $(find . -name '*.html'); do s3cmd modify --add-header='Content-Type: text/html' $BUCKET/${f:2} ; done
for f in $(find . -name '*.xml'); do s3cmd modify --add-header='Content-Type: application/xml' $BUCKET/${f:2} ; done
s3cmd modify --add-header='Content-Type: application/atom+xml' $BUCKET/feed.xml


# Sync everything else
#yellow '--> Syncing everything else'
#s3cmd sync --delete-removed $SITE_DIR $BUCKET
