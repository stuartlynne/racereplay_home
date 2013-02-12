CREATE SCHEMA racetest;

CREATE TABLE racetest.organizers ( 
	organizerid          INT  NOT NULL  AUTO_INCREMENT,
	organizer            VARCHAR( 20 )  NOT NULL  ,
	description          VARCHAR( 100 )    ,
	CONSTRAINT pk_organizers PRIMARY KEY ( organizerid ),
	
 );

ALTER TABLE racetest.organizers COMMENT 'List of  organizers that own venues, do events, loan chips.';

ALTER TABLE racetest.organizers MODIFY organizerid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify organizer table entry';

ALTER TABLE racetest.organizers MODIFY organizer VARCHAR( 20 )  NOT NULL   COMMENT 'Short display name for organizer.';

ALTER TABLE racetest.organizers MODIFY description VARCHAR( 100 )     COMMENT 'Long description for organizer.';

CREATE TABLE racetest.users ( 
	userid               INT  NOT NULL  AUTO_INCREMENT,
	lastname             VARCHAR( 100 )    ,
	firstname            VARCHAR( 100 )    ,
	login                VARCHAR( 32 )    ,
	email                VARCHAR( 200 )    ,
	gender               VARCHAR( 1 )    ,
	team                 VARCHAR( 100 )    ,
	yob                  VARCHAR( 4 )    ,
	ucicat               VARCHAR( 12 )    ,
	abilitycat           VARCHAR( 20 )    ,
	privacyflag          VARCHAR( 10 )    ,
	strava               VARCHAR( 100 )    ,
	ucicode              VARCHAR( 20 )    ,
	CONSTRAINT pk_users PRIMARY KEY ( userid ),
	
 );

CREATE INDEX idx_users_login ON racetest.users ( login );

ALTER TABLE racetest.users COMMENT 'Self Administered information about users.';

ALTER TABLE racetest.users MODIFY userid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify user table entry';

ALTER TABLE racetest.users MODIFY ucicode VARCHAR( 20 )     COMMENT 'UCI Code';

CREATE TABLE racetest.venues ( 
	venueid              INT  NOT NULL  AUTO_INCREMENT,
	organizerid          INT  NOT NULL  ,
	venue                VARCHAR( 20 )  NOT NULL  ,
	description          VARCHAR( 100 )  NOT NULL  ,
	distance             FLOAT    ,
	minspeed             FLOAT    ,
	maxspeed             FLOAT    ,
	gaptime              FLOAT    ,
	timezone             VARCHAR( 20 )    ,
	activeflag           BOOL    ,
	CONSTRAINT pk_venues PRIMARY KEY ( venueid ),
	
 );

CREATE INDEX idx_venues ON racetest.venues ( organizerid );

ALTER TABLE racetest.venues COMMENT 'list of locations that organizers run races at';

ALTER TABLE racetest.venues MODIFY venueid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify venue table entry';

ALTER TABLE racetest.venues MODIFY organizerid INT  NOT NULL   COMMENT 'Organizer that uses this venue.';

ALTER TABLE racetest.venues MODIFY venue VARCHAR( 20 )  NOT NULL   COMMENT 'Short display name for venue.';

ALTER TABLE racetest.venues MODIFY description VARCHAR( 100 )  NOT NULL   COMMENT 'Description of the venue.';

ALTER TABLE racetest.venues MODIFY distance FLOAT     COMMENT 'in km of each lap';

ALTER TABLE racetest.venues MODIFY minspeed FLOAT     COMMENT 'minimum expected speed';

ALTER TABLE racetest.venues MODIFY maxspeed FLOAT     COMMENT 'maximum expected speed';

ALTER TABLE racetest.venues MODIFY gaptime FLOAT     COMMENT 'allowable gap in ms between riders in a group';

ALTER TABLE racetest.venues MODIFY timezone VARCHAR( 20 )     COMMENT 'Timezone that the timing system generates TimeStamps in.';

ALTER TABLE racetest.venues MODIFY activeflag BOOL     COMMENT 'active venue';

CREATE TABLE racetest.chips ( 
	organizerid          INT    ,
	chipid               INT  NOT NULL  AUTO_INCREMENT,
	chip                 VARCHAR( 20 )    ,
	loaner               BOOL    ,
	shortname            VARCHAR( 10 )  NOT NULL  ,
	totalactivations     INT    ,
	currentactivations   INT    ,
	replacebattery       BOOL    ,
	batteryreplaced      DATE    ,
	CONSTRAINT pk_chips PRIMARY KEY ( chipid ),
	
 );

CREATE INDEX idx_chips_0 ON racetest.chips ( organizerid );

ALTER TABLE racetest.chips COMMENT 'Canonical list of chips and if they are loaners.';

ALTER TABLE racetest.chips MODIFY chipid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify chip table entry';

ALTER TABLE racetest.chips MODIFY chip VARCHAR( 20 )     COMMENT 'As received or entered manually.';

ALTER TABLE racetest.chips MODIFY loaner BOOL     COMMENT 'Set to true if this is a loaner chip.';

ALTER TABLE racetest.chips MODIFY shortname VARCHAR( 10 )  NOT NULL   COMMENT 'If the loaner flag is set then this is the optional Short Display Name.';

ALTER TABLE racetest.chips MODIFY totalactivations INT     COMMENT 'Total number of recorded activations.';

ALTER TABLE racetest.chips MODIFY currentactivations INT     COMMENT 'Number of activations since most recent battery change.';

ALTER TABLE racetest.chips MODIFY replacebattery BOOL     COMMENT 'Set if percentage of BATT OK count was below 90% in a workout.';

ALTER TABLE racetest.chips MODIFY batteryreplaced DATE     COMMENT 'Set to the date the battery was replaced.';

CREATE TABLE racetest.events ( 
	eventid              INT  NOT NULL  AUTO_INCREMENT,
	venueid              INT    ,
	starttime            TIMESTAMP  NOT NULL  ,
	finishtime           TIMESTAMP    ,
	description          VARCHAR( 100 )    ,
	start                INT    ,
	category             VARCHAR( 20 )    ,
	eventtype            VARCHAR( 20 )    ,
	laps                 INT    ,
	sprints              INT    ,
	CONSTRAINT pk_events PRIMARY KEY ( eventid ),
	
 );

CREATE INDEX idx_events ON racetest.events ( venueid, starttime, finishtime, description );

ALTER TABLE racetest.events COMMENT 'List of workouts, races, at a venue.n';

ALTER TABLE racetest.events MODIFY eventid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify event table entry';

ALTER TABLE racetest.events MODIFY description VARCHAR( 100 )     COMMENT 'What the workout or race is.';

ALTER TABLE racetest.events MODIFY start INT     COMMENT 'start number if a number of categories are in race';

ALTER TABLE racetest.events MODIFY category VARCHAR( 20 )     COMMENT 'Category of race, e.g. A/B/C or Cat 1/2, 3, 4.';

ALTER TABLE racetest.events MODIFY eventtype VARCHAR( 20 )     COMMENT 'Type of event, workout, track, road, timetrial.';

ALTER TABLE racetest.events MODIFY laps INT     COMMENT 'number of laps in race';

ALTER TABLE racetest.events MODIFY sprints INT     COMMENT 'number of sprints';

CREATE TABLE racetest.groupsets ( 
	groupsetid           INT  NOT NULL  AUTO_INCREMENT,
	venueid              INT    ,
	datestamp            DATETIME  NOT NULL  ,
	lengthms             INT    ,
	gapms                INT    ,
	members              INT    ,
	CONSTRAINT pk_groupset PRIMARY KEY ( groupsetid ),
	
 );

CREATE TABLE racetest.health ( 
	healthid             INT  NOT NULL  AUTO_INCREMENT,
	chipid               INT    ,
	datestamp            DATE    ,
	activations          INT    ,
	battery              INT    ,
	skippedcount         INT    ,
	corrections          INT    ,
	batteryreplacedflag  BOOL    ,
	CONSTRAINT pk_chiphealth PRIMARY KEY ( healthid )
 );

CREATE INDEX idx_health ON racetest.health ( chipid );

ALTER TABLE racetest.health COMMENT 'This table summarizes chip health indicators by date.';

ALTER TABLE racetest.health MODIFY datestamp DATE     COMMENT 'Date chip health recorded on.';

ALTER TABLE racetest.health MODIFY activations INT     COMMENT 'Number of activations.';

ALTER TABLE racetest.health MODIFY battery INT     COMMENT 'Total of battery flags.';

ALTER TABLE racetest.health MODIFY skippedcount INT     COMMENT 'Total possibly skipped laps.';

ALTER TABLE racetest.health MODIFY corrections INT     COMMENT 'Total of correction fields.';

CREATE TABLE racetest.races ( 
	raceid               INT  NOT NULL  AUTO_INCREMENT,
	groupsetid           INT    ,
	description          LONG VARCHAR    ,
	startms              INT    ,
	racetype             VARCHAR( 20 )    ,
	entries              INT    ,
	lastlap              INT   DEFAULT 0 ,
	CONSTRAINT pk_races PRIMARY KEY ( raceid ),
	
 );

CREATE TABLE racetest.workouts ( 
	workoutid            INT  NOT NULL  AUTO_INCREMENT,
	venueid              INT    ,
	chipid               INT    ,
	boxid                VARCHAR( 2 )    ,
	starttime            DATETIME  NOT NULL  ,
	finishtime           DATETIME    ,
	totalms              INT    ,
	bestlapms            INT    ,
	laps                 INT    ,
	skippedcount         INT    ,
	corrections          INT    ,
	battery              INT    ,
	CONSTRAINT pk_workouts PRIMARY KEY ( workoutid ),
	
 );

CREATE INDEX pk_workouts_0 ON racetest.workouts ( starttime );

CREATE INDEX pk_workouts_1 ON racetest.workouts ( finishtime );

ALTER TABLE racetest.workouts COMMENT 'Summary of a set of laps (workout).';

ALTER TABLE racetest.workouts MODIFY workoutid INT  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify workout table entry';

ALTER TABLE racetest.workouts MODIFY venueid INT     COMMENT 'Where a workout took place.';

ALTER TABLE racetest.workouts MODIFY chipid INT     COMMENT 'The chip that recorded the data.';

ALTER TABLE racetest.workouts MODIFY boxid VARCHAR( 2 )     COMMENT 'unique id if multiple timing decoders in use at an event';

ALTER TABLE racetest.workouts MODIFY starttime DATETIME  NOT NULL   COMMENT 'when workout startedn';

ALTER TABLE racetest.workouts MODIFY finishtime DATETIME     COMMENT 'when workout finished (may be null)';

ALTER TABLE racetest.workouts MODIFY totalms INT     COMMENT 'length of workout in milli-seconds.';

ALTER TABLE racetest.workouts MODIFY bestlapms INT     COMMENT 'Best lap time in milli-seconds';

ALTER TABLE racetest.workouts MODIFY laps INT     COMMENT 'Number of laps recorded.';

ALTER TABLE racetest.workouts MODIFY skippedcount INT     COMMENT 'Total skipped lap count';

ALTER TABLE racetest.workouts MODIFY corrections INT     COMMENT 'Total corrections';

ALTER TABLE racetest.workouts MODIFY battery INT     COMMENT 'Total battery ';

CREATE TABLE racetest.chiphistory ( 
	chipid               INT  NOT NULL  ,
	userid               INT  NOT NULL  ,
	starttime            TIMESTAMP  NOT NULL  ,
	finishtime           TIMESTAMP    ,
	
 );

CREATE INDEX idx_tags_0 ON racetest.chiphistory ( userid );

CREATE INDEX pk_tags ON racetest.chiphistory ( chipid );

ALTER TABLE racetest.chiphistory COMMENT 'When a user used a chip.';

ALTER TABLE racetest.chiphistory MODIFY chipid INT  NOT NULL   COMMENT 'key to chip that was used in this period.';

ALTER TABLE racetest.chiphistory MODIFY userid INT  NOT NULL   COMMENT 'key for user that used the chip during this period.';

ALTER TABLE racetest.chiphistory MODIFY starttime TIMESTAMP  NOT NULL   COMMENT 'This record is valid as of this time (required.)';

ALTER TABLE racetest.chiphistory MODIFY finishtime TIMESTAMP     COMMENT 'This entry is valid until this time (may be null.)';

CREATE TABLE racetest.laps ( 
	lapid                INT  NOT NULL  AUTO_INCREMENT,
	workoutid            INT    ,
	groupsetid           INT    ,
	datestamp            DATETIME    ,
	groupnumber          INT    ,
	workoutlap           INT    ,
	finishms             INT  NOT NULL  ,
	startms              INT    ,
	groupms              INT    ,
	lapms                INT    ,
	correction           INT    ,
	skippedflag          BOOL    ,
	battery              INT    ,
	,
	CONSTRAINT pk_laps PRIMARY KEY ( lapid )
 );

CREATE INDEX idx_lapd_0 ON racetest.laps ( datestamp );

CREATE INDEX idx_lapd_2 ON racetest.laps ( workoutid );

CREATE INDEX idx_laps_0 ON racetest.laps ( groupsetid );

ALTER TABLE racetest.laps COMMENT 'Per Lap Timing Data, as received from the timing system. ';

ALTER TABLE racetest.laps MODIFY workoutid INT     COMMENT 'All consecutive lap entries belonging to a single users workout are identified with the same worksetid.n';

ALTER TABLE racetest.laps MODIFY datestamp DATETIME     COMMENT 'When the timing record was recorded.';

ALTER TABLE racetest.laps MODIFY groupnumber INT     COMMENT '1..N, The position within a recorded group set.';

ALTER TABLE racetest.laps MODIFY workoutlap INT     COMMENT '1..N The lap number within the workout.';

ALTER TABLE racetest.laps MODIFY finishms INT  NOT NULL   COMMENT 'Absolute timestamp for timing data for the end of the lap. nThis is a required field.';

ALTER TABLE racetest.laps MODIFY startms INT     COMMENT 'Optional field if this timing record represents a full lap. ';

ALTER TABLE racetest.laps MODIFY groupms INT     COMMENT 'Optional field if this timing entry was part of a group passing the timing point.';

ALTER TABLE racetest.laps MODIFY lapms INT     COMMENT 'Optional field representing the actual elapsed time for a lap if startms is valid.n';

CREATE TABLE racetest.raceinfo ( 
	raceinfoid           INT  NOT NULL  AUTO_INCREMENT,
	raceid               INT    ,
	finishms             INT    ,
	lapnumber            INT  NOT NULL  ,
	racelap              INT    ,
	lapstogo             INT  NOT NULL DEFAULT 0 ,
	neutralflag          BOOL   DEFAULT 0 ,
	startflag            BOOL   DEFAULT 0 ,
	bellflag             BOOL   DEFAULT 0 ,
	sprintflag           BOOL   DEFAULT 0 ,
	premeflag            BOOL   DEFAULT 0 ,
	finishflag           BOOL   DEFAULT 0 ,
	CONSTRAINT pk_racelaps PRIMARY KEY ( raceinfoid ),
	
 );

CREATE INDEX idx_racelaps ON racetest.raceinfo ( raceid );

ALTER TABLE racetest.raceinfo COMMENT 'This records information about each lap of a race.';

ALTER TABLE racetest.raceinfo MODIFY raceid INT     COMMENT 'The race this is part of.';

ALTER TABLE racetest.raceinfo MODIFY lapnumber INT  NOT NULL   COMMENT '1..N The actual lap number.';

ALTER TABLE racetest.raceinfo MODIFY racelap INT     COMMENT 'The official race lap, zero for neutral laps.';

ALTER TABLE racetest.raceinfo MODIFY lapstogo INT  NOT NULL DEFAULT 0  COMMENT 'What the riders saw when this lap was recorded.';

ALTER TABLE racetest.raceinfo MODIFY neutralflag BOOL   DEFAULT 0  COMMENT 'Neutral lap, does not count against official laps.';

ALTER TABLE racetest.raceinfo MODIFY startflag BOOL   DEFAULT 0  COMMENT 'Set for the "zero" lap, i.e. when riders crossed the start line to start the race. ';

ALTER TABLE racetest.raceinfo MODIFY bellflag BOOL   DEFAULT 0  COMMENT 'If the bell was rung as the riders went by the start / finish line.n';

ALTER TABLE racetest.raceinfo MODIFY sprintflag BOOL   DEFAULT 0  COMMENT 'The riders where sprinting for points when this lap was recorded.';

ALTER TABLE racetest.raceinfo MODIFY premeflag BOOL   DEFAULT 0  COMMENT 'The riders where sprinting for a preme when this lap was recorded.';

ALTER TABLE racetest.raceinfo MODIFY finishflag BOOL   DEFAULT 0  COMMENT 'The riders where sprinting for the finish when this was recorded.';

CREATE TABLE racetest.racelaps ( 
	lapid                INT    ,
	raceinfoid           INT    ,
	finishorder          INT   DEFAULT 0 ,
	missedflag           INT    ,
	
 );

CREATE INDEX idx_racelaps_2 ON racetest.racelaps ( lapid );

CREATE INDEX idx_racelaps_3 ON racetest.racelaps ( raceinfoid );

ALTER TABLE racetest.racelaps COMMENT 'This is used to join specific laps to a race. A separate table is used as not all laps are part of races.';

ALTER TABLE racetest.racelaps MODIFY missedflag INT     COMMENT 'set if there was a missed lap after this one (timing system did not record a time)';

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_users FOREIGN KEY ( userid ) REFERENCES racetest.users( userid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chips ADD CONSTRAINT fk_chips_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.events ADD CONSTRAINT fk_events_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.groupsets ADD CONSTRAINT fk_groupset_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.health ADD CONSTRAINT fk_health_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_lapd_workouts FOREIGN KEY ( workoutid ) REFERENCES racetest.workouts( workoutid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_laps_groupset FOREIGN KEY ( groupsetid ) REFERENCES racetest.groupsets( groupsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.raceinfo ADD CONSTRAINT fk_racelaps_races FOREIGN KEY ( raceid ) REFERENCES racetest.races( raceid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.races ADD CONSTRAINT fk_races_groupsets FOREIGN KEY ( groupsetid ) REFERENCES racetest.groupsets( groupsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.venues ADD CONSTRAINT fk_venues_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.workouts ADD CONSTRAINT fk_workouts_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.workouts ADD CONSTRAINT fk_workouts_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.racelaps ADD CONSTRAINT fk_racelaps_laps FOREIGN KEY ( lapid ) REFERENCES racetest.laps( lapid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.racelaps ADD CONSTRAINT fk_racelaps_raceinfo FOREIGN KEY ( raceinfoid ) REFERENCES racetest.raceinfo( raceinfoid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

