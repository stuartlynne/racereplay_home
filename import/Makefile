
#PATH = ":/bin:/usr/bin:/usr/local/bin:/home/racereplay/bin:"

DIR=$(shell expr $$(pwd) : "/home/\([^/]*\)")
PATH = ":/bin:/usr/bin:/usr/local/bin:/home/${DIR}/bin:"

DATABASE = "${DIR}"
DBUSER = "${DIR}"
DBPASSWORD = "aa.bb.cc"



CSV = $(wildcard *.csv)
FILES = $(subst .csv,,${CSV})

TABLES = $(subst .csv,.tab,$(filter-out lapd-%,${CSV}))


ADMINFILES = organizers.csv users.csv venues.csv chips.csv
DAILYFILES = events.csv chiphistory.csv
MISCFILES = newbattery.csv


ADMINTABLES = $(subst .csv,.tab,${ADMINFILES})
DAILYTABLES = $(subst .csv,.tab,${DAILYFILES})
MISCTABLES = $(subst .csv,.tab,${MISCFILES})


%.tab: %.csv
	csv2mysql $< > $@

.PHONY : all usage lapd tables test clean


all: lapd daily


usage:
	@echo "make lapd | tables | test"
	@echo

lapd: 
	cd lapd; make lapd

admin: ${ADMINTABLES}
daily: ${DAILYTABLES}
misc: ${MISCTABLES}

test:
	@echo DIR: ${DIR}
	@echo CSV: ${CSV}
	@echo FILES: ${FILES}
	@echo ADMINTABLES: ${ADMINTABLES}
	@echo MISC: ${MISCTABLES}
	@echo PATH: ${PATH}
	@echo DATABASE: ${DATABASE}
	@echo DBUSER: ${DBUSER}

drop: clean
	-@echo "DROP DATABASE ${DATABASE};" | mysql -u root -p

create:
	createdb ${DATABASE}
	#cat /home/${DBUSER}/etc/${DATABASE}.sql | mysql -u root -p

new: clean drop create


clean:
	-cd lapd; make clean
	-rm -f *.tab *.lap




