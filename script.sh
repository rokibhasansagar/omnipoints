#!/bin/bash

# Colors
CL_XOS="\033[34;1m"
CL_PFX="\033[33m"
CL_INS="\033[36m"
CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"

DIR=$(pwd)

mkdir tranSKadooSH
cd tranSKadooSH

datetime=$(date +%Y%m%d)

google_cookies() {
  echo -en "\n" $CL_INS "Setup Google Cookies for Smooth googlesource Cloning" $CL_RST
  git clone -q "https://$GITHUB_TOKEN@github.com/rokibhasansagar/google-git-cookies.git" &> /dev/null
  if [ -e google-git-cookies ]; then
    bash google-git-cookies/setup_cookies.sh
    rm -rf google-git-cookies
  fi
}

git_auth() {
  echo -e "\n" $CL_INS "Github Authorization Setting Up" $CL_RST
  git config --global user.email $GitHubMail
  git config --global user.name $GitHubName
  git config --global color.ui true

  google_cookies
}

trim_darwin() {
  echo -e "\n" $CL_PFX "Removing Unimportant Darwin-specific Files from syncing" $CL_RST
  cd .repo/manifests
  sed -i '/darwin/d' default.xml
  ( find . -type f -name '*.xml' | xargs sed -i '/darwin/d' ) || true
  git commit -a -m "Magic" || true
  cd ../
  sed -i '/darwin/d' manifest.xml
  cd ../
}

repo_sync_shallow() {
  echo -e "\n\n" $CL_GRN "Initialize repo Command" $CL_RST
  repo init -q -u https://github.com/omnirom/android -b android-6.0

  trim_darwin

  CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
  THREAD_COUNT_SYNC=$(($CPU_COUNT * 8))
  
  echo -e "\n" $CL_YLW "Syncing it up! Wait for a few minutes..." $CL_RST
  repo sync -c -q --force-sync --no-clone-bundle --optimized-fetch --prune --no-tags -j$THREAD_COUNT_SYNC

  echo -e "\n" $CL_MAG "SHALLOW Source Syncing done" $CL_RST
  
  # Merge AOSP
  cd vendor/omni/utils
  curl -sL https://gist.github.com/rokibhasansagar/2de6065bf57c9d1027cbafbb8ce7bbf0/raw/4c12450d6f145111137f630d387c87c4c0e7d658/upstream.sh -o upstream.sh
  chmod a+x ./upstream.sh
  ./upstream.sh
