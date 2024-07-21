#!/usr/bin/env bash

set -euo pipefail

die()
{
    echo "$@" 1>&2
    exit 1
}

list_photos()
{
    folder="$1"
    pushd "$folder" > /dev/null
    find . | grep -i '\.jpg$' | sed -e 's#^\./##' | sort
    popd > /dev/null
}

set_git_config()
{
    git config user.email 'mail'
    git config user.name 'name'
    # prevent git from trying to compress files on push
    git config core.compression -1
}

convert_all_photos()
{
    for photo in $(find . | grep -i '\.jpg$'); do
        dirname=$(dirname "$photo")
        mkdir -p "orig/$dirname"
        mkdir -p "view/$dirname"
        mkdir -p "mini/$dirname"
        original=orig/$photo
        mv "$photo" "$original"
        view=view/$photo
        mini=mini/$photo
        echo "convert -resize 2000x2000 -quality 90% $original $view"
        echo "convert -resize 400x400 -quality 90% $original $mini"
    done | parallel -j "$(nproc)" --bar

    size=$(du -s . | cut -f 1)
    limit=2000000 # Github single push limit is 2GB
    if [ $size -gt $limit ]; then
        echo "GitHub single push limit reached, delete original files"
        rm -rf orig
        size=$(du -s . | cut -f 1)
        if [ $size -gt $limit ]; then
            die "size of view only pics is bigger than GitHub limit"
        fi
        cp -r view orig # duplicate view as original files
        # git will deduplicate files
    fi
}

check_auth()
{
    [ -f GIT_USER ] || die "file GIT_USER missing"
    git_user=$(cat GIT_USER)
    gh auth status || die "need to authenticate using 'gh auth login' first"
    auth_user=$(gh auth status |& grep "Logged in to github.com" | sed -e 's/.*github.com as //' -e 's/ (.*//')
    [ "$auth_user" == "$git_user" ] || die "auth user $auth_user different from expected $git_user"
}

main()
{
    [ $# -eq 2 ] || die "usage: folder gallery_name"

    folder="$1"; shift
    gallery_name="$1";shift
    repo_name=$(echo "$gallery_name" | sha1sum | head -c 10)

    check_auth

    tmp=$(mktemp -d)
    trap "rm -rf $tmp" EXIT

    cp -r "$folder" "$tmp/repo"
    pushd "$tmp/repo"

    find . -type f | (grep -vi '\.jpg' || true) | while read extra_file; do
        echo "delete extra file: $extra_file"
        rm "$extra_file"
    done
    convert_all_photos
    git init
    set_git_config
    git add .
    git commit -a -m 'init'
    du -sh orig
    du -sh view
    du -sh mini
    echo "push new repo \"$repo_name\" for gallery \"$gallery_name\""
    gh repo create "$repo_name" --public --push --source ./
    popd

    set_git_config
    mkdir -p galleries
    list_photos "$folder" > galleries/"$gallery_name"
    git add .
    git commit -m "$gallery_name"
}

main "$@"
