#!/bin/bash

path_to_repos="/root/repos/"
git_repo_location=${path_to_repos}git

# Check if we have git installed
# command -v is a POSIX command that is also a Bash builtin
if ! command -v git &> /dev/null; then
    echo Installing git from distro package list
    apt update
    apt install git -y
fi

echo

# get local git version
local_git_version=`git --version`
local_git_version=${local_git_version:12}
echo Current installed git version: $local_git_version
echo

# Check for repo and clone if needed
need_to_clone=0

if [[ ! -d $git_repo_location ]]; then
    echo Git repo folder not found at expected location: $git_repo_location
    echo
    need_to_clone=1
else
    check_git_repo=`git -C ${git_repo_location} rev-parse 2>/dev/null; echo $?`

    if [[ check_git_repo -ne 0 ]]; then
        echo "Found folder ${git_repo_location}, but it's not a git repo"
        echo
        need_to_clone=1
    fi
fi

if [[ $need_to_clone -eq 1 ]]; then
    echo Cloning git repo
    echo
    git clone https://github.com/git/git.git $git_repo_location
    echo
else
    echo Git repo found at: $git_repo_location
    echo
fi

echo pushd:
pushd $git_repo_location
echo

# fetch if we didn't clone
if [[ $need_to_clone -ne 1 ]]; then
    echo Pulling latest
    echo
    git pull
    echo
fi

echo Finding latest released tag:

# find major
tags=`git tag -l "v*"`
major=0
for tag in ${tags[@]}; do
    # skip release candidates (contain dash '-' character)
    if [[ $tag == *"-"* ]]; then
        continue
    fi

    tag=${tag:1}
    versions=(${tag//./ })
    if [[ $((${versions[0]})) -gt major ]]; then
        major=$((${versions[0]}))
    fi
done

echo Major: $major

# find minor
tags=`git tag -l "v${major}.*"`
minor=0
for tag in ${tags[@]}; do
    # skip release candidates (contain dash '-' character)
    if [[ $tag == *"-"* ]]; then
        continue
    fi

    versions=(${tag//./ })
    if [[ $((${versions[1]})) -gt minor ]]; then
        minor=$((${versions[1]}))
    fi
done

echo Minor: $minor

# find patch
tags=`git tag -l "v${major}.${minor}.*"`
patch=0
for tag in ${tags[@]}; do
    # skip release candidates (contain dash '-' character)
    if [[ $tag == *"-"* ]]; then
        continue
    fi

    versions=(${tag//./ })
    if [[ $((${versions[2]})) -gt minor ]]; then
        patch=$((${versions[2]}))
    fi
done

echo Patch: $patch
echo

current_versions=(${local_git_version//./ })
current_major=$((current_versions[0]))
current_minor=$((current_versions[1]))
current_patch=$((current_versions[2]))

if [[ $major -gt $current_major || $minor -gt $current_minor || $patch -gt $current_patch ]]; then
    echo Currently installed version is old. Beginning update..
    echo
fi

echo popd:
popd
