
PATH = ":/bin:/usr/bin:/usr/local/bin:/home/racerplay/bin:"

DATABASE = "racetest"
DBUSER = "racetest"
DBPASSWORD = "aa.bb.cc"


CSV = $(wildcard *.csv)
FILES = $(subst .csv,,${CSV})

LAPD = $(subst .csv,.lap,$(filter lapd-%,${CSV}))

%.lap: %.csv
	touch $@#
	lapimport $< > $@

.PHONY : all usage lapd tables test clean

all: lapd

usage:
	@echo "make lapd | test"
	@echo

lapd: ${LAPD}

test:
	@echo CSV: ${CSV}
	@echo FILES: ${FILES}
	@echo LAPD: ${LAPD}


clean:
	-rm -f *.tab *.lap



