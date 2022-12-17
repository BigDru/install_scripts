#!/bin/bash

nvim_repo_location=${path_to_repos}nvim

has_dnf_query=`command -v dnf`
if [[ -z $has_dnf_query ]]; then
    has_dnf=0
else
    has_dnf=1
fi

# install dependencies
# command -v is a POSIX command that is also a Bash builtin
echo Upgrading and installing dependencies
if [[ has_dnf -eq 1 ]]; then
    echo
else
    apt-get install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
fi

echo
need_to_clone=0

if [[ ! -d $nvim_repo_location ]]; then
    echo Nvim repo folder not found at expected location: $nvim_repo_location
    echo
    need_to_clone=1
else
    check_nvim_repo=`git -C ${nvim_repo_location} rev-parse 2>/dev/null; echo $?`

    if [[ check_nvim_repo -ne 0 ]]; then
        echo "Found folder ${nvim_repo_location}, but it's not a git repo"
        echo
        need_to_clone=1
    fi
fi

if [[ $need_to_clone -eq 1 ]]; then
    echo Cloning nvim repo
    echo
	git clone https://github.com/neovim/neovim $nvim_repo_location
    echo
else
    echo nvim repo found at: $nvim_repo_location
    echo
fi

echo pushd:
pushd $nvim_repo_location
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
    if [[ $((${versions[2]})) -gt patch ]]; then
        patch=$((${versions[2]}))
    fi
done

echo Patch: $patch
echo

# Check if we have nvim installed
need_to_install=0
command -v nvim &> /dev/null
if [[ $? -eq 1 ]]; then
    echo nvim Not found. 
    need_to_install=1
else
    echo nvim found
    version_check=`nvim --version | sed -n 1p`
    # excludes the v in v0.8.1
    local_version=${version_check:6}

    current_versions=(${local_version//./ })
    current_major=$((current_versions[0]))
    current_minor=$((current_versions[1]))
    current_patch=$((current_versions[2]))

    if [[ $major -eq $current_major && $minor -eq $current_minor && $patch -eq $current_patch ]]; then
        echo Already at latest version
        echo
        echo popd:
        popd
        exit 0
    else
        need_to_install=1
    fi
fi

if [[ need_to_install -eq 1 ]]; then
    echo
    echo Installing
    git checkout tags/v${major}.${minor}.${patch}
    git submodule update --init --recursive
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    make install

    echo
    nvim --version
fi

#
#
#echo Currently installed version is old. Beginning update..
#echo
#git checkout tags/v${major}.${minor}.${patch}
#echo
#
#make prefix=/usr all doc info
#make prefix=/usr install install-doc install-html install-info
#
#echo
#
#echo popd:
#popd
#
#echo Done updating!
#git --version
