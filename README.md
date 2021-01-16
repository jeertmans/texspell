# texspell
Command line spell-checker tools for TeX documents

# todo-lists

## v0.1 - working prototype

- [x] have a working spell check that generate .diff files ?
- [] maybe find a better representation than .diff files ?
- [] (hard) possibility to jump from .diff file line to correspond file and line or to "accept" the modification (then .diff file is updated)
- [] produce incremental dictionary (to avoid false-positive)
- [] possibility to ignore so files (files or file patterns) from a file
- [] find a good way to show (and maybe quickly edit) the spelling errors
- [] allow to ignore errors in specific LaTeX env. (tikzpicture, ...) ?
- [] add a hierarchical representation of errors in files (tree main -> sections -> ...) accordingly to file hierarchy
- [] add machine learning (eg.: Writefull add-on) techniques to produces higher quality text ?


## v0.2 - publish tools
- [] setup environment (folders, etc.)
- [] setup a requirements file
- [] make executable globally acessible on machine
- [] publish tool as a packet that could be installed using apt for example
