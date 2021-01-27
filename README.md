# texspell
Command line spell-checker tools for TeX documents

# Installation
## Prerequisite
You will need the following package:
```
hunspell
```
##
- Clone or download the source code
- Make the file executable `chmod +x spellcheck.sh`
- Make a link to make this file executable anywhere `ln spellcheck.sh ~/bin/texspell`

Optionnal:
- Make the completion script executable `chmod +x texspell-complete.sh`
- Add to your .bashrc/zshrc `source YOUR_INSTALL_PATH/texspell/texspell-complete.sh` and do not forget to replace `YOUR_INSTALL_PATH` by your actual install path


# Coding style

* Variable names should use capital letters and underscores only
* Function names should use lower case letters and underscores only
* Functions should have docstring accordingly to what is already done
* Functions should use local variables
* Prefer creating function if a code is often re-used
* Code is splitted into several sections and the appropriate one should be used when writing code

# todo-lists

## v0.1 - working prototype

### Generating diff files

* [x] have a working spell check that generate .diff files ?
* [x] maybe find a better representation than .diff files ?
* [x] add line number
* [x] Propose multiple correction
* [x] Diff reporting
* [x] Do not generate empty files
* [x] Temp files and report files are generated such that they do not overwrite any existing file (`mktemp` for e.g.) or, at-least, warn for it ("Are you sure?: [Y/n]")

### Command line tools

* [ ] use a user-defined dictionary
* [ ] allow to ignore errors in specific LaTeX env. (tikzpicture, ...) ?
* [x] Add installation instruction
* [x] Add completion on command line
* [x] Add help
* [x] Make hunspell shut up
* [x] add verbose environment
* [ ] Use shasum to only check files that changed (optional)
* [x] Do not explore hidden directories (only if specified)
* [ ] Add mode so than `man` command can read only documentation ? No rly useful but could be nice
* [ ] Add color mode, e.g., by coloring errors in red and propositions in green

### CI - Testing

* [ ] Add mock .tex to test the tool

### Edit from diff files

* [ ] (hard) possibility to jump from .diff file line to correspond file and line or to "accept" the modification (then .diff file is updated)
* [ ] produce incremental dictionary (to avoid false-positive)
* [ ] possibility to ignore so files (files or file patterns) from a file
* [ ] find a good way to show (and maybe quickly edit) the spelling errors
* [ ] add a hierarchical representation of errors in files (tree main -> sections -> ...) accordingly to file hierarchy
* [ ] Easily ignore / naviguate from files (and know which error you are looking at)
* [ ] Generate hidden file that reports last program execution (so that it can propose files that were only gen. by last exec.)


## v0.2 - publish tools

* [ ] setup environment (folders, etc.)
* [ ] setup a requirements file
* [ ] make executable globally acessible on machine
* [ ] publish tool as a packet that could be installed using apt for example


## V0.3 - Ideas to sort
* [ ] Interactive mode: print the errors one by one and choose accept/ignore/refuse
* [ ] add machine learning (eg.: Writefull add-on) techniques to produces higher quality text ?
