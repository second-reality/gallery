#!/usr/bin/env bash

set -euo pipefail

die()
{
    echo "$@" 1>&2
    exit 1
}

[ -f GIT_USER ] || die "file GIT_USER missing"
git_user=$(cat GIT_USER)

[ -f header.html ] || die "file header.html missing"
[ -f footer.html ] || die "file footer.html missing"

base_raw_url="https://raw.githubusercontent.com/$git_user"
base_repo_url="https://github.com/$git_user"

index_one_gallery()
{
    gallery_file="$1"
    gallery_name=$(basename "$gallery_file")
cat << EOF
<a href="#$gallery_name">$gallery_name</a><br>
EOF
}

one_gallery()
{
    gallery_file="$1"
    gallery_name=$(basename "$gallery_file")
    repo_name=$(echo "$gallery_name" | sha1sum | head -c 10)
    url="$base_raw_url/$repo_name/master"
    dl_link="https://downgit.github.io/#/home?url=$base_repo_url/$repo_name/tree/master/orig"
cat << EOF
    <h2 id="$gallery_name"><a href="#$gallery_name">$gallery_name</a> <a href="$dl_link">💾</a></h2>
    <div id="nanogallery2-$repo_name" data-nanogallery2 = '{
         "thumbnailWidth": "auto",
         "thumbnailHeight": 300,
         "galleryDisplayTransition": "none",
         "thumbnailDisplayTransition": "none",
         "imageTransition": "slideAppear",
         "viewerGallery": "none",
         "viewerFullscreen": true,
         "viewerTools":     {
            "topLeft":    "playPauseButton",
            "topRight":   "fullscreenButton, downloadButton, closeButton"
         }
    }' >
EOF
    for photo in $(cat "$gallery_file"); do
        original=$url/orig/$photo
        view=$url/view/$photo
        mini=$url/mini/$photo
cat << EOF
    <a href="$view" data-ngthumb="$mini" data-ngdownloadurl="$original"></a>
EOF
    done
cat << EOF
    </div>
EOF
}

generate_index()
{
    cdn="https://unpkg.com/nanogallery2@3.0.5/dist/"
cat << EOF
<!-- jQuery -->
<script  type="text/javascript"  src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>

<!-- nanogallery2 -->
<link    href="$cdn/css/nanogallery2.min.css" rel="stylesheet" type="text/css">
<script  type="text/javascript" src="$cdn/jquery.nanogallery2.min.js"></script>
<body style="background-color:lightgray">
$(cat header.html)
EOF

    find galleries -type f | sort -r | while read g; do
        index_one_gallery "$g"
    done

cat << EOF
<hr>
EOF

    find galleries -type f | sort -r | while read g; do
        one_gallery "$g"
    done
cat << EOF
$(cat footer.html)
</body>
EOF
}

generate_index > index.html
