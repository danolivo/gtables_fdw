# contrib/gtables_fdw/Makefile

EXTENSION = gtables_fdw
EXTVERSION = 0.1

MODULE_big = gtables_fdw
OBJS = gtables_fdw.o $(WIN32RES)

DATA = gtables_fdw--0.1.sql
PGFILEDESC = "gtables_fdw - global tables across fdw api"

EXTRA_INSTALL=contrib/postgres_fdw contrib/gtables_fdw
#REGRESS = gtables_fdw

ifdef USE_PGXS
PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/gtables_fdw
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

check:
	$(prove_check)
