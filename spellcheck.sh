# Requires hunspell
# on Ubuntu: sudo apt install hunspell

# Currently, this file:
# A - If launch without argument
#   1) grabs all .tex files in "." directory and its sub-directories but ignore the file if name "colors.tex"
#   2) generates a spell-checked file for each .tex file and then saves a diff of both file to highlight the spelling mistakes and their location in a nice format
# B - If launched with argument "clean"
#   1) removes all .diff files in "." directory and its sub-directories

ignore="! -iname colors.tex"

if [ "$#" -gt 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

if [ "$#" -eq 1 ]; then
    if [ "$1" = "clean" ]; then
    	find . -type f -iname "*.diff" | xargs -n 1 rm
   	exit 0
    fi
    echo "Unknown parameter: $1"
    exit 1
fi

# Generate all .diff files

find . -type f -iname "*.tex" $ignore | xargs -n 1 -t -I % sh -c 'hunspell -t -U -i utf-8 % > %.temp; diff % %.temp > %.diff; rm %.temp'
