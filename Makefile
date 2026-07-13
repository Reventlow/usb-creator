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
