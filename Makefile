DESTDIR = /usr/local/bin

install:
	$(MAKE) install-texspell
	$(MAKE) install-detex
	
install-texspell:
	rm -f ${DESTDIR}/texspell
	ln spellcheck.sh ${DESTDIR}/texspell

install-detex:
	cd opendetex && $(MAKE) install

uninstall:
	$(MAKE) uninstall-texspell
	$(MAKE) uninstall-detex

uninstall-texspell:
	rm -f ${DESTDIR}/texspell

uninstall-detex:
	cd opendetex && $(MAKE) uninstall

