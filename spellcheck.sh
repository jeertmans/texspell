#! /bin/bash

#############
# Constants #
#############

# Colors
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

DIFF_EXT=".diff" # Might be changed or choosed by user later... ?
TEX_EXT=".tex"


DOC="
\ttexspell -- Command line spell-checker tool for TeX documents\n
\n
Options:\n
-h, --help: get this help\n
-a, --all: Clean/Check also hidden files and hidden directories\n
-c, --clean: Remove all .diff in the . directiory and sub-directories\n
-o, --clean-only: Do not generate the ${DIFF_EXT}\n
--no-report: Do not produce a report\n
-v, --version: get version number\n
\n"

##################
# Default values #
##################

ignore="colors.tex" # Good for testing but should be removed :)
CLEAN=0 #Remove or not diff files
SPELL=1 #Create or not diff files
VERBOSE=1 # Level of verbosity
REPORT=1 # Produce a report or not
CHECK_HIDDEN=0 #Check or not (spell/clean) files in hidden dir/files
SRC="." # SRC to check
SRCISFILE=0 # Is SRC a file
TEMP_DIR=""
REPORT_FILE="report_texspell"

#################
# Flags handler #
#################
while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo -e $DOC
      exit 0
      ;;
    -v|--version)
      echo "Version: 0.1"
      shift
      ;;
    -c|--clean)
      CLEAN=1
      shift
      ;;
    -o|--clean-only)
      CLEAN=1
      SPELL=0
      shift
      ;;
    --no-report)
      REPORT=0
      shift
      ;;
    -a|--all)
      CHECK_HIDDEN=1 
      shift
      ;;
    *)
      if [ -f "$1" ]; then
        SRCISFILE=1
        SRC=$1
        shift
      elif [ -d $1 ]; then
        SRCISFILE=0
        SRC=$1
        shift
      else
      echo "Last argument should be either a file or a directoy: "${1}
      exit 1
      fi
      ;;
  esac
done

#########################
# Function declarations #
#########################

# Find files
# 1 - Source file or directory
# 2 - Extention of file, ex.: ".tex", ".diff"
# 3 - Binary variable (0 or 1) to say if hidden files must be included
# + - All other files or pattern (non case-sensitive) that must be excluded
#
# R - All the files matching conditons
function find_files {
  local SRC=$1
  local EXT=$2
  local HID=$3
  local IGN=""
  while test $# -gt 3; do
    IGN="${IGN} ! -iname $4"
    shift
  done
  if [ $HID -eq 1 ]; then
    echo $(find $SRC -type f -iname "*${EXT}" $IGN)
  else
    echo $(find $SRC -type f -iname "*${EXT}" $IGN -not -path "*/\.*")
  fi
}

# Remove files
# 1 - List of files
#
# R - Nothing
function remove_files {
  local FILES=$1
  xargs -n 1 -r rm $FILES
}

# Remove colors from input
# https://stackoverflow.com/questions/17998978/removing-colors-from-output
# 1 - Input
#
# R - The input with colors removed
function remove_colors {
  local IN=$1
  $(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" $IN)
}

# Substitute regex pattern
# 1 - Input
# 2 - Search pattern, ex.: "([a-zA-Z])"
# 3 - Sub. pattern, ex.: "_\1_" to add "_" around matching patterns
#
# R - The input with substituted patterns
function regex_sub {
  local STR=$1
  local PAT=$2
  local SUB=$3
  echo $(sed -E "s/${PAT}/${SUB}/g" $STR)
}

# Substitute regex pattern in file (in-place)
# 1 - Input
# 2 - Search pattern, ex.: "([a-zA-Z])"
# 3 - Sub. pattern, ex.: "_\1_" to add "_" around matching patterns
#
# R - Nothing
function regex_sub_file {
  local FILE=$1
  local PAT=$2
  local SUB=$3
  sed -i -E "s/${PAT}/${SUB}/g" $FILE
}

####################
# Script execution #
####################

# Cleaning .diff files
if [ $CLEAN -eq 1 ]; then
  if [ $SRCISFILE -eq 1 ]; then
    if [ -f "${SRC}${DIFF_EXT}" ]; then
      rm "${SRC}${DIFF_EXT}"
    fi
  else
    find_files $SRC $DIFF_EXT $CHECK_HIDDEN | remove_files 
  fi
fi


# Typechecking
if [ $SPELL -eq 1 ]; then
  # Generate diff files
  
  FILES=0
  EMPTY_FILES=0
  ERRORS=0
  UNKNOWN_WORDS=0
  if [ $REPORT -eq 1 ]; then 
    rm $REPORT_FILE
    touch $REPORT_FILE
    echo "Start " $(date) > $REPORT_FILE 
    echo "" >> $REPORT_FILE
  fi
  
  echo "Processing files..."
  
  FILES_LIST=()

  mapfile -d $'\0' FILES_LIST < <(find_files $SRC $TEX_EXT $CHECK_HIDDEN $ignore)

  for FILE in ${FILES_LIST[@]}; do
    if [ $VERBOSE -ge 1 ]; then
      echo $file
    fi

    FILENAME=$(basename $FILE)
    TMP_FILE_1=$(mktemp -p "${TEMP_DIR}" "${FILENAME}1_${date}_XXXXX.tmp")
    TMP_FILE_2=$(mktemp -p "${TEMP_DIR}" "${FILENAME}2_${date}_XXXXX.tmp")

    hunspell -a -t -i utf-8 -d en_US <$FILE | grep -v '[\*]' > $TMP_FILE_1
    # Whe need to clean the first line of the file containing a header from Ispell
    sed -i '1d' $TMP_FILE_1
    sed -i '/^$/N;/^\n$/D' $TMP_FILE_1
    # Reformat spelling suggestion with colors:
    # L{lineno}: {error} => ({# of sugg.}) {suggestions}
    regex_sub_file $TMP_FILE_1 "&\s(\S+)\s([0-9]+)\s([0-9]+):\s(.+)" "L\3: \\${RED}\1\\${NC} => (\2) \\${GREEN}\4\\${NC}\n"
    hunspell -L -t -i utf-8 -d en_US <$FILE > $TMP_FILE_2
    NLINES=$(wc -l $TMP_FILE_1 | awk '{ print $1 }') 

    if [ $NLINES -eq 0 ]; then
      if [ $VERBOSE -ge 1 ]; then
        echo $FILE " is empty"
      fi

      if [ $REPORT -eq 1 ]; then
        echo $file " no errors" >> $REPORT_FILE
        EMPTY_FILES=$(($EMPTY_FILES+1))
      fi
    else
      #Erase file
      echo -e $(cat $TMP_FILE_1)
      cat $TMP_FILE_2

      DIFF_FILE="${FILE}${DIFF_EXT}"
      echo "Created by texspell">$DIFF_FILE

      j=0
      for (( i=1; i <= $NLINES ; i++ ))
      do
        if [ -z "$(sed "${i}q;d" $TMP_FILE_1)" ]; then
          j=$((j+1))
        else
          echo "----" >> $DIFF_FILE
          echo -e $(sed "${j}q;d" $TMP_FILE_2 | grep -Fx -n -f - $FILE | cut -f1 -d:) >> $DIFF_FILE
          echo -e $(sed "${j}q;d" $TMP_FILE_2) >> $DIFF_FILE
          echo -e $(sed "${i}q;d" $TMP_FILE_1) >> $DIFF_FILE
        fi
      done

      if [ $REPORT -eq 1 ]; then
        echo $FILE " Errors: " $(grep -c '[\&]' $TMP_FILE_1) "Unknown words" $(grep -c '[\#]' $TMP_FILE_1) >> $REPORT_FILE
        ERRORS=$(($ERRORS +  $(grep -c '[\&]' $TMP_FILE_1)))
        UNKNOWN_WORDS=$(($UNKNOWN_WORDS + $(grep -c '[\#]' $TMP_FILE_1)))
        FILES=$(($FILES+1))
      fi
    fi

  done
  if [ $REPORT -eq 1 ]; then
    sed -i "1 aEnd    $(date)"  $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Errors files " $FILES >> $REPORT_FILE
    echo "Empty files: " $EMPTY_FILES >> $REPORT_FILE
    echo "Errors: " $ERRORS >> $REPORT_FILE
    echo "Unknown words: " $UNKNOWN_WORDS >> $REPORT_FILE
    if [ $VERBOSE -ge 1 ]; then
      echo ""
      echo ""
      cat $REPORT_FILE
    fi
  fi
fi

