SUBDIRS := spec/ics-3-connection-semantics
TOPTARGETS := all clean

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

setup_dependencies:
	pip install matplotlib networkx

check_links:
	python ./scripts/check_links.py

check_dependencies:
	python ./scripts/check_dependencies.py

check_syntax:
	bash ./scripts/check_syntax.sh

.PHONY: $(TOPTARGETS) $(SUBDIRS) setup_dependencies check_links check_dependencies check_syntax
