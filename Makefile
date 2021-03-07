DESTDIR = /usr/local/bin
COMPDIRBASH = $(shell pkg-config --variable=completionsdir bash-completion)
COMPDIRZSH = /usr/local/share/zsh/site-functions
COMPDIRZSHTARGET = $(COMPDIRZSH)-$(wildcard $(COMPDIRZSH))
COMPDIRZSHPRESENT =$(COMPDIRZSH)-$(COMPDIRZSH)


install:
	$(MAKE) install-texspell
	$(MAKE) install-detex
	
install-texspell: | $(COMPDIRZSHTARGET)
	rm -f ${DESTDIR}/texspell
	install ./texspell.sh ${DESTDIR}/texspell
	rm -f ${COMPDIRBASH}/texspell
	install ./texspell-complete.sh ${COMPDIRBASH}/texspell

$(COMPDIRZSHPRESENT):
	rm -f ${COMPDIRZSH}/_texspell
	install ./texspell-complete-zsh.sh ${COMPDIRZSH}/_texspell 

install-detex:
	cd opendetex && $(MAKE) install

uninstall:
	$(MAKE) uninstall-texspell
	$(MAKE) uninstall-detex

uninstall-texspell:
	rm -f ${DESTDIR}/texspell
	rm -f ${COMPDIR}/texspell

uninstall-detex:
	cd opendetex && $(MAKE) uninstall

