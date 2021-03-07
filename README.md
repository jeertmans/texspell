# texspell
Command line spell-checker tools for TeX documents

# Intallation
## LanguageTool
The V1 of texspell is based on [languageTool](https://dev.languagetool.org/http-server.html) so you will need to install it first:
- Download the `.zip` from the source
- Unzip it where you want to 

**Note:** LanguageTool is a server tool so you can install it on another machine instead of your own computer



## Opendetex
Opendetex will help us to parse our `.tex` into plain text to let LanguageTool correct it. To install it 
```
git submodule init
git submodule update
```

## Step by step
To install it simply do
```
sudo make install
```

It will install both `texspell` and `opendetex`. If you want you can install each module separately:

```
sudo make install-texspell
sudo make install-detex
```

If you need to desinstall `texspell`:
```
sudo make uninstall
```
or
```
sudo make uninstall-texspell
sudo make uninstall-detex
```

**Note:**
If you want to use the completion for zsh make sure that it is activated. Otherwise add those lines in your `.zshrc`:
```
autoload -U compinit
compinit
```

# Coding style

* Variable names should use capital letters and underscores only
* Function names should use lower case letters and underscores only
* Functions should have docstring accordingly to what is already done
* Functions should use local variables
* Prefer creating function if a code is often re-used
* Code is splitted into several sections and the appropriate one should be used when writing code
* Only use "" instead of ''

# todo-lists

## V1.0 Add languageTool
Hunspell is great **but** for us it has 2 main drawback:
1) Hunspell will try to correct words that will be present in the pdf
2) Hunspell can only do word by word correction.
We want to switch to languageTool which is a more powerfull typechecker but we will need to rewrite a lot of the code to adapt it.


* [ ] Add languageTool installation instruction
* [ ] Test the [ngram](https://dev.languagetool.org/finding-errors-using-n-gram-data)
* [ ] Parse Tex to txt
* [ ] Correct txt
* [ ] Associate corrected txt with line in the .tex
* [ ] Add a config file
* [ ] Add a mode to launch also the languagetool server
* [ ] Add a mode to use a default server
* [ ] Add a mode to use a specific server

# Version
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

* [x] use a user-defined dictionary
* [ ] allow to ignore errors in specific LaTeX env. (tikzpicture, ...) ?
* [x] Add installation instruction
* [x] Add completion on command line
* [x] Add help
* [x] Make hunspell shut up
* [x] add verbose environment
* [x] Use shasum to only check files that changed (optional)
* [x] Do not explore hidden directories (only if specified)
* [ ] Add mode so than `man` command can read only documentation ? No rly useful but could be nice
* [x] Add color mode, e.g., by coloring errors in red and propositions in green

### CI - Testing

* [x] Add mock .tex to test the tool
* [ ] Add unitary testing
* [ ] Add pipeline to prevent failed test

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
* [x] make executable globally acessible on machine
* [ ] publish tool as a packet that could be installed using apt for example


## V0.3 - Ideas to sort
* [ ] Interactive mode: print the errors one by one and choose accept/ignore/refuse
* [ ] add machine learning (eg.: Writefull add-on) techniques to produces higher quality text
