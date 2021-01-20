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

# todo-lists

## v0.1 - working prototype

* [x] have a working spell check that generate .diff files ?
* [ ] maybe find a better representation than .diff files ?
* [ ] (hard) possibility to jump from .diff file line to correspond file and line or to "accept" the modification (then .diff file is updated)
* [ ] produce incremental dictionary (to avoid false-positive)
* [ ] possibility to ignore so files (files or file patterns) from a file
* [ ] find a good way to show (and maybe quickly edit) the spelling errors
* [ ] allow to ignore errors in specific LaTeX env. (tikzpicture, ...) ?
* [ ] add a hierarchical representation of errors in files (tree main -> sections -> ...) accordingly to file hierarchy
* [ ] add machine learning (eg.: Writefull add-on) techniques to produces higher quality text ?
* [x] Add installation instruction
* [x] Add completion on command line
* [x] Add help
* [ ] Make hunspell shut up
* [ ] add verbose environment
* [ ] Add mock .tex to test the tool
* [ ] Do not explore hidden directories
* [ ] Do not generate empty files


## v0.2 - publish tools

* [ ] setup environment (folders, etc.)
* [ ] setup a requirements file
* [ ] make executable globally acessible on machine
* [ ] publish tool as a packet that could be installed using apt for example


## V0.3 - Ideas to sort
* [ ] Interactive mode: print the errors one by one and choose accept/ignore/refuse
