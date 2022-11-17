#!/bin/bash
#
# This script uses the following environment variables
#
# TAG_PATH - The TAG_PATH variable defines a list of paths to parse for the retag script. This is
# a whitespace delimited list of path definitions. Each path definition is a colon delimited list
# consisting of <default>:<tag-file>:<path> with the following definitions:
#     <default> - 0|1  if 0, then only process this path if the retag -a option is given
#     <tag-file> - The filename to use for the output
#     <path> - The path to start a recursive tag search in
# This is all run from the ${GIT_ROOT}/${SRC_PATH_PREFIX} location. All paths should be
# relative from that directory.
#
# Ex: If you have a project with a directory structure like this:
#   $GIT_ROOT/$SRC_PATH_PREFIX/
#       project/
#           src/
#           include/
#
# Then the correponding TAG_PATH would be defined as follows:
#   export TAG_PATH="1:tags_src:project/src 0:tags_incl:project/include"
#
# Which will generate the following files:
#   $GIT_ROOT/
#       .rc/
#           tags/
#               tags_src     - This will contain all tags from the $GIT_ROOT/$SRC_PATH_PREFIX/project/src directory
#               tags_incl    - This will contain all tags from the $GIT_ROOT/$SRC_PATH_PREFIX/project/include directory
#
# GIT_ROOT - The base directory from which the source code is located
#
# SRC_PATH_PREFIX - The base path to the primary source code location within GIT_ROOT
#
# TAGDIR - The directory location where to store the info

Usage="Usage: rebuild_ctags [<options>]

 Options:
   -a                 Build all ctag directories
   -p                 Pretend - shows what commands would have been executed
   --tagfile <file>   Build only the tagfile specified from the TAG_PATH definition
   --dir <dir>        Put the tag files in specified directory"

s_opts=apt:h
l_opts=dir:,tagfile:,help,pretend

all=0
tagfile=
pretend=0
prog=`basename $0`
dir=${HOME}

if [ $GIT_ROOT ]; then
	rootdir=${GIT_ROOT}
else
	rootdir=./
fi

if [ $SRC_PATH_PREFIX -a -d $rootdir/$SRC_PATH_PREFIX ]; then
	src_path=${SRC_PATH_PREFIX}
else
	src_path=""
	echo ""
	echo "SRC_PATH_PREFIX not defined or does not exist. Overriding and using current directory"
	TAG_PATH=""
fi

ctags_bin=ctags
if [[ "$($ctags_bin --version)" =~ "Universal Ctags" ]]; then
	universal_ctags=1
else
	universal_ctags=0
fi

EXEC=

if [ "${TAGDIR}" != "" ]; then
	dir=${TAGDIR}
fi

create_ctags()
{
	filename=$1
	path=$2

	if [ $universal_ctags -eq 1 ]; then
		ctags_cmd="$ctags_bin --tag-relative=always --recurse -f $dir/$filename --links=no --extras=+F --format=2 --excmd=pattern --fields=nksSar --sort=no --append=no *"
	else
		ctags_cmd="$ctags_bin --tag-relative --recurse -f $dir/$filename --links=no --extra= --file-scope=yes --format=2 --excmd=pattern --fields=nksSar --sort=no --append=no *"
	fi
	#ctags_cmd="/usr/bin/ctags --tag-relative --recurse -extra=f -f $filename --links=no *"

	echo -n "  $path -> $filename ..."
	
	if [ -d $rootdir/$src_path/$path ]; then
		$EXEC cd $rootdir/$src_path/$path
		cd $rootdir/$src_path/$path
		$EXEC $ctags_cmd 2>&1
		echo " done"
	else
		echo "Path not found:$rootdir/$src_path/$path"
	fi
}

print_tagpath()
{
	echo "  TAGDIR: ${TAGDIR}"
	if [[ "$TAG_PATH" != "" ]]; then
		echo "  TAG_PATH:"
		echo "    Def TagFile         Path:"
		echo "$(echo $TAG_PATH | tr ' ' '\n' | tr ':' '\t' | sed -e 's/^\([01]\)/    \1/')"
		echo ""
	else
		echo "  TAG_PATH: not defined."
	fi
}

optarg=0
opts=`getopt -n $prog -o $s_opts -ual $l_opts -- $@`
if [ $? != 0 ]; then
	echo ""
	echo "$Usage"
	echo ""
	exit 2
fi

eval set -- "$opts"

while [ $1 != -- ]; do

	case "$1" in
		-a)
			all=1
			;;

		-t | --tagfile)
			tag_file=$2
			shift
			;;

		-p | --pretend)
			pretend=1
			EXEC=/bin/echo
			;;

		--dir)
			dir=$2
			shift
			;;

		--) ;; # ignore

		* | --help) echo ""
		   echo "$Usage"
		   echo ""
		   print_tagpath
		   exit 1;;
	esac

	shift
done

if [ ! -d $dir ]; then
	echo "Directory $dir does not exist. Creating it."
	$EXEC mkdir -p $dir
fi

echo ""
if [ $universal_ctags -eq 1 ]; then
	echo "Using Universal CTAGS"
else
	echo "Using Exuberant CTAGS"
fi

print_tagpath
echo "Rebuilding ctag definitions..."

echo ""
if [[ "$TAG_PATH" != "" ]]; then
	for path in $TAG_PATH; do
		default=$(echo $path | cut -d ":" -f 1)
		filename=$(echo $path | cut -d ":" -f 2)
		directory=$(echo $path | cut -d ":" -f 3)
		if [ "$tag_file" != "" -a "$tag_file" != $filename ]; then
			continue
		fi
		if [ $all -eq 1 -o $default -eq 1 ]; then
			create_ctags $filename $directory
		fi
	done
	# Now look for any extraneous files
	files=$(ls $TAGDIR)
	rm_files=""
	for file in $files; do
		if [[ ! "${TAG_PATH}" =~ "${file}" ]]; then
			echo "  Extraneous file found [$file]"
			rm_files+=" $file"
		fi
	done
	if [[ "$rm_files" != "" ]]; then
		echo ""
		echo "Possible extraneous files found that are not part of the TAG_PATH definition."
		echo "This is possibly due to leftover files from an out-dated version of this script,"
		echo "or if your TAG_PATH environment variables have changed."
		echo ""
		echo "To remove, use the following command:"
		echo "  cd $TAGDIR && rm$rm_files"
	fi
else
	create_ctags ctags ./
fi


echo ""
echo "Done creating ctag definitions."
echo ""

exit 0
