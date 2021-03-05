DESTDIR = /usr/local/bin

install:
	rm -f ${DESTDIR}/texspell
	ln spellcheck.sh ${DESTDIR}/texspell
	cd opendetex && $(MAKE) install
	
install-texspell:
	rm -f ${DESTDIR}/texspell
	ln spellcheck.sh ${DESTDIR}/texspell

install-detex:
	cd opendetex && $(MAKE) install

uninstall:
	rm -f ${DESTDIR}/texspell
	cd opendetex && $(MAKE) uninstall

uninstall-texspell:
	rm -f ${DESTDIR}/texspell

uninstall-detex:
	cd opendetex && $(MAKE) uninstall

