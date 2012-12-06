CREATE SCHEMA racetest;

CREATE TABLE racetest.organizers ( 
	organizerid          INT NOT NULL AUTO_INCREMENT,
	organizer            VARCHAR( 20 ) NOT NULL,
	description          VARCHAR( 100 ),
	CONSTRAINT pk_organizers PRIMARY KEY ( organizerid ),
	CONSTRAINT idx_organizers UNIQUE ( organizer )
 );

ALTER TABLE racetest.organizers COMMENT 'List of  organizers that own venues, do events, loan chips.';

ALTER TABLE racetest.organizers MODIFY organizerid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify organizer table entry';

ALTER TABLE racetest.organizers MODIFY organizer VARCHAR( 20 ) NOT NULL COMMENT 'Short display name for organizer.';

ALTER TABLE racetest.organizers MODIFY description VARCHAR( 100 ) COMMENT 'Long description for organizer.';

CREATE TABLE racetest.users ( 
	userid               INT NOT NULL AUTO_INCREMENT,
	lastname             VARCHAR( 100 ),
	firstname            VARCHAR( 100 ),
	login                VARCHAR( 32 ),
	email                VARCHAR( 200 ),
	gender               VARCHAR( 1 ),
	team                 VARCHAR( 100 ),
	yob                  VARCHAR( 4 ),
	ucicat               VARCHAR( 12 ),
	abilitycat           VARCHAR( 20 ),
	privacyflag          VARCHAR( 10 ),
	strava               VARCHAR( 100 ),
	ucicode              VARCHAR( 20 ),
	CONSTRAINT pk_users PRIMARY KEY ( userid ),
	CONSTRAINT idx_users_lastname_firstname UNIQUE ( lastname, firstname )
 );

CREATE INDEX idx_users_login ON racetest.users ( login );

ALTER TABLE racetest.users COMMENT 'Self Administered information about users.';

ALTER TABLE racetest.users MODIFY userid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify user table entry';

ALTER TABLE racetest.users MODIFY ucicode VARCHAR( 20 ) COMMENT 'UCI Code';

CREATE TABLE racetest.venues ( 
	venueid              INT NOT NULL AUTO_INCREMENT,
	organizerid          INT NOT NULL,
	venue                VARCHAR( 20 ) NOT NULL,
	description          VARCHAR( 100 ) NOT NULL,
	distance             FLOAT,
	minspeed             FLOAT,
	maxspeed             FLOAT,
	gaptime              FLOAT,
	timezone             VARCHAR( 20 ),
	activeflag           BOOL,
	CONSTRAINT pk_venues PRIMARY KEY ( venueid ),
	CONSTRAINT idx_venues_by_venue UNIQUE ( venue )
 );

CREATE INDEX idx_venues ON racetest.venues ( organizerid );

ALTER TABLE racetest.venues COMMENT 'list of locations that organizers run races at';

ALTER TABLE racetest.venues MODIFY venueid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify venue table entry';

ALTER TABLE racetest.venues MODIFY organizerid INT NOT NULL COMMENT 'Organizer that uses this venue.';

ALTER TABLE racetest.venues MODIFY venue VARCHAR( 20 ) NOT NULL COMMENT 'Short display name for venue.';

ALTER TABLE racetest.venues MODIFY description VARCHAR( 100 ) NOT NULL COMMENT 'Description of the venue.';

ALTER TABLE racetest.venues MODIFY distance FLOAT COMMENT 'in km of each lap';

ALTER TABLE racetest.venues MODIFY minspeed FLOAT COMMENT 'minimum expected speed';

ALTER TABLE racetest.venues MODIFY maxspeed FLOAT COMMENT 'maximum expected speed';

ALTER TABLE racetest.venues MODIFY gaptime FLOAT COMMENT 'allowable gap in ms between riders in a group';

ALTER TABLE racetest.venues MODIFY timezone VARCHAR( 20 ) COMMENT 'Timezone that the timing system generates TimeStamps in.';

ALTER TABLE racetest.venues MODIFY activeflag BOOL COMMENT 'active venue';

CREATE TABLE racetest.chips ( 
	organizerid          INT,
	chipid               INT NOT NULL AUTO_INCREMENT,
	chip                 VARCHAR( 20 ),
	loaner               BOOL,
	shortname            VARCHAR( 10 ) NOT NULL,
	totalactivations     INT,
	currentactivations   INT,
	replacebattery       BOOL,
	batteryreplaced      DATE,
	CONSTRAINT pk_chips PRIMARY KEY ( chipid ),
	CONSTRAINT idx_chips UNIQUE ( chip )
 );

CREATE INDEX idx_chips_0 ON racetest.chips ( organizerid );

ALTER TABLE racetest.chips COMMENT 'Canonical list of chips and if they are loaners.';

ALTER TABLE racetest.chips MODIFY chipid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify chip table entry';

ALTER TABLE racetest.chips MODIFY chip VARCHAR( 20 ) COMMENT 'As received or entered manually.';

ALTER TABLE racetest.chips MODIFY loaner BOOL COMMENT 'Set to true if this is a loaner chip.';

ALTER TABLE racetest.chips MODIFY shortname VARCHAR( 10 ) NOT NULL COMMENT 'If the loaner flag is set then this is the optional Short Display Name.';

ALTER TABLE racetest.chips MODIFY totalactivations INT COMMENT 'Total number of recorded activations.';

ALTER TABLE racetest.chips MODIFY currentactivations INT COMMENT 'Number of activations since most recent battery change.';

ALTER TABLE racetest.chips MODIFY replacebattery BOOL COMMENT 'Set if percentage of BATT OK count was below 90% in a lapset.';

ALTER TABLE racetest.chips MODIFY batteryreplaced DATE COMMENT 'Set to the date the battery was replaced.';

CREATE TABLE racetest.events ( 
	eventid              INT NOT NULL AUTO_INCREMENT,
	venueid              INT,
	starttime            TIMESTAMP NOT NULL,
	finishtime           TIMESTAMP,
	description          VARCHAR( 100 ),
	start                INT,
	category             VARCHAR( 20 ),
	eventtype            VARCHAR( 20 ),
	laps                 INT,
	sprints              INT,
	CONSTRAINT pk_events PRIMARY KEY ( eventid ),
	CONSTRAINT idx_events_0 UNIQUE ( venueid, starttime, description )
 );

CREATE INDEX idx_events ON racetest.events ( venueid, starttime, finishtime, description );

ALTER TABLE racetest.events COMMENT 'List of workouts, races, at a venue.n';

ALTER TABLE racetest.events MODIFY eventid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify event table entry';

ALTER TABLE racetest.events MODIFY description VARCHAR( 100 ) COMMENT 'What the workout or race is.';

ALTER TABLE racetest.events MODIFY start INT COMMENT 'start number if a number of categories are in race';

ALTER TABLE racetest.events MODIFY category VARCHAR( 20 ) COMMENT 'Category of race, e.g. A/B/C or Cat 1/2, 3, 4.';

ALTER TABLE racetest.events MODIFY eventtype VARCHAR( 20 ) COMMENT 'Type of event, workout, track, road, timetrial.';

ALTER TABLE racetest.events MODIFY laps INT COMMENT 'number of laps in race';

ALTER TABLE racetest.events MODIFY sprints INT COMMENT 'number of sprints';

CREATE TABLE racetest.groupsets ( 
	groupsetid           INT NOT NULL AUTO_INCREMENT,
	venueid              INT,
	datestamp            DATETIME NOT NULL,
	lengthms             INT,
	gapms                INT,
	members              INT,
	CONSTRAINT pk_groupset PRIMARY KEY ( groupsetid ),
	CONSTRAINT idx_groupsets UNIQUE ( venueid, datestamp )
 );

CREATE TABLE racetest.lapsets ( 
	lapsetid             INT NOT NULL AUTO_INCREMENT,
	venueid              INT,
	chipid               INT,
	boxid                VARCHAR( 2 ),
	starttime            DATETIME NOT NULL,
	finishtime           DATETIME,
	totalms              INT,
	bestlapms            INT,
	laps                 INT,
	skippedcount         INT,
	corrections          INT,
	battery              INT,
	CONSTRAINT pk_workouts PRIMARY KEY ( lapsetid ),
	CONSTRAINT idx_workouts UNIQUE ( chipid, starttime )
 );

CREATE INDEX pk_workouts_0 ON racetest.lapsets ( starttime );

CREATE INDEX pk_workouts_1 ON racetest.lapsets ( finishtime );

ALTER TABLE racetest.lapsets COMMENT 'Summary of a set of laps (workout).';

ALTER TABLE racetest.lapsets MODIFY lapsetid INT NOT NULL AUTO_INCREMENT COMMENT 'uniquely identify lapset table entry';

ALTER TABLE racetest.lapsets MODIFY venueid INT COMMENT 'Where a workout took place.';

ALTER TABLE racetest.lapsets MODIFY chipid INT COMMENT 'The chip that recorded the data.';

ALTER TABLE racetest.lapsets MODIFY boxid VARCHAR( 2 ) COMMENT 'unique id if multiple timing decoders in use at an event';

ALTER TABLE racetest.lapsets MODIFY starttime DATETIME NOT NULL COMMENT 'when workout startedn';

ALTER TABLE racetest.lapsets MODIFY finishtime DATETIME COMMENT 'when workout finished (may be null)';

ALTER TABLE racetest.lapsets MODIFY totalms INT COMMENT 'length of workout in milli-seconds.';

ALTER TABLE racetest.lapsets MODIFY bestlapms INT COMMENT 'Best lap time in milli-seconds';

ALTER TABLE racetest.lapsets MODIFY laps INT COMMENT 'Number of laps recorded.';

ALTER TABLE racetest.lapsets MODIFY skippedcount INT COMMENT 'Total skipped lap count';

ALTER TABLE racetest.lapsets MODIFY corrections INT COMMENT 'Total corrections';

ALTER TABLE racetest.lapsets MODIFY battery INT COMMENT 'Total battery ';

CREATE TABLE racetest.health ( 
	healthid             INT NOT NULL AUTO_INCREMENT,
	chipid               INT,
	datestamp            DATE,
	activations          INT,
	battery              INT,
	skippedcount         INT,
	corrections          INT,
	batteryreplacedflag  BOOL,
	CONSTRAINT pk_chiphealth PRIMARY KEY ( healthid )
 );

CREATE INDEX idx_health ON racetest.health ( chipid );

ALTER TABLE racetest.health COMMENT 'This table summarizes chip health indicators by date.';

ALTER TABLE racetest.health MODIFY datestamp DATE COMMENT 'Date chip health recorded on.';

ALTER TABLE racetest.health MODIFY activations INT COMMENT 'Number of activations.';

ALTER TABLE racetest.health MODIFY battery INT COMMENT 'Total of battery flags.';

ALTER TABLE racetest.health MODIFY skippedcount INT COMMENT 'Total possibly skipped laps.';

ALTER TABLE racetest.health MODIFY corrections INT COMMENT 'Total of correction fields.';

CREATE TABLE racetest.chiphistory ( 
	chipid               INT NOT NULL,
	userid               INT NOT NULL,
	starttime            TIMESTAMP NOT NULL,
	finishtime           TIMESTAMP,
	CONSTRAINT idx_tags UNIQUE ( starttime, chipid )
 );

CREATE INDEX idx_tags_0 ON racetest.chiphistory ( userid );

CREATE INDEX pk_tags ON racetest.chiphistory ( chipid );

ALTER TABLE racetest.chiphistory COMMENT 'When a user used a chip.';

ALTER TABLE racetest.chiphistory MODIFY chipid INT NOT NULL COMMENT 'key to chip that was used in this period.';

ALTER TABLE racetest.chiphistory MODIFY userid INT NOT NULL COMMENT 'key for user that used the chip during this period.';

ALTER TABLE racetest.chiphistory MODIFY starttime TIMESTAMP NOT NULL COMMENT 'This record is valid as of this time (required.)';

ALTER TABLE racetest.chiphistory MODIFY finishtime TIMESTAMP COMMENT 'This entry is valid until this time (may be null.)';

CREATE TABLE racetest.laps ( 
	lapsetid             INT,
	groupsetid           INT,
	datestamp            DATETIME,
	lapnumber            INT,
	groupnumber          INT,
	finishms             INT NOT NULL,
	startms              INT,
	groupms              INT,
	lapms                INT,
	correction           INT,
	skippedflag          BOOL,
	battery              INT,
	CONSTRAINT idx_laps UNIQUE ( datestamp, lapsetid, lapnumber )
 );

CREATE INDEX idx_lapd_0 ON racetest.laps ( datestamp );

CREATE INDEX idx_lapd_2 ON racetest.laps ( lapsetid );

CREATE INDEX idx_laps_0 ON racetest.laps ( groupsetid );

ALTER TABLE racetest.laps COMMENT 'Per Lap Timing Data, as received from the timing system. ';

ALTER TABLE racetest.laps MODIFY lapsetid INT COMMENT 'All consecutive lap entries belonging to a single users workout are identified with the same lapsetid.n';

ALTER TABLE racetest.laps MODIFY datestamp DATETIME COMMENT 'When the timing record was recorded.';

ALTER TABLE racetest.laps MODIFY lapnumber INT COMMENT 'The lap number, where consecutive laps have been recorded, this is the lap number.n';

ALTER TABLE racetest.laps MODIFY groupnumber INT COMMENT 'A group of entries is where all consecutive entries are within the (venued specific) gaptime.';

ALTER TABLE racetest.laps MODIFY finishms INT NOT NULL COMMENT 'Absolute timestamp for timing data for the end of the lap. nThis is a required field.';

ALTER TABLE racetest.laps MODIFY startms INT COMMENT 'Optional field if this timing record represents a full lap. ';

ALTER TABLE racetest.laps MODIFY groupms INT COMMENT 'Optional field if this timing entry was part of a group passing the timing point.';

ALTER TABLE racetest.laps MODIFY lapms INT COMMENT 'Optional field representing the actual elapsed time for a lap if startms is valid.n';

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_users FOREIGN KEY ( userid ) REFERENCES racetest.users( userid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chips ADD CONSTRAINT fk_chips_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.events ADD CONSTRAINT fk_events_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.groupsets ADD CONSTRAINT fk_groupset_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_lapd_workouts FOREIGN KEY ( lapsetid ) REFERENCES racetest.lapsets( lapsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_laps_groupset FOREIGN KEY ( groupsetid ) REFERENCES racetest.groupsets( groupsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.lapsets ADD CONSTRAINT fk_workouts_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.lapsets ADD CONSTRAINT fk_workouts_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.venues ADD CONSTRAINT fk_venues_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.health ADD CONSTRAINT fk_health_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

