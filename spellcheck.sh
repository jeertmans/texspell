#! /bin/bash
# Requires hunspell
# on Ubuntu: sudo apt install hunspell

# Currently, this file:
# A - If launch without argument
#   1) grabs all .tex files in "." directory and its sub-directories but ignore the file if name "colors.tex"
#   2) generates a spell-checked file for each .tex file and then saves a diff of both file to highlight the spelling mistakes and their location in a nice format
# B - If launched with argument "clean"
#   1) removes all .diff files in "." directory and its sub-directories

ignore="! -iname colors.tex"
CLEAN=0
SPELL=1
VERBOSE=1
REPORT=1
SRC="."
SRCISFILE=0
TEMP_DIR=""

# Flags handler
while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "texspell-- Command line spell-checker tool for TeX documents"
      echo " "
      echo "Options:"
      echo "-h, --help: get this help"
      echo "-c, --clean: Remove all .diff in the . directiory and sub-directories"
      echo "-o, --clean-only: Do not generate the .diff"
      echo "--no-report: Do not produce a report"
      echo "-v, --version: get version number"
      echo " "
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

# Clean
if [ $CLEAN -eq 1 ]; then
  if [ $SRCISFILE -eq 1 ]; then
    if [ -f $SRC.diff ]; then
      rm $SRC.diff
    fi
  else
    find $SRC -type f -iname "*.diff" | xargs -n 1 -r rm
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
    rm report_texspell
    touch report_texspell
    echo "Start " $(date) > report_texspell 
    echo "" >> report_texspell
  fi
  
  echo "Processing files..."

  for file in $(find $SRC -type f -iname "*.tex" $ignore); do
    if [ $VERBOSE -ge 1 ]; then
      echo $file
    fi

    filename=$(basename $file)
    TMP_FILE_1=$(mktemp -p "${TEMP_DIR}" "${filename}1_${date}_XXXXX.tmp")
    TMP_FILE_2=$(mktemp -p "${TEMP_DIR}" "${filename}2_${date}_XXXXX.tmp")

    hunspell -a -t -i utf-8 -d en_US <$file | grep '[\#\&]' > $TMP_FILE_1
    sed -i '1d' $TMP_FILE_1
    hunspell -L -i utf-8 -d en_US <$file > $TMP_FILE_2
    NLINES=$(wc -l $TMP_FILE_1 | awk '{ print $1 }') 

    if [ $NLINES -eq 0 ]; then
      if [ $VERBOSE -ge 1 ]; then
        echo $file " is empty"
      fi

      if [ $REPORT -eq 1 ]; then
        echo $file " no errors" >> report_texspell
        EMPTY_FILES=$(($EMPTY_FILES+1))
      fi
    else
      #Erase file
      echo "Created by texspell">$file.diff

      for (( i=1; i <= $NLINES ; i++ ))
      do
        echo "----" >> $file.diff
        echo $(sed "${i}q;d" $TMP_FILE_2 | grep -Fx -n -f - $file | cut -f1 -d:) >> $file.diff
        echo $(sed "${i}q;d" $TMP_FILE_2) >> $file.diff
        echo $(sed "${i}q;d" $TMP_FILE_1) >> $file.diff
      done

      if [ $REPORT -eq 1 ]; then
        echo $file " Errors: " $(grep -c '[\&]' $TMP_FILE_1) "Unknown words" $(grep -c '[\#]' $TMP_FILE_1) >> report_texspell
        ERRORS=$(($ERRORS +  $(grep -c '[\&]' $TMP_FILE_1)))
        UNKNOWN_WORDS=$(($UNKNOWN_WORDS + $(grep -c '[\#]' $TMP_FILE_1)))
        FILES=$(($FILES+1))
      fi
    fi

  done
  if [ $REPORT -eq 1 ]; then
    sed -i "1 aEnd $(date)"  report_texspell
    echo "" >> report_texspell
    echo "Errors files " $FILES >> report_texspell
    echo "Empty files: " $EMPTY_FILES >> report_texspell
    echo "Errors: " $ERRORS >> report_texspell
    echo "Unknown words: " $UNKNOWN_WORDS >> report_texspell
    if [ $VERBOSE -ge 1 ]; then
      echo ""
      echo ""
      cat report_texspell
    fi
  fi
fi

