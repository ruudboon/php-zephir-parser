RE2C := $(shell command -v re2c 2>/dev/null)
ifndef RE2C
$(error No re2c found in the $$PATH. Consider install re2c or/and add re2c executable to the $$PATH)
endif

RE2C_FLAGS=
RE2C_VERSION=$(shell $(RE2C) --vernum 2>/dev/null)
ifeq ($(shell test "$(RE2C_VERSION)" -gt "9999"; echo $$?),0)
RE2C_FLAGS=-W
endif

clean: parser-clean tests-clean

.PHONY: parser-clean
parser-clean:
	find . -name \*.loT -o -name \*.out | xargs rm -f
	find ./parser \
		   -name zephir.c  \
		-o -name zephir.h  \
		-o -name scanner.c \
		-o -name parser.c  | xargs rm -f


.PHONY: tests-clean
tests-clean:
	find ./tests -name \*.php -o -name \*.sh | xargs rm -f
	find ./tests -name \*.diff -o -name \*.exp -o -name \*.log | xargs rm -f
	find ./tests -name \*.tmp | xargs rm -f

.PHONY: maintainer-clean
maintainer-clean:
	@echo 'This command is intended for maintainers to use; it'
	@echo 'deletes files that may need special tools to rebuild.'
	@echo
	-rm -f $(srcdir)/parser/lemon
	-rm -f $(srcdir)/parser/scanner.c
	-rm -f $(srcdir)/parser/parser.c

$(srcdir)/parser/scanner.c: $(srcdir)/parser/scanner.re
	$(RE2C) $(RE2C_FLAGS) -d --no-generation-date -o $@ $<

$(srcdir)/parser/lemon: $(srcdir)/parser/lemon.c
	$(CC) $< -o $@

$(srcdir)/parser/parser.c: $(srcdir)/parser/zephir.c $(srcdir)/parser/base.c
	@echo "#include <php.h>" > $@
	cat $< >> $@
	echo "#line 1 \"$(top_srcdir)/parser/base.c\"" >> $@
	cat $(top_srcdir)/parser/base.c >> $@

$(srcdir)/parser/zephir.c: $(srcdir)/parser/zephir.lemon $(srcdir)/parser/lemon patch-libtool
	$(top_srcdir)/parser/lemon $<

# For more see: https://stackoverflow.com/q/49476206
.PHONY: patch-libtool
patch-libtool: libtool
	$(AWK) '/case \$$p in/{print;print "\t    *.gcno)\n\t    ;;";next}1' $^ > $^.tmp && mv $^.tmp $^
