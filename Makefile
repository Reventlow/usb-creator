# Conventional entry points; CI uses the same targets.
.PHONY: test lint sbom install

test:
	bash tests/test.sh

lint:
	bash -n usb-creator
	shellcheck -x usb-creator tests/test.sh scripts/gen-sbom.sh packaging/*.sh

sbom:
	scripts/gen-sbom.sh > usb-creator.spdx.json

install:
	install -Dm755 usb-creator $(DESTDIR)/usr/local/bin/usb-creator
	install -Dm644 docs/usb-creator.1 $(DESTDIR)/usr/local/share/man/man1/usb-creator.1
	install -Dm644 docs/tldr/usb-creator.md $(DESTDIR)/usr/local/share/doc/usb-creator/tldr.md
