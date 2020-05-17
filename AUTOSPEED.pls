create or replace PACKAGE BODY AUTOSPEED AS 

  PROCEDURE CALCULATESPEED(MAXSTEPSCOUNT IN INT) AS
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
  END CALCULATESPEED;

    PROCEDURE CreateEandS2 as
    SUM_X FLOAT;
    SUM_DIFF_X2 FLOAT;
    COUNT_X INTEGER;
    BEGIN
           EXECUTE IMMEDIATE 'CREATE TABLE ttt_CurrentEandS2 (
                            sum_x FLOAT,
                            sum_diff_x2 FLOAT,
                            count_x INT
                            )';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        SUM_X := 0;
        SUM_DIFF_X2 := 0;
        SELECT COUNT(*) INTO COUNT_X FROM TRANSPORT.Speed WHERE SPEED IS NOT NULL;
        SELECT SUM(SPEED) INTO SUM_X FROM TRANSPORT.Speed WHERE SPEED IS NOT NULL;
        SELECT SUM((SPEED - SUM_X) * (SPEED - SUM_X)) INTO SUM_DIFF_X2 FROM TRANSPORT.SPEED WHERE SPEED IS NOT NULL;  
        EXECUTE IMMEDIATE 'INSERT INTO ttt_CurrentEandS2(sum_x, sum_diff_x2, count_x) VALUES (:1, :2, :3)' USING SUM_X, SUM_DIFF_X2, COUNT_X;

    END CreateEandS2;
    
    PROCEDURE UpdateEandS2 (X in FLOAT) as
    SUM_X FLOAT;
    SUM_DIFF_X2 FLOAT;
    COUNT_X INTEGER;
    BEGIN
        SUM_X := 0;
        SUM_DIFF_X2 := 0;
        EXECUTE IMMEDIATE 'SELECT SUM(ttt_CurrentEandS2.COUNT_X) FROM ttt_CurrentEandS2' INTO COUNT_X;
        EXECUTE IMMEDIATE 'SELECT SUM(ttt_CurrentEandS2.SUM_X) FROM ttt_CurrentEandS2'  INTO SUM_X ;
        EXECUTE IMMEDIATE 'SELECT SUM(ttt_CurrentEandS2.SUM_DIFF_X2) FROM ttt_CurrentEandS2'  INTO SUM_DIFF_X2;
        
        COUNT_X := COUNT_X + 1;
        SUM_X := SUM_X + X;
        SUM_DIFF_X2 := SUM_DIFF_X2 + (X - SUM_X) * (X - SUM_X);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ttt_CurrentEandS2';
        EXECUTE IMMEDIATE 'INSERT INTO ttt_CurrentEandS2(sum_x, sum_diff_x2, count_x) VALUES (:1, :2, :3)' USING SUM_X, SUM_DIFF_X2, COUNT_X;

    END UpdateEandS2;
END AUTOSPEED;