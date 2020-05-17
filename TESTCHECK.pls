create or replace PACKAGE BODY testCheck AS

   
    
    PROCEDURE LoadDateToTracksTable(tableName IN NVARCHAR2) as
    sql_str VARCHAR2(2000);
    BEGIN
        sql_str := 'CREATE OR REPLACE VIEW vvv_tracks as
                            SELECT 
                            DDATE as DDATE,
                            ROUTE_NUMBER as ROUTE_NUMBER,
                            ROUTE_VARIANT as ROUTE_VARIANT,
                            ROUTE_NAME as ROUTE_NAME, 
                            CARRIER_BOARD_NUM as CARRIER_BOARD_NUM,
                            CARRIER_NAME as CARRIER_NAME,
                            TRANSPORT_NAME as TRANSPORT_NAME,
                            ID_TRANSPORT_ASUGPT as ID_TRANSPORT_ASUGPT,
                            ORDER_NUM_ASUGPT as ORDER_NUM_ASUGPT,
                            TRIP_NUM_ASUGPT as TRIP_NUM_ASUGPT,
                            STOP_TIME_REAL as STOP_TIME_REAL,
                            STOP_TIME_PLAN as STOP_TIME_PLAN,
                            STOP_NAME_BEFORE as STOP_NAME_BEFORE,
                            ID_STOP_BEFORE as ID_STOP_BEFORE,
                            STOP_NAME as STOP_NAME,
                            ID_STOP as ID_STOP,
                            ROUND(DISTANCE_BACK * 1000) as DISTANCE_BACK,
                            ROUND(DISTANCE_BACK_NORMATIVE * 1000) as DISTANCE_BACK_NORMATIVE,
                            TRIP_TYPE as TRIP_TYPE,
                            STOP_NUMBER as STOP_NUMBER
                            FROM ' || tableName;
        EXECUTE IMMEDIATE sql_str;
        
    END LoadDateToTracksTable;
    
      
    PROCEDURE CreateTable_LikeTracks (tableName in NVARCHAR2) as
    sql_str VARCHAR2(2000);
    BEGIN
        sql_str := 'CREATE TABLE ' || tableName || ' (
                        DDATE NVARCHAR2(1000),
                        ROUTE_NUMBER NVARCHAR2(1000),
                        ROUTE_VARIANT INT,
                        ROUTE_NAME NVARCHAR2(1000),
                        CARRIER_BOARD_NUM NVARCHAR2(1000),
                        CARRIER_NAME NVARCHAR2(1000),
                        TRANSPORT_NAME NVARCHAR2(1000),
                        ID_TRANSPORT_ASUGPT INT,
                        ORDER_NUM_ASUGPT INT,
                        TRIP_NUM_ASUGPT INT,
                        STOP_TIME_REAL NVARCHAR2(1000),
                        STOP_TIME_PLAN NVARCHAR2(1000),
                        STOP_NAME_BEFORE NVARCHAR2(1000),
                        ID_STOP_BEFORE INT,
                        STOP_NAME NVARCHAR2(1000),
                        ID_STOP INT,
                        DISTANCE_BACK FLOAT,
                        DISTANCE_BACK_NORMATIVE FLOAT,
                        TRIP_TYPE NVARCHAR2(1000),
                        STOP_NUMBER INT
                        )';
                        
        EXECUTE IMMEDIATE sql_str;
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        sql_str :=  'TRUNCATE TABLE ' ||tableName;
        EXECUTE IMMEDIATE sql_str;
    
    END CreateTable_LikeTracks;
    
    
    PROCEDURE CreateCheckSpeedTable as
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE ttt_CheckSpeed (
                           DDATE NVARCHAR2(1000),
                           ROUTE_NUMBER NVARCHAR2(1000),
                           CARRIER_BOARD_NUM NVARCHAR2(1000),
                            CARRIER_NAME NVARCHAR2(1000),
                            TRANSPORT_NAME NVARCHAR2(1000),
                            ID_TRANSPORT_ASUGPT INT,
                            ORDER_NUM_ASUGPT INT,
                            TRIP_NUM_ASUGPT INT,
                            STOP_TIME_PLAN NVARCHAR2(1000),
                            STOP_NAME_BEFORE NVARCHAR2(1000),
                            ID_STOP_BEFORE INT,
                            STOP_NAME NVARCHAR2(1000),
                            ID_STOP INT,
                            DISTANCE_BACK FLOAT,
                            DISTANCE_BACK_NORMATIVE FLOAT,
                            TRIP_TYPE NVARCHAR2(1000),
                            STOP_NUMBER INT,
                            STOP_TIME_REAL NVARCHAR2(1000),
                            STOP_TIME_REAL_BEFORE NVARCHAR2(1000),
                            TIME_BETWEEN INT,
                            SPEED FLOAT
                            )';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ttt_CheckSpeed';
    END CreateCheckSpeedTable;
    
    PROCEDURE CreateSpeedTable (maxStepsCount in INTEGER) as
    timeBetweenStops INT;
    flag int;
    SPEED FLOAT;
    STRB NVARCHAR2(1000);
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE ttt_Speed (
                            ID_STOP_BEFORE INT,
                            ID_STOP INT,
                            SPEED FLOAT
                            )';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ttt_Speed';
        flag := 0;
        FOR REC IN (
        SELECT * FROM TRACKS WHERE NOT(TRACKS.STOP_TIME_REAL IS NULL)) LOOP
            flag := flag + 1;
            SELECT MAX(TRACKS.STOP_TIME_REAL) INTO STRB FROM TRACKS WHERE TRACKS.ROUTE_NUMBER = REC.ROUTE_NUMBER AND TRACKS.DDATE = REC.DDATE AND NOT(TRACKS.STOP_TIME_REAL IS NULL) AND TRACKS.ID_STOP = REC.ID_STOP_BEFORE AND TRACKS.STOP_TIME_REAL < REC.STOp_TIME_REAL;
    
            timeBetweenStops := (to_date(rec.stop_time_real, 'dd.mm.rr hh24:mi:ss') - to_date(STRB, 'dd.mm.rr hh24:mi:ss')) * 24 * 60 * 60;
            SPEED := REC.DISTANCE_BACK  / TIMEBETWEENSTOPS;
            
             EXECUTE IMMEDIATE ' INSERT INTO ttt_Speed (ID_STOP_BEFORE, ID_STOP, SPEED) VALUES (:1, :2, :3)' USING REC.ID_STOP_BEFORE, REC.ID_STOP, SPEED;
            
            IF (flag >= maxStepsCount) THEN
                EXIT;
            END IF;
        END LOOP;
    END CreateSpeedTable;

    PROCEDURE CheckDistanceAndNormative (EPSILON IN INTEGER) as
    file_id UTL_FILE.file_type;       
    v TIMESTAMP;
    BEGIN
        
       CreateTable_LikeTracks('ttt_CheckDistanceAndNormTable');
       
       SELECT systimestamp INTO v FROM dual;
       file_id := UTL_FILE.FOPEN('ddd_TESTCHECKDIR', 'CheckDistanceAndDistanceNormative.csv', 'W');

       UTL_FILE.put_line(file_id, 'Checking that _back and distance_normative are equals:');        
       UTL_FILE.put_line(file_id, 'DDATE; ROUTE_NUMBER; ROUTE_VARIANT; ROUTE_NAME; CARRIER_BOARD_NUM; CARRIER_NAME; TRANSPORT_NAME; ID_TRANSPORT_ASUGPT; ORDER_NUM_ASUGPT; TRIP_NUM_ASUGPT; STOP_TIME_REAL; STOP_TIME_PLAN; STOP_NAME_BEFORE; ID_STOP_BEFORE; STOP_NAME; ID_STOP; DISTANCE_BACK; DISTANCE_BACK_NORMATIVE; TRIP_TYPE; STOP_NUMBER; ');

       for rec in 
         (SELECT DDATE, ROUTE_NUMBER,ROUTE_VARIANT, ROUTE_NAME, CARRIER_BOARD_NUM, CARRIER_NAME,
                 TRANSPORT_NAME, ID_TRANSPORT_ASUGPT, ORDER_NUM_ASUGPT, TRIP_NUM_ASUGPT,
                 STOP_TIME_REAL, STOP_TIME_PLAN, STOP_NAME_BEFORE, ID_STOP_BEFORE, STOP_NAME, 
                 ID_STOP, DISTANCE_BACK, DISTANCE_BACK_NORMATIVE, TRIP_TYPE, STOP_NUMBER 
           FROM tracks WHERE (ABS(tracks.DISTANCE_BACK - tracks.DISTANCE_BACK_NORMATIVE) > EPSILON)) loop
           UTL_FILE.put_line(file_id, rec.DDATE || ';' || rec.ROUTE_NUMBER || ';' || rec.ROUTE_VARIANT || ';' || rec.ROUTE_NAME || ';' || rec.CARRIER_BOARD_NUM || ';' || rec.CARRIER_NAME || ';' ||
           rec.TRANSPORT_NAME || ';' || rec.ID_TRANSPORT_ASUGPT || ';' ||  rec.ORDER_NUM_ASUGPT || ';' || rec.TRIP_NUM_ASUGPT || ';' || rec.STOP_TIME_REAL || ';' || rec.STOP_TIME_PLAN || ';' || 
           rec.STOP_NAME_BEFORE || ';' || rec.ID_STOP_BEFORE || ';' || rec.STOP_NAME || ';' || rec.ID_STOP || ';' || rec.DISTANCE_BACK || ';' || rec.DISTANCE_BACK_NORMATIVE || ';' ||  rec.TRIP_TYPE || ';' || rec.STOP_NUMBER);
       
        EXECUTE IMMEDIATE ' INSERT INTO ttt_CheckDistAndNormTable (DDATE, ROUTE_NUMBER, ROUTE_VARIANT, ROUTE_NAME, CARRIER_BOARD_NUM, CARRIER_NAME,
        TRANSPORT_NAME, ID_TRANSPORT_ASUGPT, ORDER_NUM_ASUGPT, TRIP_NUM_ASUGPT, STOP_TIME_REAL, STOP_TIME_PLAN, STOP_NAME_BEFORE, ID_STOP_BEFORE, STOP_NAME, 
        ID_STOP, DISTANCE_BACK, DISTANCE_BACK_NORMATIVE, TRIP_TYPE, STOP_NUMBER ) VALUES (:1, :2, :3, :4, :5, :6,:7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20)' USING
        rec.DDATE, rec.ROUTE_NUMBER, rec.ROUTE_VARIANT, rec.ROUTE_NAME, rec.CARRIER_BOARD_NUM, rec.CARRIER_NAME, rec.TRANSPORT_NAME, rec.ID_TRANSPORT_ASUGPT, rec.ORDER_NUM_ASUGPT, rec.TRIP_NUM_ASUGPT,
        rec.STOP_TIME_REAL, rec.STOP_TIME_PLAN, rec.STOP_NAME_BEFORE, rec.ID_STOP_BEFORE, rec.STOP_NAME, rec.ID_STOP, rec.DISTANCE_BACK, rec.DISTANCE_BACK_NORMATIVE, rec.TRIP_TYPE, rec.STOP_NUMBER;
        
        END LOOP;
        UTL_FILE.put_line(file_id, 'Execution time: ' || (systimestamp - v));    
        UTL_FILE.fclose(file_id);
        
    END CheckDistanceAndNormative;
    
    PROCEDURE StopCount (routeNumber in NVARCHAR2, maxStepsCount in INTEGER) as
    file_id UTL_FILE.file_type;
    maxNumberStop INT;
    countPrev INT;
    countCurrent INT;
    flag INT;
    flag_step INT;
    v TIMESTAMP;
    BEGIN
        flag := 0;
        flag_step :=0;
        SELECT systimestamp INTO v FROM dual;
        file_id := UTL_FILE.FOPEN('ddd_TESTCHECKDIR', 'StopCount.csv', 'W');
        
        FOR REC IN (SELECT distinct DDATE FROM TRACKS WHERE TRACKS.ROUTE_NUMBER = ROUTE_NUMBER) LOOP
            maxNumberStop := 0;
            flag := 0;
            countPrev :=0;
        
            UTL_FILE.put_line(file_id, 'Checking count of stops on 1 ' || REC.DDATE );        
        
            SELECT MAX(STOP_NUMBER) INTO maxNumberStop FROM tracks WHERE tracks.ROUTE_NUMBER = routeNumber AND tracks.DDATE = REC.DDATE;
            UTL_FILE.put_line(file_id,maxNumberStop );   
            
            FOR i IN 1..maxNumberStop LOOP
                flag_step := flag_step + 1;
                UTL_FILE.put_line(file_id, i || ';' || flag_step );        
                SELECT COUNT(STOP_NUMBER) into countCurrent FROM tracks WHERE tracks.ROUTE_NUMBER = route_number AND tracks.DDATE = REC.DDATE AND tracks.STOP_NUMBER = i;
                IF (countPrev !=0 AND countCurrent != countPrev) THEN
                     FLAG := 1;
                     EXIT;
                END IF;
                countPrev := countCurrent;
                IF (flag_step = maxStepsCount) THEN
                    EXIT;
                END if;
            END LOOP;
           
            IF (FLAG = 1) THEN
                 UTL_FILE.put_line(file_id, 'Some of the stops are skipped');
            ELSE
                UTL_FILE.put_line(file_id, 'All is ok');
            END IF;
            
            IF (flag_step = maxStepsCount) THEN
                EXIT;
            END IF;
        END LOOP;
        
        UTL_FILE.put_line(file_id, 'Execution time: ' || (systimestamp - v));
        UTL_FILE.fclose(file_id);
        
    END StopCount;   
    
    PROCEDURE CHECKSPEED (maxSpeed in FLOAT, miSpeed in FLOAT, maxStepsCount in INTEGER) IS
    timeBetweenStops INT;
    file_id UTL_FILE.file_type;
    flag int;
    SPEED FLOAT;
    STRB NVARCHAR2(1000);
    v TIMESTAMP;
    BEGIN
    
    CreateCheckSpeedTable;
    
    SELECT systimestamp INTO v FROM dual;
    flag := 0;
    file_id := UTL_FILE.FOPEN('ddd_TESTCHECKDIR', 'SpeedCheck.csv', 'W');
    UTL_FILE.put_line(file_id, 'Speed test (speed must be less then 70):' );  
    
    FOR REC IN (
        SELECT * FROM TRACKS WHERE NOT(TRACKS.STOP_TIME_REAL IS NULL)) LOOP
            flag := flag + 1;
            SELECT MAX(TRACKS.STOP_TIME_REAL) INTO STRB FROM TRACKS WHERE TRACKS.ROUTE_NUMBER = REC.ROUTE_NUMBER AND TRACKS.DDATE = REC.DDATE AND NOT(TRACKS.STOP_TIME_REAL IS NULL) AND TRACKS.ID_STOP = REC.ID_STOP_BEFORE AND TRACKS.STOP_TIME_REAL < REC.STOp_TIME_REAL;
    
            timeBetweenStops := (to_date(rec.stop_time_real, 'dd.mm.rr hh24:mi:ss')- to_date(STRB, 'dd.mm.rr hh24:mi:ss')) * 24 * 60 * 60;
            SPEED := REC.DISTANCE_BACK  / TIMEBETWEENSTOPS;
        
            IF (SPEED < 2.7 OR SPEED > maxSpeed) THEN  
                UTL_FILE.put_line(file_id, rec.DDATE || ';' || rec.ROUTE_NUMBER || ';' || rec.ROUTE_VARIANT || ';' || rec.ROUTE_NAME || ';' || rec.CARRIER_BOARD_NUM || ';' || rec.CARRIER_NAME || ';' ||
                rec.TRANSPORT_NAME || ';' || rec.ID_TRANSPORT_ASUGPT || ';' ||  rec.ORDER_NUM_ASUGPT || ';' || rec.TRIP_NUM_ASUGPT || ';' || rec.STOP_TIME_REAL || ';' || rec.STOP_TIME_PLAN || ';' || rec.STOP_NAME_BEFORE || ';' || rec.ID_STOP_BEFORE || ';' || rec.STOP_NAME || ';' || rec.ID_STOP || ';' || 
                rec.DISTANCE_BACK || ';' || rec.DISTANCE_BACK_NORMATIVE || ';' ||  rec.TRIP_TYPE || ';' || rec.STOP_NUMBER || ';' || STRB || ';' || timeBetweenStops || ';' || speed);
            
                EXECUTE IMMEDIATE 'INSERT INTO ttt_CheckSpeed 
                  (DDATE, ROUTE_NUMBER, CARRIER_BOARD_NUM, TRANSPORT_NAME, ID_TRANSPORT_ASUGPT, ORDER_NUM_ASUGPT, TRIP_NUM_ASUGPT, STOP_TIME_PLAN, STOP_NAME_BEFORE, ID_STOP_BEFORE, 
                  STOP_NAME, ID_STOP, DISTANCE_BACK, DISTANCE_BACK_NORMATIVE, TRIP_TYPE, STOP_NUMBER, STOP_TIME_REAL, STOP_TIME_REAL_BEFORE, TIME_BETWEEN, SPEED) 
                  VALUES (:1, :2, :3, :4, :5, :6,:7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20)' USING rec.DDATE, rec.ROUTE_NUMBER, rec.CARRIER_BOARD_NUM, 
                  rec.TRANSPORT_NAME, rec.ID_TRANSPORT_ASUGPT, rec.ORDER_NUM_ASUGPT, rec.TRIP_NUM_ASUGPT, rec.STOP_TIME_PLAN, rec.STOP_NAME_BEFORE, rec.ID_STOP_BEFORE, rec.STOP_NAME, 
                  rec.ID_STOP, rec.DISTANCE_BACK, rec.DISTANCE_BACK_NORMATIVE, rec.TRIP_TYPE, rec.STOP_NUMBER, rec.STOP_TIME_REAL, STRB, timeBetweenStops, SPEED;
            END IF;
            
            IF (flag = maxStepsCount) THEN
                EXIT;
            END IF;
        END LOOP;

        UTL_FILE.put_line(file_id, 'Execution time: ' || (systimestamp - v));
        UTL_FILE.fclose(file_id);
    END CHECKSPEED;
    
END testCheck;