#!/bin/bash

function owl_version_compare () {
  local file=$1
  versionInfo=`cat $file | grep owl:versionInfo | head -n 1 | grep -oP '\d{1,6}(\.\d{1,6}){0,3}'`
  priorVersion=`cat $file | grep owl:priorVersion | head -n 1 | grep -oP '\d{1,6}(\.\d{1,6}){0,3}'`

  echo $versionInfo
  echo $priorVersion

  temp=$(dpkg --compare-versions $versionInfo "gt" $priorVersion && echo "yes" || echo "no")
  echo $temp
  if [[ $temp != "yes" ]]
  then
    echo "file $file : owl:versionInfo is not higher than owl:priorVersion!"
    exit 1
  fi
}

function owl_version_increase_test () {
  local file1=$1
  local file2=$2
  versionInfo_file1=`cat $file1 | grep owl:versionInfo | head -n 1 | grep -oP '\d{1,6}(\.\d{1,6}){0,3}'`
  versionInfo_file2=`cat $file2 | grep owl:versionInfo | head -n 1 | grep -oP '\d{1,6}(\.\d{1,6}){0,3}'`

  echo "version file 1: $versionInfo_file1"
  echo "version file 2: $versionInfo_file2"

  temp=$(dpkg --compare-versions $versionInfo_file1 "lt" $versionInfo_file2 && echo "yes" || echo "no")
  echo $temp
  if [[ $temp != "yes" ]]
  then
    echo "file $file : owl:versionInfo of $file1 is not lower than of $file2!"
    exit 1
  fi
}

function exit_if_no_file_change () {
  local file1=$1
  local file2=$2

  lines_of_cmp_result=`cmp $file1 $file2 | wc -l`
  lines_of_cmp_result=$(($lines_of_cmp_result - 1 + 1))

  if (( $lines_of_cmp_result < 1 ))
  then
    echo "There was no change in the vocabulary file, thus not checking the version increase."
    exit 0
  fi
}
