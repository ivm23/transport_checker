create or replace PACKAGE AUTOSPEED AS 

   PROCEDURE CALCULATESPEED(MAXSTEPSCOUNT in INT);
   PROCEDURE CreateEandS2;
   PROCEDURE UpdateEandS2 (X in FLOAT);

END AUTOSPEED;