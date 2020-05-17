create or replace PACKAGE testCheck AS

    PROCEDURE CreateDirForReportFiles(dirPath in NVARCHAR2);
    PROCEDURE LoadDateToTracksTable(tableName IN NVARCHAR2);
    PROCEDURE LoadDateToIdealTable(tableName IN NVARCHAR2);
        
    PROCEDURE CheckDistanceAndNormative(EPSILON INTEGER);
    PROCEDURE StopCount(routeNumber in NVARCHAR2, maxStepsCount in INTEGER);
    PROCEDURE CHECKSPEED(maxSpeed in FLOAT, miSpeed in FLOAT, maxStepsCount in INTEGER);
    PROCEDURE CreateSpeedTable(maxStepsCount in INTEGER); 

END testCheck;