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

omni_br=android-6.0

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
  repo init -q -u https://github.com/omnirom/android -b $omni_br

  trim_darwin

  CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
  THREAD_COUNT_SYNC=$(($CPU_COUNT * 8))
  
  echo -e "\n" $CL_YLW "Syncing it up! Wait for a few minutes..." $CL_RST
  repo sync -c -q --force-sync --no-clone-bundle --optimized-fetch --prune --no-tags -j$THREAD_COUNT_SYNC

  echo -e "\n" $CL_MAG "SHALLOW Source Syncing done" $CL_RST
  
  du -sh *

  # Merge AOSP
  cd vendor/omni/utils
  rm -f aosp-merge.sh aosp-push-merge.sh
  curl -sL https://gist.github.com/rokibhasansagar/2de6065bf57c9d1027cbafbb8ce7bbf0/raw/c2036b8780a0e8e93c98bf77278ae27e5f7a20f2/aosp-merge.sh -o aosp-merge.sh
  curl -sL https://gist.github.com/rokibhasansagar/406f0fcf93671691873b12b684f047e1/raw/b6a717098d33228da109a5778b04be889e073a51/aosp-push-merge.sh -o aosp-push-merge.sh
  chmod a+x ./aosp-merge.sh ./aosp-push-merge.sh

  ./aosp-merge.sh

  # Add ssh known hosts
  ssh-keyscan -H gerrit.omnirom.org >> ~/.ssh/known_hosts || ssh-keyscan -t rsa -H gerrit.omnirom.org:29418 >> ~/.ssh/known_hosts
  ssh -o StrictHostKeyChecking=no rokibhasansagar@gerrit.omnirom.org:29418

  cd $DIR/tranSKadooSH/vendor/omni/utils
  ./aosp-push-merge.sh
}

git_auth
repo_sync_shallow
