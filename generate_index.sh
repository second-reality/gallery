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
<h2 id="$gallery_name"><a href="#$gallery_name">$gallery_name</a>|<a href="$dl_link" style="text-decoration:none" target="_blank">↓</a>|<a href="#" style="text-decoration:none">≡</a></h2>
<div class="gallery_$repo_name">
EOF
    for photo in $(cat "$gallery_file"); do
        original=$url/orig/$photo
        view=$url/view/$photo
        mini=$url/mini/$photo
cat << EOF
    <a href="$view" data-caption="<a href=$original style=text-decoration:none target=_blank>🔍</a>"><img loading="lazy" src="$mini" height=200px/></a>
EOF
    done
# https://github.com/feimosi/baguetteBox.js
cat << EOF
</div>
<script>
    window.addEventListener('load', function() {
    baguetteBox.run('.gallery_$repo_name', {
        "fullScreen": false,
        "animation": false,
    });
});
</script>
EOF
}

generate_index()
{
cat << EOF
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/baguettebox.js/1.12.0/baguetteBox.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/baguettebox.js/1.12.0/baguetteBox.min.js" async></script>
<body style="background-color:lightgray">
$(cat header.html)
<details>
<summary>Index</summary>
EOF

    find galleries -type f | sort -r | while read g; do
        index_one_gallery "$g"
    done

cat << EOF
<hr>
</details>
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
