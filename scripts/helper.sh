#!/bin/bash

function version_compare () { # made by https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash?page=2&tab=scoredesc#tab-top
  function sub_ver () {
    local len=${#1}
    temp=${1%%"."*} && indexOf=`echo ${1%%"."*} | echo ${#temp}`
    echo -e "${1:0:indexOf}"
  }
  function cut_dot () {
    local offset=${#1}
    local length=${#2}
    echo -e "${2:((++offset)):length}"
  }
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "=" && exit 0
  fi
  local v1=`echo -e "${1}" | tr -d '[[:space:]]'`
  local v2=`echo -e "${2}" | tr -d '[[:space:]]'`
  local v1_sub=`sub_ver $v1`
  local v2_sub=`sub_ver $v2`
  if (( v1_sub > v2_sub )); then
    echo ">"
  elif (( v1_sub < v2_sub )); then
    echo "<"
  else
    version_compare `cut_dot $v1_sub $v1` `cut_dot $v2_sub $v2`
  fi
}

function owl_version_compare () {
  local file=$1
  versionInfo=`cat $file | grep owl:versionInfo | head -n 1 | grep -oP '[\.\d{1,6}]*'`
  priorVersion=`cat $file | grep owl:priorVersion | head -n 1 | grep -oP '[\.\d{1,6}]*'`

  echo $versionInfo
  echo $priorVersion

  temp=$(version_compare $versionInfo $priorVersion)
  echo $temp
  if [[ $temp != ">" ]]
  then
    echo "file $file : owl:versionInfo is not higher than owl:priorVersion!"
    exit 1
  fi
}

function owl_version_increase_test () {
  local file1=$1
  local file2=$2
  versionInfo_file1=`cat $file1 | grep owl:versionInfo | head -n 1 | grep -oP '[\.\d{1,6}]*'`
  versionInfo_file2=`cat $file2 | grep owl:versionInfo | head -n 1 | grep -oP '[\.\d{1,6}]*'`

  echo $versionInfo_file1
  echo $versionInfo_file2

  temp=$(version_compare $versionInfo_file1 $versionInfo_file2)
  echo $temp
  if [[ $temp != "<" ]]
  then
    echo "file $file : owl:versionInfo of $file2 was not increased, i.e. it need to be higher than the version of $file1!"
    exit 1
  fi
}

function exit_if_no_file_change () {
  local file1=$1
  local file2=$2

  echo "Calculating line count difference ..."
  if cmp "$file1" "$file2"
  then
    echo "There is no change in the vocabulary file, thus not checking the version increase."
    exit 0
  fi
  echo "Done with exit_if_no_file_change"
}
