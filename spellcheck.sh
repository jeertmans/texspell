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
VERBOSITY=1 # Level of verbosity
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
    --verbosity)
      VERBOSITY=$2
      shift
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
  $(sed -E "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" $IN)
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
  echo $(echo "${STR}" | sed -E "s/${PAT}/${SUB}/g")
}

# Substitute regex pattern in file (in-place)
# 1 - Input file
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

# Write into a file the errors, their line number and the correction suggestions
# 1 - Input file
# 2 - Output file
#
# R - Nothing
function errors_and_suggestions {
  local IN=$1
  local OUT=$2

  # Run hunspell, discarding lines with no error (*)
  hunspell -a -t -i utf-8 -d en_US <$IN | grep -v '[\*]' > $OUT
  # Clean the first line of the file containing a header from Ispell
  sed -i '1d' $OUT
  # Remove extra linebreaks
  sed -i '/^$/N;/^\n$/D' $OUT
  
  MATCH="&\s(\S+)\s([0-9]+)\s([0-9]+):\s(.+)"
  SUBS="V\3: \1 => (\2) \4"

  regex_sub_file $OUT "${MATCH}" "${SUBS}" 
}

# Write into a file the lines where errors occur
# 1 - Input file
# 2 - Ouput file
#
# R - Nothing
function lines_with_errors {
  local IN=$1
  local OUT=$2
  hunspell -L -t -i utf-8 -d en_US <$IN > $OUT
}

# Returns a given line from a file
# 1 - The file
# 2 - The line number
#
# R - The Ith line
function ith_line_file {
  local FILE=$1
  local I=$2
  echo "$(sed "${I}q;d" $FILE)"
}

# Return the line number of the first line matching a given string
# 1 - The search string
# 2 - The file
#
# R - The line number
function first_match_lineno_file {
  local MATCH=$1
  local FILE=$2
  #echo $(echo $MATCH | grep -Fx -n -f - $FILE | cut -f1 -d:)
  echo $(grep -o -m 1 -h -n "${MATCH}" $FILE | cut -f1 -d:)

}

function report_file {
  local FILE=$1
  local FILENAME=$(basename $FILE)

  # Generate TMP 1
  local TMP_FILE_1=$(mktemp -p "${TEMP_DIR}" "${FILENAME}1_XXXXX.tmp")
  errors_and_suggestions $FILE $TMP_FILE_1

  
  # Generate TMP 2
  local TMP_FILE_2=$(mktemp -p "${TEMP_DIR}" "${FILENAME}2_XXXXX.tmp")
  lines_with_errors $FILE $TMP_FILE_2 

  if [ $VERBOSITY -ge 1 ]; then
    echo "Proccesing" $FILE
  fi

  # Count the # of lines (errors) in file
  local N_LINES=$(wc -l $TMP_FILE_1 | awk '{ print $1 }') 

  if [ $N_LINES -eq 0 ]; then
    if [ $VERBOSITY -ge 1 ]; then
      echo $FILE " is empty"
    fi

    if [ $REPORT -eq 1 ]; then
      echo $FILE " no errors" >> $REPORT_FILE
      EMPTY_FILES=$(($EMPTY_FILES+1))
    fi
  else
    local DIFF_FILE="${FILE}${DIFF_EXT}"
    echo "Created by texspell">$DIFF_FILE

    j=0
    k=-1
    POS=0
    COLORIZED_LINE=""
    COLORIZED_ERRORS=""
    for (( i=1; i <= $N_LINES ; i++ ))
    do
      SUGGESTIONS=$(ith_line_file $TMP_FILE_1 $i)

      if [ -z "${SUGGESTIONS}" ]; then
        j=$((j+1))
      else
        if [ $j -gt $k ]; then

          if [ $VERBOSITY -ge 2 ] && [ ! -z "${COLORIZED_ERRORS}" ]; then
            echo -e $COLORIZED_LINE
            echo -e $COLORIZED_ERRORS
            COLORIZED_LINE=""
            COLORIZED_ERRORS=""
            POS=0
          fi

          ERRORNOUS_LINE="$(ith_line_file $TMP_FILE_2 $j)"
          LINE_NO=$(first_match_lineno_file "${ERRORNOUS_LINE}" $FILE)

          echo "----" >> $DIFF_FILE
          echo "In line ${LINE_NO}:" >> $DIFF_FILE
          echo $ERRORNOUS_LINE >> $DIFF_FILE
          k=$j
        fi
        
        echo $SUGGESTIONS >> $DIFF_FILE

        if [ $VERBOSITY -ge 2 ]; then
          MATCH="(V([0-9]+):\s)(\S+)(\s=>\s)(.+)"
          SUBS1="\1\\${RED}\3\\${NC}\4\\${GREEN}\5\\${NC}"
          SUBS2="\2"
          SUBS3="\3"
          V_POSITION=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS2}")
          ERRORNOUS_WORD=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS3}")
          COLORIZED_SUGG=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS1}")
          if [ -z "$COLORIZED_ERRORS" ]; then
            COLORIZED_ERRORS="${COLORIZED_SUGG}"
          else
            COLORIZED_ERRORS+="\n${COLORIZED_SUGG}"
          fi
          LENGTH=$((V_POSITION-POS))

          COLORIZED_LINE+="${ERRORNOUS_LINE:$POS:$LENGTH}${RED}${ERRORNOUS_WORD}${NC}"
          POS=$((V_POSITION+${#ERRORNOUS_WORD}))
        fi
      fi
    done
    # Print last line
    if [ $VERBOSITY -ge 2 ] && [ ! -z "${COLORIZED_ERRORS}" ]; then
      echo -e $COLORIZED_LINE
      echo -e $COLORIZED_ERRORS
    fi

    if [ $REPORT -eq 1 ]; then
      echo $FILE " Errors: " $(grep -c '[\&]' $TMP_FILE_1) "Unknown words" $(grep -c '[\#]' $TMP_FILE_1) >> $REPORT_FILE
      # We could count errors in the loop (each i) but global variable doesn seem to be updated
      ERRORS=$(($ERRORS +  $(grep -c "[=>]" $TMP_FILE_1)))
      UNKNOWN_WORDS=$(($UNKNOWN_WORDS + $(grep -c '[\#]' $TMP_FILE_1)))
    fi
  fi

}

####################
# Script execution #
####################

# Cleaning diff files
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
  
  EMPTY_FILES=0
  ERRORS=0
  UNKNOWN_WORDS=0
  if [ $REPORT -eq 1 ]; then 
    echo "Start " $(date) > $REPORT_FILE 
    echo "" >> $REPORT_FILE
  fi
    
  FILES=$(find_files $SRC $TEX_EXT $CHECK_HIDDEN $ignore)
  
  FILES_LIST=(`echo $FILES | sed "s/ /\n/g"`)
  N_FILES=${#FILES_LIST[@]}
  
  if [ $VERBOSITY -ge 1 ]; then
    echo "Processing ${N_FILES} file(s)..."
  fi

  for FILE in ${FILES_LIST[@]}; do
    # Create a reporting for each file
    report_file $FILE 
  done

  if [ $REPORT -eq 1 ]; then
    # Reporting summary of results in a file
    sed -i "1 aEnd    $(date)"  $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "# of files with error(s): " $(($N_FILES-$EMPTY_FILES)) >> $REPORT_FILE
    echo "# of files without error: " $EMPTY_FILES >> $REPORT_FILE
    echo "# of error(s): " $ERRORS >> $REPORT_FILE
    echo "# of unknown words: " $UNKNOWN_WORDS >> $REPORT_FILE
    if [ $VERBOSITY -ge 1 ]; then
      echo ""
      echo "Report summary:"
      echo ""
      cat $REPORT_FILE
    fi
  fi
fi

