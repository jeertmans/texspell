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
