CREATE SCHEMA racetest;

CREATE TABLE racetest.organizers ( 
	organizerid          int  NOT NULL  AUTO_INCREMENT,
	organizer            varchar(20)  NOT NULL  ,
	description          varchar(100)    ,
	CONSTRAINT pk_organizers PRIMARY KEY ( organizerid ),
	CONSTRAINT idx_organizers UNIQUE ( organizer ) 
 );

ALTER TABLE racetest.organizers COMMENT 'List of  organizers that own venues, do events, loan chips.';

ALTER TABLE racetest.organizers MODIFY organizerid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify organizer table entry';

ALTER TABLE racetest.organizers MODIFY organizer varchar(20)  NOT NULL   COMMENT 'Short display name for organizer.';

ALTER TABLE racetest.organizers MODIFY description varchar(100)     COMMENT 'Long description for organizer.';

CREATE TABLE racetest.users ( 
	userid               int  NOT NULL  AUTO_INCREMENT,
	lastname             varchar(100)    ,
	firstname            varchar(100)    ,
	login                varchar(32)    ,
	email                varchar(200)    ,
	gender               varchar(1)    ,
	team                 varchar(100)    ,
	yob                  varchar(4)    ,
	ucicat               varchar(12)    ,
	abilitycat           varchar(20)    ,
	privacyflag          varchar(10)    ,
	strava               varchar(100)    ,
	ucicode              varchar(20)    ,
	CONSTRAINT pk_users PRIMARY KEY ( userid ),
	CONSTRAINT idx_users_lastname_firstname UNIQUE ( lastname, firstname ) 
 );

CREATE INDEX idx_users_login ON racetest.users ( login );

ALTER TABLE racetest.users COMMENT 'Self Administered information about users.';

ALTER TABLE racetest.users MODIFY userid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify user table entry';

ALTER TABLE racetest.users MODIFY ucicode varchar(20)     COMMENT 'UCI Code';

CREATE TABLE racetest.venues ( 
	venueid              int  NOT NULL  AUTO_INCREMENT,
	organizerid          int  NOT NULL  ,
	venue                varchar(20)  NOT NULL  ,
	description          varchar(100)  NOT NULL  ,
	distance             float    ,
	minspeed             float    ,
	maxspeed             float    ,
	gaptime              float    ,
	timezone             varchar(20)    ,
	activeflag           bool    ,
	CONSTRAINT pk_venues PRIMARY KEY ( venueid ),
	CONSTRAINT idx_venues_by_venue UNIQUE ( venue ) 
 );

CREATE INDEX idx_venues ON racetest.venues ( organizerid );

ALTER TABLE racetest.venues COMMENT 'list of locations that organizers run races at';

ALTER TABLE racetest.venues MODIFY venueid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify venue table entry';

ALTER TABLE racetest.venues MODIFY organizerid int  NOT NULL   COMMENT 'Organizer that uses this venue.';

ALTER TABLE racetest.venues MODIFY venue varchar(20)  NOT NULL   COMMENT 'Short display name for venue.';

ALTER TABLE racetest.venues MODIFY description varchar(100)  NOT NULL   COMMENT 'Description of the venue.';

ALTER TABLE racetest.venues MODIFY distance float     COMMENT 'in km of each lap';

ALTER TABLE racetest.venues MODIFY minspeed float     COMMENT 'minimum expected speed';

ALTER TABLE racetest.venues MODIFY maxspeed float     COMMENT 'maximum expected speed';

ALTER TABLE racetest.venues MODIFY gaptime float     COMMENT 'allowable gap in ms between riders in a group';

ALTER TABLE racetest.venues MODIFY timezone varchar(20)     COMMENT 'Timezone that the timing system generates TimeStamps in.';

ALTER TABLE racetest.venues MODIFY activeflag bool     COMMENT 'active venue';

CREATE TABLE racetest.chips ( 
	organizerid          int    ,
	chipid               int  NOT NULL  AUTO_INCREMENT,
	chip                 varchar(20)    ,
	loaner               bool    ,
	shortname            varchar(10)  NOT NULL  ,
	CONSTRAINT pk_chips PRIMARY KEY ( chipid ),
	CONSTRAINT idx_chips UNIQUE ( chip ) 
 );

CREATE INDEX idx_chips_0 ON racetest.chips ( organizerid );

ALTER TABLE racetest.chips COMMENT 'Canonical list of chips and if they are loaners.';

ALTER TABLE racetest.chips MODIFY chipid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify chip table entry';

ALTER TABLE racetest.chips MODIFY chip varchar(20)     COMMENT 'As received or entered manually.';

ALTER TABLE racetest.chips MODIFY loaner bool     COMMENT 'Set to true if this is a loaner chip.';

ALTER TABLE racetest.chips MODIFY shortname varchar(10)  NOT NULL   COMMENT 'If the loaner flag is set then this is the optional Short Display Name.';

CREATE TABLE racetest.events ( 
	eventid              int  NOT NULL  AUTO_INCREMENT,
	venueid              int    ,
	starttime            timestamp  NOT NULL  ,
	finishtime           timestamp    ,
	description          varchar(100)    ,
	start                int    ,
	category             varchar(20)    ,
	eventtype            varchar(20)    ,
	laps                 int    ,
	sprints              int    ,
	CONSTRAINT pk_events PRIMARY KEY ( eventid ),
	CONSTRAINT idx_events_0 UNIQUE ( venueid, starttime, description ) 
 );

CREATE INDEX idx_events ON racetest.events ( venueid, starttime, finishtime, description );

ALTER TABLE racetest.events COMMENT 'List of workouts, races, at a venue.
';

ALTER TABLE racetest.events MODIFY eventid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify event table entry';

ALTER TABLE racetest.events MODIFY description varchar(100)     COMMENT 'What the workout or race is.';

ALTER TABLE racetest.events MODIFY start int     COMMENT 'start number if a number of categories are in race';

ALTER TABLE racetest.events MODIFY category varchar(20)     COMMENT 'Category of race, e.g. A/B/C or Cat 1/2, 3, 4.';

ALTER TABLE racetest.events MODIFY eventtype varchar(20)     COMMENT 'Type of event, workout, track, road, timetrial.';

ALTER TABLE racetest.events MODIFY laps int     COMMENT 'number of laps in race';

ALTER TABLE racetest.events MODIFY sprints int     COMMENT 'number of sprints';

CREATE TABLE racetest.groupsets ( 
	groupsetid           int  NOT NULL  AUTO_INCREMENT,
	venueid              int    ,
	datestamp            datetime  NOT NULL  ,
	lengthms             int    ,
	gapms                int    ,
	members              int    ,
	CONSTRAINT pk_groupset PRIMARY KEY ( groupsetid ),
	CONSTRAINT idx_groupsets UNIQUE ( venueid, datestamp ) 
 );

CREATE TABLE racetest.races ( 
	raceid               int  NOT NULL  AUTO_INCREMENT,
	groupsetid           int    ,
	description          long varchar    ,
	startms              int    ,
	racetype             varchar(20)    ,
	entries              int    ,
	lastlap              int   DEFAULT 0 ,
	racelaps             int   DEFAULT 0 ,
	CONSTRAINT pk_races PRIMARY KEY ( raceid ),
	CONSTRAINT idx_races UNIQUE ( groupsetid ) 
 );

CREATE TABLE racetest.workouts ( 
	workoutid            int  NOT NULL  AUTO_INCREMENT,
	venueid              int    ,
	chipid               int    ,
	boxid                varchar(2)    ,
	starttime            datetime  NOT NULL  ,
	finishtime           datetime    ,
	totalms              int    ,
	bestlapms            int    ,
	laps                 int    ,
	skippedcount         int    ,
	corrections          int    ,
	battery              int    ,
	CONSTRAINT pk_workouts PRIMARY KEY ( workoutid ),
	CONSTRAINT idx_workouts UNIQUE ( chipid, starttime ) 
 );

CREATE INDEX pk_workouts_0 ON racetest.workouts ( starttime );

CREATE INDEX pk_workouts_1 ON racetest.workouts ( finishtime );

ALTER TABLE racetest.workouts COMMENT 'Summary of a set of laps (workout).';

ALTER TABLE racetest.workouts MODIFY workoutid int  NOT NULL  AUTO_INCREMENT COMMENT 'uniquely identify workout table entry';

ALTER TABLE racetest.workouts MODIFY venueid int     COMMENT 'Where a workout took place.';

ALTER TABLE racetest.workouts MODIFY chipid int     COMMENT 'The chip that recorded the data.';

ALTER TABLE racetest.workouts MODIFY boxid varchar(2)     COMMENT 'unique id if multiple timing decoders in use at an event';

ALTER TABLE racetest.workouts MODIFY starttime datetime  NOT NULL   COMMENT 'when workout started
';

ALTER TABLE racetest.workouts MODIFY finishtime datetime     COMMENT 'when workout finished (may be null)';

ALTER TABLE racetest.workouts MODIFY totalms int     COMMENT 'length of workout in milli-seconds.';

ALTER TABLE racetest.workouts MODIFY bestlapms int     COMMENT 'Best lap time in milli-seconds';

ALTER TABLE racetest.workouts MODIFY laps int     COMMENT 'Number of laps recorded.';

ALTER TABLE racetest.workouts MODIFY skippedcount int     COMMENT 'Total skipped lap count';

ALTER TABLE racetest.workouts MODIFY corrections int     COMMENT 'Total corrections';

ALTER TABLE racetest.workouts MODIFY battery int     COMMENT 'Total battery ';

CREATE TABLE racetest.batteryhistory ( 
	chipid               int  NOT NULL  ,
	batterydate          date    ,
	batteryid            int  NOT NULL  AUTO_INCREMENT,
	CONSTRAINT idx_batteryhistory UNIQUE ( chipid, batterydate ) ,
	CONSTRAINT pk_batteryhistory PRIMARY KEY ( batteryid )
 );

ALTER TABLE racetest.batteryhistory COMMENT 'When where batteries replaced.';

ALTER TABLE racetest.batteryhistory MODIFY batterydate date     COMMENT 'When the battery was replaced';

ALTER TABLE racetest.batteryhistory MODIFY batteryid int  NOT NULL  AUTO_INCREMENT COMMENT 'Useful for debugging the queries, can be removed.';

CREATE TABLE racetest.chiphistory ( 
	chipid               int  NOT NULL  ,
	userid               int  NOT NULL  ,
	starttime            timestamp  NOT NULL  ,
	finishtime           timestamp    ,
	location             varchar(100)    ,
	CONSTRAINT idx_tags UNIQUE ( starttime, chipid ) 
 );

CREATE INDEX idx_tags_0 ON racetest.chiphistory ( userid );

CREATE INDEX pk_tags ON racetest.chiphistory ( chipid );

ALTER TABLE racetest.chiphistory COMMENT 'When a user used a chip.';

ALTER TABLE racetest.chiphistory MODIFY chipid int  NOT NULL   COMMENT 'key to chip that was used in this period.';

ALTER TABLE racetest.chiphistory MODIFY userid int  NOT NULL   COMMENT 'key for user that used the chip during this period.';

ALTER TABLE racetest.chiphistory MODIFY starttime timestamp  NOT NULL   COMMENT 'This record is valid as of this time (required.)';

ALTER TABLE racetest.chiphistory MODIFY finishtime timestamp     COMMENT 'This entry is valid until this time (may be null.)';

CREATE TABLE racetest.laps ( 
	lapid                int  NOT NULL  AUTO_INCREMENT,
	workoutid            int    ,
	groupsetid           int    ,
	datestamp            datetime    ,
	groupnumber          int    ,
	workoutlap           int    ,
	finishms             int  NOT NULL  ,
	startms              int    ,
	groupms              int    ,
	lapms                int    ,
	correction           int    ,
	skippedflag          bool    ,
	battery              int    ,
	CONSTRAINT idx_laps UNIQUE ( datestamp, workoutid, workoutlap ) ,
	CONSTRAINT pk_laps PRIMARY KEY ( lapid )
 );

CREATE INDEX idx_lapd_0 ON racetest.laps ( datestamp );

CREATE INDEX idx_lapd_2 ON racetest.laps ( workoutid );

CREATE INDEX idx_laps_0 ON racetest.laps ( groupsetid );

ALTER TABLE racetest.laps COMMENT 'Per Lap Timing Data, as received from the timing system. ';

ALTER TABLE racetest.laps MODIFY workoutid int     COMMENT 'All consecutive lap entries belonging to a single users workout are identified with the same worksetid.
';

ALTER TABLE racetest.laps MODIFY datestamp datetime     COMMENT 'When the timing record was recorded.';

ALTER TABLE racetest.laps MODIFY groupnumber int     COMMENT '1..N, The position within a recorded group set.';

ALTER TABLE racetest.laps MODIFY workoutlap int     COMMENT '1..N The lap number within the workout.';

ALTER TABLE racetest.laps MODIFY finishms int  NOT NULL   COMMENT 'Absolute timestamp for timing data for the end of the lap. 
This is a required field.';

ALTER TABLE racetest.laps MODIFY startms int     COMMENT 'Optional field if this timing record represents a full lap. ';

ALTER TABLE racetest.laps MODIFY groupms int     COMMENT 'Optional field if this timing entry was part of a group passing the timing point.';

ALTER TABLE racetest.laps MODIFY lapms int     COMMENT 'Optional field representing the actual elapsed time for a lap if startms is valid.
';

CREATE TABLE racetest.raceinfo ( 
	raceinfoid           int  NOT NULL  AUTO_INCREMENT,
	raceid               int    ,
	finishms             int    ,
	lapnumber            int  NOT NULL  ,
	racelap              int    ,
	lapstogo             int  NOT NULL DEFAULT 0 ,
	neutralflag          bool   DEFAULT 0 ,
	startflag            bool   DEFAULT 0 ,
	bellflag             bool   DEFAULT 0 ,
	finishflag           bool   DEFAULT 0 ,
	premeflag            bool   DEFAULT 0 ,
	sprintflag           bool   DEFAULT 0 ,
	CONSTRAINT pk_racelaps PRIMARY KEY ( raceinfoid ),
	CONSTRAINT idx_racelaps_0 UNIQUE ( raceid, lapnumber ) 
 );

CREATE INDEX idx_racelaps ON racetest.raceinfo ( raceid );

ALTER TABLE racetest.raceinfo COMMENT 'This records information about each lap of a race.';

ALTER TABLE racetest.raceinfo MODIFY raceid int     COMMENT 'The race this is part of.';

ALTER TABLE racetest.raceinfo MODIFY lapnumber int  NOT NULL   COMMENT '1..N The actual lap number.';

ALTER TABLE racetest.raceinfo MODIFY racelap int     COMMENT 'The official race lap, zero for neutral laps.';

ALTER TABLE racetest.raceinfo MODIFY lapstogo int  NOT NULL DEFAULT 0  COMMENT 'What the riders saw when this lap was recorded.';

ALTER TABLE racetest.raceinfo MODIFY neutralflag bool   DEFAULT 0  COMMENT 'Neutral lap, does not count against official laps.';

ALTER TABLE racetest.raceinfo MODIFY startflag bool   DEFAULT 0  COMMENT 'Set for the "zero" lap, i.e. when riders crossed the start line to start the race. ';

ALTER TABLE racetest.raceinfo MODIFY bellflag bool   DEFAULT 0  COMMENT 'If the bell was rung as the riders went by the start / finish line.
';

ALTER TABLE racetest.raceinfo MODIFY finishflag bool   DEFAULT 0  COMMENT 'The riders where sprinting for the finish when this was recorded.';

ALTER TABLE racetest.raceinfo MODIFY premeflag bool   DEFAULT 0  COMMENT 'The riders where sprinting for a preme when this lap was recorded.';

ALTER TABLE racetest.raceinfo MODIFY sprintflag bool   DEFAULT 0  COMMENT 'The riders where sprinting for points when this lap was recorded.';

CREATE TABLE racetest.racelaps ( 
	lapid                int    ,
	raceinfoid           int    ,
	finishorder          int   DEFAULT 0 ,
	missedflag           int    ,
	CONSTRAINT idx_racelaps_1 UNIQUE ( lapid, raceinfoid ) 
 );

CREATE INDEX idx_racelaps_2 ON racetest.racelaps ( lapid );

CREATE INDEX idx_racelaps_3 ON racetest.racelaps ( raceinfoid );

ALTER TABLE racetest.racelaps COMMENT 'This is used to join specific laps to a race. A separate table is used as not all laps are part of races.';

ALTER TABLE racetest.racelaps MODIFY missedflag int     COMMENT 'set if there was a missed lap after this one (timing system did not record a time)';

ALTER TABLE racetest.batteryhistory ADD CONSTRAINT fk_batteryhistory_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_users FOREIGN KEY ( userid ) REFERENCES racetest.users( userid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chiphistory ADD CONSTRAINT fk_tags_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.chips ADD CONSTRAINT fk_chips_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.events ADD CONSTRAINT fk_events_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.groupsets ADD CONSTRAINT fk_groupset_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_lapd_workouts FOREIGN KEY ( workoutid ) REFERENCES racetest.workouts( workoutid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.laps ADD CONSTRAINT fk_laps_groupset FOREIGN KEY ( groupsetid ) REFERENCES racetest.groupsets( groupsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.raceinfo ADD CONSTRAINT fk_racelaps_races FOREIGN KEY ( raceid ) REFERENCES racetest.races( raceid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.racelaps ADD CONSTRAINT fk_racelaps_laps FOREIGN KEY ( lapid ) REFERENCES racetest.laps( lapid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.racelaps ADD CONSTRAINT fk_racelaps_raceinfo FOREIGN KEY ( raceinfoid ) REFERENCES racetest.raceinfo( raceinfoid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.races ADD CONSTRAINT fk_races_groupsets FOREIGN KEY ( groupsetid ) REFERENCES racetest.groupsets( groupsetid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.venues ADD CONSTRAINT fk_venues_organizers FOREIGN KEY ( organizerid ) REFERENCES racetest.organizers( organizerid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.workouts ADD CONSTRAINT fk_workouts_chips FOREIGN KEY ( chipid ) REFERENCES racetest.chips( chipid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE racetest.workouts ADD CONSTRAINT fk_workouts_venues FOREIGN KEY ( venueid ) REFERENCES racetest.venues( venueid ) ON DELETE NO ACTION ON UPDATE NO ACTION;

