create or replace PACKAGE BODY RBSCHECK AS

PROCEDURE CREATE_VIEWS AS
    BEGIN
    
    EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW VVV_RBSDATA AS 
    SELECT
        LATITUDE as LATITUDE, 
        LONGITUDE as LONGITUDE, 
        ID_STOP as ID_STOP,
        ID_NEXT_STOP as ID_NEXT_STOP,
        DISTANCE as DISTANCE
        FROM RBS';
    
      EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW VVV_TSTOP AS 
        SELECT
        LATITUDE as LATITUDE, 
        LONGITUDE as LONGITUDE, 
        ID_STOP as ID_STOP,
        ID_NEXT_STOP as ID_NEXT_STOP,
        DISTANCE as DISTANCE
        FROM RBS';
                
END CREATE_VIEWS;

PROCEDURE CREATE_VIEWS_WITHDATA AS
    BEGIN
    
    EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW VVV_RBSDATA_WITHDATA AS
                        SELECT
                        ID_STOP as ID_STOP,
                        ID_NEXT_STOP as ID_NEXT_STOP,
                        DISTANCE as DISTANCE,
                        DIRECTION AS DIRECTION,
                        STOP_NUMBER AS STOP_NUMBER,
                        ROUTE_NUMBER AS ROUTE_NUMBER,
                        DDATE AS DDATE    
                        FROM RBS';
    
      EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW VVV_TSTOP_WITHDATA AS 
                        SELECT
                            ID_STOP as ID_STOP,
                            ID_NEXT_STOP as ID_NEXT_STOP,
                            DISTANCE as DISTANCE,
                            DIRECTION AS DIRECTION,
                            STOP_NUMBER AS STOP_NUMBER,
                            ROUTE_NUMBER AS ROUTE_NUMBER,
                            DDATE AS DDATE    
                            FROM RBS';
                
END CREATE_VIEWS_WITHDATA;

PROCEDURE CREATE_RBSCHECKTABLE AS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE TTT_RBSCHECK (ID_STOP INTEGER,
                                                      ID_NEXT_STOP INTEGER,
                                                      BRIEF_DIST FLOAT,
                                                      DISTANCE_FROM_RBS FLOAT    
                                                      )';
                                                      
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        EXECUTE IMMEDIATE  'TRUNCATE TABLE TTT_RBSCHECK';
END CREATE_RBSCHECKTABLE;
    
    
PROCEDURE CREATE_RBSCHECKTABLE_WITHDATA AS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE TTT_RBSCHECK_WITHDATA(
    ID_STOP INT,
    ID_NEXT_STOP INT,
    DIRECTION INT,
    STOP_NUMBER INT,
    ROUTE_NUMBER NVARCHAR2(1000),
    DDATE NVARCHAR2(1000)  )';
                                                      
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -955 THEN NULL;
                          ELSE RAISE;
            END IF;
        
        EXECUTE IMMEDIATE  'TRUNCATE TABLE TTT_RBSCHECK_WITHDATA';
END CREATE_RBSCHECKTABLE_WITHDATA;

PROCEDURE RBSEqualDist(K IN INTEGER) AS
BEGIN
    CREATE_RBSCHECKTABLE_WITHDATA;
    CREATE_VIEWS_WITHDATA;
    DECLARE
FLAG INT;
BEGIN
FLAG := 0;
for rec in (
   select VVV_RBSDATA_WITHDATA.ID_STOP AS ID_STOP, VVV_RBSDATA_WITHDATA.ID_NEXT_STOP AS ID_NEXT_STOP, VVV_RBSDATA_WITHDATA.DIRECTION AS DIRECTION, 
    VVV_RBSDATA_WITHDATA.STOP_NUMBER AS STOP_NUMBER, VVV_RBSDATA_WITHDATA.ROUTE_NUMBER AS ROUTE_NUMBER, VVV_RBSDATA_WITHDATA.DDATE AS DDATE, VVV_RBSDATA_WITHDATA.DISTANCE AS DIST1, 
    VVV_TSTOP_WITHDATA.DISTANCE AS DIST2
    FROM VVV_RBSDATA_WITHDATA JOIN VVV_TSTOP_WITHDATA ON VVV_RBSDATA_WITHDATA.ID_STOP = VVV_TSTOP_WITHDATA.ID_STOP AND VVV_RBSDATA_WITHDATA.ID_NEXT_STOP = VVV_TSTOP_WITHDATA.ID_NEXT_STOP AND VVV_RBSDATA_WITHDATA.DIRECTION = VVV_TSTOP_WITHDATA.DIRECTION
    AND VVV_RBSDATA_WITHDATA.STOP_NUMBER = VVV_TSTOP_WITHDATA.STOP_NUMBER AND VVV_RBSDATA_WITHDATA.ROUTE_NUMBER = VVV_TSTOP_WITHDATA.ROUTE_NUMBER
   )
    loop
   FLAG := FLAG + 1;
       
        IF (ABS(REC.DIST1 - REC.DIST2) > K) THEN
            INSERT INTO TTT_RBSCHECK_WITHDATA (ID_STOP, ID_NEXT_STOP,DIRECTION, STOP_NUMBER, ROUTE_NUMBER, DDATE) VALUES
            (REC.ID_STOP, REC.ID_NEXT_STOP, REC.DIRECTION, REC.STOP_NUMBER, REC.ROUTE_NUMBER, REC.DDATE);
        END IF;
    
    IF (FLAG > 1000) THEN
        EXIT;
        END IF;
    end loop;
    
    END;
END RBSEqualDist;

  PROCEDURE RBSCheckRealDist AS
   d FLOAT;
    PI FLOAT;
    E_R FLOAT;
    lat1 FLOAT;
    lat2 FLOAT;
    long1 FLOAT;
    long2 FLOAT;
    cl1 FLOAT;
    cl2 FLOAT;
    sl1 FLOAT;
    sl2 FLOAT;
    delta FLOAT;
    cdelta FLOAT;
    sdelta FLOAT;
    x FLOAT;
    y FLOAT;
    ad FLOAT;
    FLAG FLOAT;
  BEGIN
  CREATE_VIEWS;
  CREATE_RBSCHECKTABLE;
  E_R := 6372.795;
   PI := 3.14159265358979 ;
   FLAG := 0;
   
   for rec in (
   select VVV_RBSDATA.LATITUDE as L1, VVV_RBSDATA.LONGITUDE as LON1, VVV_TSTOP.LATITUDE as L2, VVV_TSTOP.LONGITUDE as LON2, 
   VVV_RBSDATA.ID_STOP as ID_STOP, VVV_RBSDATA.ID_NEXT_STOP as ID_NEXT_STOP, VVV_RBSDATA.DISTANCE as dist
    FROM VVV_RBSDATA JOIN VVV_TSTOP ON VVV_RBSDATA.ID_NEXT_STOP = VVV_TSTOP.ID_STOP
   )
    loop
   FLAG := FLAG + 1;
        lat1 := rec.L1 * PI / 180.0;
        lat2 := rec.L2 * PI / 180.0;
        long1 := rec.LON1 * PI / 180.0;
        long2 := rec.LON2 * PI / 180.0;
 
        cl1 := cos(lat1);
        cl2 := cos(lat2);
        sl1 := sin(lat1);
        sl2 := sin(lat2);
        
        delta := long2 - long1;
        cdelta := cos(delta);
        sdelta := sin(delta);
        
        y := sqrt((cl2 * sdelta)*(cl2 * sdelta) + (cl1 * sl2 - sl1 * cl2 * cdelta)*(cl1 * sl2 - sl1 * cl2 * cdelta));
        x := sl1 * sl2 + cl1 * cl2 * cdelta;
        ad := atan2(y, x);
        d := ad * E_R;
       
        IF ((d - 0.3) > rec.dist) THEN
                    INSERT INTO TTT_RBSCHECK(ID_STOP, ID_NEXT_STOP, BRIEF_DISTANCE, DISTANCE_FROM_RBS) VALUES (rec.ID_STOP, rec.ID_NEXT_STOP, d, REC.DIST);
        END IF;
    
    IF (FLAG > 1000) THEN
        EXIT;
        END IF;
    end loop;
    
  END RBSCheckRealDist;

END RBSCHECK;