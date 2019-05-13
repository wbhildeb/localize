#!/bin/bash

# localize 2019-05-13
# created by Walker Hildebrand

# This file is the core of the program but should not be run on its own, it is meant to be used by customized executables

# This purpose of this program is to aid with working on UWaterloo computer science
#   projects locally. After setting up a folder to contain copies of all of the
#   files on the server, you can use this program to keep your local folder and
#   your remote directory in sync.

# ------------------------------------------------------------------

readonly LCL_CMDNAME=$(basename $0)
readonly LCL_CONNECTION=${LCL_USERNAME}@${LCL_SERVER}

if [ $# == 0 ]; then
  echo "Usage: $LCL_CMDNAME command [arguments]" >&2
  echo "Example: $LCL_CMDNAME exec -o ls"
  exit -1
fi


function UTIL_getLocalPath
{
  func_name=${FUNCNAME[0]}
  usage="Internal Usage: $func_name filepath"

  if [ $# != 1 ]; then
    echo $usage >&2
    exit 1
  fi

  relative_path=${1#.}
  relative_path=${relative_path#/}

  echo ${LCL_LOCALHOME%/}/${relative_path}
}

function UTIL_getRemotePath
{
  func_name=${FUNCNAME[0]}
  usage="Internal Usage: $func_name filepath"

  if [ $# != 1 ]; then
    echo $usage >&2
    exit 1
  fi

  relative_path=${1#.}
  relative_path=${relative_path#/}

  echo ${LCL_REMOTEHOME%/}/${relative_path}
}
 

function LCL_exec
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name [option] command"

  keep_connection_open=false

  case $1 in
    --open|-o)
      keep_connection_open=true
      shift 1
      ;;
    --close|-c)
      shift 1
      ;;
    -*)
      echo \'$1\' is not a valid option. Try "-o, --open, -c or --close"
      echo $usage >&2
      exit 1
      ;;
  esac

  if [ $# -ne 0 ]; then
    args=$@ # need the temp var or all semicolons at the ends of words will be removed
    command=${args%;}\;
  fi
  
  flags="-Y"
  if [ $keep_connection_open = "true" ]; then
    flags=${flags}" -t"
    command="$command bash --login" 
  fi

  ssh $flags $LCL_CONNECTION "cd $LCL_REMOTEHOME; $command"
}


function LCL_connect
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name"

  if [ $# != 0 ]; then
    echo $usage >&2
    exit 1;
  fi

  LCL_exec -o
}


function LCL_pull
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name [filepath]\nNOTE: file path should be relative to lclhome and should start with './'"

  if [ $# -gt 1 ]; then
    for file in $@; do
      echo $file
      LCL_pull $file
    done;
    exit 0;
  fi

  if [ $# == 1 ]; then
    relative_path=${1%/};
  else
    relative_path=.
  fi

  local_path=$(UTIL_getLocalPath $relative_path)
  remote_path=$(UTIL_getRemotePath $relative_path)

  file_type=$(LCL_exec "stat --format=%F $relative_path 2>/dev/null")
  
  if [ "$file_type" == "directory" ]; then
    if [ ! -d $local_path ]; then
      mkdir -p $local_path;
    fi
    scp -r ${LCL_CONNECTION}:${remote_path%/}/* ${local_path}
  elif [ "$file_type" == "regular file" ]; then
    if [ ! -d $(dirname $local_path) ]; then
      mkdir -p $local_path;
    fi
    scp ${LCL_CONNECTION}:${remote_path} $local_path
  elif [ "$file_type" == "" ]; then
    echo "Error: file '${LCL_CONNECTION}:${remote_path}' does not exist"
    exit 1
  else
    while read file_to_pull; do
      LCL_pull $file_to_pull </dev/null
    done < <(LCL_exec "ls -1 $relative_path")
  fi
}


function LCL_push
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name [filepath]\nNOTE: file path should be relative to lclhome and should start with './'"

  if [ $# -gt 1 ]; then
    for file in $@; do
      echo $file
      LCL_push $file
    done;
    exit 0;
  fi

  if [ $# == 1 ]; then
    relative_path=${1%/};
  else
    relative_path=.
  fi

  remote_path=$(UTIL_getRemotePath $relative_path)

  cd $LCL_LOCALHOME
  file_type=$(stat -f%HT ${relative_path} 2>/dev/null)

  if [ "$file_type" == "Directory" ]; then
    if $(LCL_exec "[ ! -d $relative_path ]"); then
      LCL_exec "mkdir -p $relative_path"
    fi
    scp -r ${relative_path%/}/* ${LCL_CONNECTION}:${remote_path}
  elif [ "$file_type" == "Regular File" ]; then
    if $(LCL_exec "[ ! -d $(dirname $relative_path) ]"); then
      LCL_exec "mkdir -p $relative_path"
    fi
    scp $relative_path ${LCL_CONNECTION}:${remote_path}
  elif [ "$file_type" == "" ]; then
    echo "Error: file '$(UTIL_getRemotePath $relative_path)' does not exist"
    exit 1
  else
    while read file_to_push; do
      LCL_push $file_to_push </dev/null
    done < <(ls -1 $relative_path)
  fi
}


function LCL_diff_formatFileStruct
{
  curdir="./"
  while read line || [[ -n "$line" ]]; do
    if [[ "$line" == *: ]]; then
      curdir=${line%:}/
    elif [ "$line" ]; then
      echo ${curdir}${line}
    fi
  done
}


function LCL_diff
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name"
  
  if [ $# != 0 ]; then
    echo $usage
    exit 1;
  fi

  _remote_file_struc=$(mktemp)
  _local_file_struc=$(mktemp)
  _file_struc_diff=$(mktemp)
  _files_to_compare=$(mktemp)

  LCL_exec "ls -R" | tail -n +2 | LCL_diff_formatFileStruct | sort > $_remote_file_struc
  
  cd $LCL_LOCALHOME
  ls -R | LCL_diff_formatFileStruct | sort > $_local_file_struc

  while read line || [[ -n "$line" ]]; do
    if [[ "$line" == "> "* ]]; then
      echo "r: "${line#"> "}
    elif [[ "$line" == "< "* ]]; then
      echo "l: "${line#"< "}
    fi
  done < <(diff $_local_file_struc $_remote_file_struc) > $_file_struc_diff

  # Print the files that only in one of the location (remote=r, local=l)
  cat $_file_struc_diff

  while read cmpfile || [[ -n $cmpfile ]]; do
    if ! fgrep -q $cmpfile $_file_struc_diff && [ -f $cmpfile ] && [ -w $cmpfile ]; then
      echo $cmpfile >> $_files_to_compare
    fi
  done < $_local_file_struc

  shafilename=".filestosha"
  scp $_files_to_compare ${LCL_CONNECTION}:${LCL_REMOTEHOME}${shafilename} &>/dev/null

  while read line; do
    r_sha=$(echo $line | awk '{print $1}')
    file_to_sha=$(echo $line | awk '{print $2}')
    l_sha=$(shasum ${LCL_LOCALHOME}${file_to_sha#./} | awk '{print $1}')
    if [ "$l_sha" != "$r_sha" ]; then
      echo d: $file_to_sha
    fi
  done < <(LCL_exec "while read file; do shasum \$file; done <$shafilename;")

  LCL_exec "rm $shafilename"
  rm $_files_to_compare
  rm $_remote_file_struc
  rm $_local_file_struc
  rm $_file_struc_diff
}


function LCL_sync
{
  cd $LCL_LOCALHOME
  echo "WARNING: All actions are recursive, so if you copy/remove a folder, all contents will also be copied/removed."

  while read line; do
    diff_type=$(echo $line | awk '{print $1}')
    file=$(echo $line | awk '{print $2}')
    case $diff_type in
      r:)
        echo "$file only exists on the remote server. Enter command or enter 'h' for options."
        while read cmd </dev/tty; do 
          case $cmd in
            h|help)
              echo "h -- display this help message"
              echo "i -- ignore the difference"
              echo "r -- take remote version (copy file from remote to local)"
              echo "l -- take local verion (delete file on remote)"
              echo "$file only exists on the remote server. Enter command:"
              ;;
            i|ignore)
              echo "$file ignored"
              break
              ;;
            r|pull)
              LCL_pull $file;
              break
              ;;
            l|delete)
              LCL_exec "rm -r $file; if $?; then echo file deleted remotely; fi"
              break
              ;;
            *)
              echo "Invalid command. Enter 'h' for a list of commands"
          esac
        done
        ;;
      l:)
        echo "$file only exists locally. Enter command or enter 'h' for options."
        while read cmd </dev/tty; do 
          case $cmd in
            h|help)
              echo "h -- display this help message"
              echo "i -- ignore the difference"
              echo "r -- take remote version (delete file on local)"
              echo "l -- take local verion (copy file from local to remote)"
              echo "$file only exists locally. Enter command:"
              ;;
            i|ignore)
              echo "file ignored"
              break
              ;;
            r|delete)
              rm -r $file
              if [ $? ]; then echo "file deleted locally"; fi
              break
              ;;
            l|push)
              LCL_push $file
              break
              ;;
            *)
              echo "Invalid command. Enter 'h' for a list of commands"
          esac ;
        done
        ;;
      d:)
        echo "$file differs between local and remote. Enter command or enter 'h' for options."
        while read cmd </dev/tty; do 
          case $cmd in
            h|help)
              echo "h -- display this help message"
              echo "i -- ignore the difference"
              echo "r -- take remote version (copy from remote to local)"
              echo "l -- take local verion (copy from local to remote)"
              echo "$file differs between local and remote. Enter command:"
              ;;
            i|ignore)
              echo "file ignored"
              break
              ;;
            r|pull)
              LCL_pull $file
              break
              ;;
            l|push)
              LCL_push $file
              break
              ;;
            *)
              echo "Invalid command. Enter 'h' for a list of commands"
          esac
        done
        ;;
    esac
  done < <(LCL_diff)
  echo finished syncing!
}

function LCL_get
{
  func_name=${FUNCNAME[0]#LCL_}
  usage="Usage: $LCL_CMDNAME $func_name value\n Try using 'localhome', 'remotehome', 'user' or 'server' for the value"

  if [ $# -eq 0 ]; then
    echo "Local Home:   " $LCL_LOCALHOME
    echo "Remote Home:  " $LCL_REMOTEHOME
    echo "Username:     " $LCL_USERNAME
    echo "Server:       " $LCL_SERVER
    echo "Connection:   " $LCL_CONNECTION
    exit 0
  elif [ $# -gt 1 ]; then
    echo $usage >&2
    exit 1
  fi

  case $(echo $1 | tr '[:upper:]' '[:lower:]') in
    local_home|localhome|local|home|lhome|lh|h)
      echo $LCL_LOCALHOME
      ;;
    remote_home|remotehome|remote|rhome|rh)
      echo $LCL_REMOTEHOME
      ;;
    username|user|usr|u)
      echo $LCL_USERNAME
      ;;
    server|svr|s)
      echo $LCL_SERVER
      ;;
    connection|connect|con|c)
      echo $LCL_CONNECTION
      ;;
    *)
      echo "No variable '$1' to get" >&2
      exit 1
      ;;
  esac
}

if [[ $1 =~ ^(exec|connect|pull|push|diff|sync|get)$ ]]; then
  LCL_$1 ${@#$1}
else
  echo "Error: '$cmd_name $1' is not a valid command" >&2
fi
