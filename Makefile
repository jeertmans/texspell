DESTDIR = /usr/local/bin
COMPDIR = $(shell pkg-config --variable=completionsdir bash-completion)


install:
	$(MAKE) install-texspell
	$(MAKE) install-detex
	
install-texspell:
	rm -f ${DESTDIR}/texspell
	install ./texspell.sh ${DESTDIR}/texspell
	rm -f ${COMPDIR}/texspell
	install ./texspell-complete.sh ${COMPDIR}/texspell

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

