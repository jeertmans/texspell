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
    *)
      echo "Unknown flag: "${1}
      exit 1
      ;;
  esac
done

# Clean
if [ $CLEAN -eq 1 ]; then
  find . -type f -iname "*.diff" | xargs -n 1 rm
fi

# Typechecking
if [ $SPELL -eq 1 ]; then
  find . -type f -iname "*.tex" $ignore | xargs -n 1 -t -I % sh -c 'hunspell -t -U -i utf-8 % > %.temp; diff % %.temp > %.diff; rm %.temp'
fi


