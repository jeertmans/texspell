DESTDIR = /usr/local/bin
DESTDIRCONFIG = /etc
COMPDIRBASH = $(shell pkg-config --variable=completionsdir bash-completion)
COMPDIRZSH = /usr/local/share/zsh/site-functions
COMPDIRZSHTARGET = $(COMPDIRZSH)-$(wildcard $(COMPDIRZSH))
COMPDIRZSHPRESENT =$(COMPDIRZSH)-$(COMPDIRZSH)


install: ## Installs texspell and Opendetex
	$(MAKE) install-texspell
	$(MAKE) install-detex

install-texspell: | $(COMPDIRZSHTARGET) ## Installs texspell
	rm -f ${DESTDIR}/texspell
	install ./texspell.sh ${DESTDIR}/texspell
	rm -f ${COMPDIRBASH}/texspell
	install ./texspell-complete.sh ${COMPDIRBASH}/texspell

$(COMPDIRZSHPRESENT):
	rm -f ${COMPDIRZSH}/_texspell
	install ./texspell-complete-zsh.sh ${COMPDIRZSH}/_texspell 

install-detex: ## Installs Opendetex
	cd opendetex && $(MAKE) install

uninstall: ## Uninstalls texspell and Opendetex
	$(MAKE) uninstall-texspell
	$(MAKE) uninstall-detex

uninstall-texspell: ## Uninstalls texspell
	rm -f ${DESTDIR}/texspell
	rm -f ${COMPDIR}/texspell

uninstall-detex: ## Uninstalls Opendetex
	cd opendetex && $(MAKE) uninstall

check-scripts: ## Runs a shell code checker on every .sh file
	shellcheck *.sh

# From: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Prints this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
