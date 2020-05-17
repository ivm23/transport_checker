CREATE OR REPLACE PACKAGE BODY MAINCHECK AS

PROCEDURE CreateDirForReportFiles(dirPath in NVARCHAR2) as
    sql_str VARCHAR(2000);
    BEGIN
        sql_str := 'create directory ddd_TESTCHECKDIR as ''' || dirPath || '''';
        EXECUTE IMMEDIATE sql_str;
END CreateDirForReportFiles;
    

PROCEDURE STARTCHECK(RBSTABLE IN BOOLEAN, TRACKSTABLE IN BOOLEAN, SPEED IN BOOLEAN, RBSTABLENAME IN NVARCHAR2, TRACKSTABLENAME IN NVARCHAR2,DIRPATH IN NVARCHAR2, 
RBSK IN FLOAT, EPSILON INTEGER, routeNumber in NVARCHAR2, maxStepsCount in INTEGER, maxSpeed in FLOAT, miNSpeed in FLOAT) AS
  BEGIN
  IF (NOT(DIRPATH = '')) THEN 
    CreateDirForReportFiles(DIRPATH);
  END IF;
  
    IF (RBSTABLE = TRUE) THEN
         IF (RBSK < 0) THEN
            RBSCHECK.RBSEqualDist(0.3);
         ELSE
            RBSCHECK.RBSEqualDist(RBSK);
        END IF;
        
        RBSCHECK.RBSCheckRealDist;
        
    END IF;
    
    IF (TRACKSTABLE = TRUE) THEN
        IF (EPSILON < 0) THEN
             TESTCHECK.CheckDistanceAndNormative(500);
        ELSE
            TESTCHECK.CheckDistanceAndNormative(EPSILON);
        END IF;
        
        
        IF (MAXSTEPSCOUNT < 0) THEN
            TESTCHECK.StopCount(routeNumber, 100);
        ELSE
            TESTCHECK.StopCount(routeNumber, maxStepsCount);
        END IF;
        
        
        IF (MAXSPEED < 0 AND MINSPEED > 0) THEN
            TESTCHECK.CHECKSPEED(19.4, minSpeed, maxStepsCount);
        ELSE
            IF (MINSPEED < 0 AND MAXSPEED > 0) THEN
              TESTCHECK.CHECKSPEED(maxSpeed, 2.7, maxStepsCount);
            ELSE        
             IF (MINSPEED < 0 AND MAXSPEED < 0) THEN
               TESTCHECK.CHECKSPEED(19.4, 2.7, maxStepsCount);
             ELSE
               TESTCHECK.CHECKSPEED(maxSpeed, miNSpeed, maxStepsCount);
             END IF;
            END IF;
        END IF;
    END IF;
END STARTCHECK;

END MAINCHECK;