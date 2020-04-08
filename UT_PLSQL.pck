CREATE OR REPLACE PACKAGE "UT_PLSQL"

 IS
/*
---------  Documentation Comments ---------

 Project      : Programming School
 Name         : File Name
 version      : 1.0
 Author       : Falick Faisal
 Contact      : www.falickfaisal.com
 Date         : 06-Apr-2018

Copyright ? 2018 by Programming School.

All rights reserved. No portion of this Code may be reproduced in any
form without permission from the Programming School,
For permissions contact US.

---------  Functional Comments ---------

 1) Require to Trace Execution of PLSQL Process
 2) Error Stack
 3) Boolean Expression
 4) XOR development on the base of Operator Overloading
 5) Read / Write log file in  I/O (pending)


---------  Code Comments ---------

  1) Rollback / Commit is require for all transaction
  2) For get lastest version
        Contact : FalickFaisal@gmail.com



------------------------------------------------------Run Scripts
Drop table PLSQL_LOG;

CREATE TABLE PLSQL_LOG
( LOG_ID                  NUMBER,
  LOG_DATE                DATE,
  CREATED_BY              VARCHAR2(200),
  LOG_NAME                VARCHAR2(200),
  LOG_INDEX               Number,
  LOG_VALUES              VARCHAR2(4000),
  Value_Checked           Char(1) Default 'N',
  FORMAT_CALL_STACK       VARCHAR2(4000),
  FORMAT_ERROR_STACK      VARCHAR2(4000),
  FORMAT_ERROR_BACKTRACE  VARCHAR2(4000),
  GET_CPU_TIME            NUMBER,
  DETAILS                 CLOB
);

create sequence PLSQL_LOG_seq start with 1 nocache nocycle


---------  Revision  ---------
sr      Task Name            Date                    By
********************************************************************************
1)      add boolean          05-may-2018             falick
2)      refactoring          29-Nov-2018             falick
3)      add Pragma
        autonomus_Transaction 29-Nov-2018            falick
4)

*/

  G_Log_name plsql_log.log_name%type;

    --// PROCEDURE

  Procedure Set_log_name(p_logName In varchar2);

  PROCEDURE ADD_LOG(P_LOG_VALUES IN VARCHAR2 default 'UNNAMED' ,p_details in varchar2 default 'Null');

  PROCEDURE DISPLAY_LOG(P_LOG_ID IN NUMBER);
  /*
  Give the Log Name who you want to access
  */
  PROCEDURE DISPLAY_LOG(P_Log_name IN Varchar2 default null , p_checked in char default Null);

  PROCEDURE Mark_LOG (P_Log_name IN  Varchar2 default 'UNNAMED');

  FUNCTION BOOLEAN_CONVERTOR(P_INT IN INTEGER )  RETURN BOOLEAN ;

  FUNCTION BOOLEAN_CONVERTOR(P_BOOL IN BOOLEAN )  RETURN INTEGER ;

  --//FUNCTIONS
  FUNCTION FORMAT_CALL_STACK  RETURN VARCHAR2;

  FUNCTION FORMAT_ERROR_STACK  RETURN VARCHAR2;

  FUNCTION FORMAT_ERROR_BACKTRACE  RETURN VARCHAR2 ;

FUNCTION TABLE_TO_HTML(v_TableName  VARCHAR2,
                         clob_Message CLOB DEFAULT '') RETURN CLOB;

  FUNCTION SQL_TO_HTML(v_SqlStatement VARCHAR2,
                       clob_Message   CLOB DEFAULT '') RETURN CLOB;

  FUNCTION ROW_TO_PIE_CHART_HTML(v_SqlStatement VARCHAR2,
                                 clob_Message   CLOB DEFAULT '') RETURN CLOB;
                                 
END;
/
CREATE OR REPLACE PACKAGE BODY "UT_PLSQL" IS
-- week cursor for fetching row
  TYPE refCur IS REF CURSOR;
  
  Procedure Set_log_name(p_logName In varchar2)
  is
  begin
          G_Log_name:=p_logName;
  end Set_log_name;


PROCEDURE ADD_LOG(P_LOG_VALUES IN VARCHAR2,p_details in varchar2 default 'Null') IS
    /*INSERT DATA INTO LOG TABLE*/
    pragma autonomous_transaction;
    l_index_id Number;
  BEGIN
    SELECT NVL(MAX(LOG_index), 0) + 1 LOG_ID
      into l_index_id
      FROM PLSQL_LOG
      where log_name = G_Log_name;


    INSERT INTO PLSQL_LOG(LOG_ID,LOG_DATE,CREATED_BY,LOG_NAME,LOG_index,  LOG_VALUES,FORMAT_CALL_STACK,FORMAT_ERROR_STACK,FORMAT_ERROR_BACKTRACE,GET_CPU_TIME , Details )
    VALUES  ( PLSQL_LOG_seq.Nextval ,SYSDATE,USER,G_Log_name,l_index_id,  P_LOG_VALUES,DBMS_UTILITY.FORMAT_CALL_STACK,DBMS_UTILITY.FORMAT_ERROR_STACK , DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, DBMS_UTILITY.GET_CPU_TIME , p_details );
    Commit;
END   ADD_LOG;

  PROCEDURE DISPLAY_LOG(P_LOG_ID IN NUMBER) is
    /*LOG OUTPUT */

    LOG_ROWTYPE  PLSQL_LOG%ROWTYPE;

    CURSOR PLSQL_C IS
                                  SELECT *
                                  FROM PLSQL_LOG cut
                                  WHERE CUT.LOG_ID = P_LOG_ID
                                  and cut.created_by=user;
  BEGIN

    --// OPEN AND FETCH
    OPEN PLSQL_C;
    FETCH PLSQL_C   INTO LOG_ROWTYPE;


            IF  PLSQL_C%FOUND THEN
              DBMS_OUTPUT.put_line('Test name : ' || LOG_ROWTYPE.LOG_name);
              DBMS_OUTPUT.put_line('Test Values : ' || LOG_ROWTYPE.LOG_values);
              DBMS_OUTPUT.put_line('------------------------------------------------------------------');
              DBMS_OUTPUT.put_line('FORMAT_CALL_STACK : ' ||LOG_ROWTYPE.FORMAT_CALL_STACK  );
              DBMS_OUTPUT.put_line('------------------------------------------------------------------');
              DBMS_OUTPUT.put_line('FORMAT_ERROR_STACK : ' ||
                                   LOG_ROWTYPE.FORMAT_ERROR_STACK);
                DBMS_OUTPUT.put_line('------------------------------------------------------------------');
              DBMS_OUTPUT.put_line(' FORMAT_ERROR_BACKTRACE : ' ||
                                   LOG_ROWTYPE.FORMAT_ERROR_BACKTRACE);
              DBMS_OUTPUT.put_line('------------------------------------------------------------------');
              DBMS_OUTPUT.put_line('User : ' || LOG_ROWTYPE.CREATED_BY);
              DBMS_OUTPUT.put_line('DATE : ' || LOG_ROWTYPE.LOG_date);
            ELSE
              DBMS_OUTPUT.put_line('------------------------------------------------------------------');
              DBMS_OUTPUT.put_line('Invalid Test id');

            END IF;

    CLOSE PLSQL_C;

  END   DISPLAY_LOG;

  PROCEDURE DISPLAY_LOG(P_Log_name IN Varchar2 default null , p_checked in char default Null)
    is
    CURSOR PLSQL_C IS
                  SELECT *
                  FROM PLSQL_LOG cut
                  WHERE upper(CUT.LOG_name) = upper(nvl(P_Log_name,CUT.LOG_name))
                   and cut.value_checked = nvl(decode (upper(p_checked),'YES','Y','NO','N','TRUE','Y','FALSE','N',upper(p_checked)),cut.value_checked)
                   and cut.created_by=user ;
  BEGIN

    For ldx in  PLSQL_C loop
        DISPLAY_LOG(ldx.log_id);
      end loop ;
   end DISPLAY_LOG;


  PROCEDURE Mark_LOG (P_Log_name IN  Varchar2 default 'UNNAMED')
    is
  BEGIN
    Update PLSQL_LOG
     set value_checked ='Y'
     Where upper(log_name)=upper(P_Log_name);
  END Mark_LOG;




  FUNCTION BOOLEAN_CONVERTOR(P_INT IN INTEGER )  RETURN BOOLEAN  IS
  BEGIN
  /*
  RETURN BOOLEAN
  0 =  FALSE
  1 = TRUE
 */
 RETURN sys.diutil.int_to_bool(P_INT);

  END BOOLEAN_CONVERTOR;

  FUNCTION BOOLEAN_CONVERTOR(P_BOOL IN BOOLEAN )  RETURN INTEGER  IS
  BEGIN

   /*
  RETURN  INTEGER
  0 =  FALSE
  1 = TRUE
 */
 RETURN sys.diutil.bool_to_int(P_bool);

  END BOOLEAN_CONVERTOR;


  FUNCTION FORMAT_CALL_STACK RETURN VARCHAR2 IS
  /*FORMAT_CALL_STACK*/
  BEGIN
    RETURN DBMS_UTILITY.FORMAT_CALL_STACK;
  END   FORMAT_CALL_STACK ;


  FUNCTION  FORMAT_ERROR_STACK RETURN VARCHAR2 is
     /*FORMAT_ERROR_STACK*/
  begin
    return DBMS_UTILITY.FORMAT_ERROR_STACK;
  end   FORMAT_ERROR_STACK;


  FUNCTION FORMAT_ERROR_BACKTRACE  RETURN VARCHAR2 is
  /*FORMAT_BACKTRACE_STACK*/
  begin
    return DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  end   FORMAT_ERROR_BACKTRACE;

---------------------Samples---------------------
/*
*------------------------------------------------
*  BEGIN
*   dbms_output.put_line(PKG_TABLE_TO_HTML.TABLE_TO_HTML('HR.EMPLOYEES','My header'));
*  END;
*------------------------------------------------
*  BEGIN
*   dbms_output.put_line(PKG_TABLE_TO_HTML.SQL_TO_HTML('SELECT EMPLOYEE_ID, FIRST_NAME || ' ' || LAST_NAME AS FULL_NAME FROM HR.EMPLOYEES','My header'));
*  END;
*------------------------------------------------
*/

  

  -- get the cursor id and concatenate fetched row with separator or html table data tags
  FUNCTION CONCATENATE_ROW(i_CurNum    INTEGER,
                           v_separator VARCHAR2
                          ) RETURN CLOB IS
    clob_Temp   CLOB;
    clob_Data   CLOB := null;
    i_Count     INTEGER;
    i_ColCount  INTEGER;
    descTabRec  DBMS_SQL.DESC_TAB;
    d_Temp      DATE;
    n_Temp      NUMBER;
  BEGIN
    -- to get columns type and columns count
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    -- loop every column and concatenate
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      IF descTabRec(i_Count).col_type = 1 THEN -- varchar2
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, clob_Temp);
      ELSIF descTabRec(i_Count).col_type = 2 THEN -- number
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, n_Temp);
        clob_Temp := TO_CHAR(n_Temp);
      ELSIF descTabRec(i_Count).col_type = 12 THEN -- date
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, d_Temp);
        clob_Temp := TO_CHAR(d_Temp);
      END IF;

      IF v_separator IS NULL THEN
        clob_Data := clob_Data || ' ' || HTF.TABLEDATA(clob_Temp, 'CENTER');
      ELSE
        clob_Data := clob_Data || nvl(clob_Temp,'undefined') || v_separator;
      END IF;
    END LOOP;

    RETURN(clob_Data);
  END;

  FUNCTION JS_PIE_FUNC(i_CurNum    INTEGER
                      ) RETURN CLOB IS
    i_ColCount      INTEGER;
    i_Count         INTEGER;
    clob_ColHeaders CLOB := null;
    clob_ColData    CLOB := null;
    clob_Data       CLOB := null;
    descTabRec      DBMS_SQL.DESC_TAB;
  BEGIN
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      clob_ColHeaders := clob_ColHeaders || '"' || descTabRec(i_Count).col_name || '",';
    END LOOP;

    LOOP
      i_Count := DBMS_SQL.FETCH_ROWS(i_CurNum);
      EXIT WHEN i_Count = 0;
      clob_Data := CONCATENATE_ROW(i_CurNum, ',');
    END LOOP;

    clob_Data := '
      <script type="text/javascript">
          function draw_pie() {
              var canvas = document.getElementById("canvas");
              var ctx = canvas.getContext("2d");
              var canvas_size = [canvas.width, canvas.height];
              var data = [' || substr(clob_Data, 0, length(clob_Data)-1) || '], value = 0, total = 0;
              var labels = [' || substr(clob_ColHeaders, 0, length(clob_ColHeaders)-1) || '];
              var radius = Math.min(canvas_size[0], canvas_size[1]) / 2;
              var center = [canvas_size[0]/2, canvas_size[1]/2];
              var sofar = 0; // keep track of progress
              var i=0;
              var tempArray = [];

              for(var piece in data) {
                  if(data[piece]) {
                      total = total + data[piece];
                  }
                  else {
                      tempArray.push(piece);
                  }
              }

              for(var piece in tempArray.reverse()) {
                  data.splice(tempArray[piece], 1);
                  labels.splice(tempArray[piece], 1);
              }

              for (var piece in data) {
                  var thisvalue = data[piece] / total;

                  ctx.beginPath();
                  ctx.moveTo(center[0], center[1]); // center of the pie
                  ctx.arc(  // draw next arc
                        center[0],
                        center[1],
                        radius,
                        Math.PI * (- 0.5 + 2 * sofar), // -0.5 sets set the start to be top
                        Math.PI * (- 0.5 + 2 * (sofar + thisvalue)),
                        false
                    );

                  ctx.lineTo(center[0], center[1]); // line back to the center
                  ctx.closePath();
                  ctx.fillStyle = getColor();
                  ctx.fill();
                  ctx.strokeText(labels[i++],
                                 center[0] -30 + 0.75*radius * Math.cos(Math.PI * (- 0.5 + 2 * (sofar+0.5 * thisvalue))),
                                 center[1] + 0.75*radius * Math.sin(Math.PI * (- 0.5 + 2 * (sofar+0.5 * thisvalue))),
                                 50
                                )
                  sofar += thisvalue;
               }
          }

          function getColor() {
              var rgb = [];
              for (var i = 0; i < 3; i++) {
                  rgb[i] = Math.round(100 * Math.random() + 155) ; // [155-255] = lighter colors
              }
              return "rgb(" + rgb.join(",") + ")";
          }
      </script>';

      RETURN clob_Data;
  END;

  PROCEDURE DEFINE_COLUMNS(i_CurNum INTEGER
                          ) IS
    i_ColCount  INTEGER;
    descTabRec  DBMS_SQL.DESC_TAB;
    clob_Temp   CLOB;
    d_Temp      DATE;
    n_Temp      NUMBER;
  BEGIN
    -- to get columns type and columns count
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    -- loop every column and define type
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      IF descTabRec(i_Count).col_type = 1 THEN -- varchar2
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, clob_Temp);
      ELSIF descTabRec(i_Count).col_type = 2 THEN -- number
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, n_Temp);
      ELSIF descTabRec(i_Count).col_type = 12 THEN -- date
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, d_Temp);
      END IF;
    END LOOP;
  END;

  FUNCTION CREATE_HTML(clob_Message   CLOB,
                       i_CurNum       INTEGER,
                       clob_HtmlStart CLOB,
                       clob_HtmlEnd   CLOB
                      ) RETURN CLOB IS
    descTabRec  DBMS_SQL.DESC_TAB;
    i_ColCount  INTEGER;
    i_Count     INTEGER;
    clob_Html   CLOB;
    clob_Temp   CLOB;
   BEGIN
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    clob_Html := clob_HtmlStart;

    -- set title of html
    clob_Html := clob_Html || HTF.TITLE(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')) || CHR(10);
    -- add custom message to header
    clob_Html := clob_Html || HTF.HEADER(3, TO_CHAR(clob_Message), 'CENTER') || CHR(10);
    -- open table
    clob_Html := clob_Html || HTF.TABLEOPEN('BORDER=1', 'CENTER', NULL, NULL, 'CELLPADDING=0') || CHR(10);

    -- new row for table header
    clob_Html := clob_Html || HTF.TABLEROWOPEN || CHR(10);
    -- loop all columns and set table headers
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      clob_Html := clob_Html || HTF.TABLEDATA(HTF.STRONG(descTabRec(i_Count).col_name), 'CENTER') || CHR(10);
    END LOOP;
    -- close row for table header
    clob_Html := clob_Html || HTF.TABLEROWCLOSE || CHR(10);

    -- fetch all rows in the table and prepare table
    LOOP
      i_Count := DBMS_SQL.FETCH_ROWS(i_CurNum);
      EXIT WHEN i_Count = 0;
      clob_Html := clob_Html || HTF.TABLEROWOPEN || CHR(10);
      clob_Temp := CONCATENATE_ROW(i_CurNum, NULL);
      clob_Html := clob_Html || clob_Temp || HTF.TABLEROWCLOSE || CHR(10);
    END LOOP;
    -- close table
    clob_Html := clob_Html || HTF.TABLECLOSE;

    clob_Html := clob_Html || clob_HtmlEnd;

    RETURN clob_Html;
  END;

  FUNCTION TABLE_TO_HTML(v_TableName  VARCHAR2,
                         clob_Message CLOB DEFAULT '') RETURN CLOB IS
    clob_Data      CLOB := null;
  BEGIN

    clob_Data := SQL_TO_HTML('SELECT * FROM ' || v_TableName, clob_Message);

    RETURN clob_Data;
  END;

  FUNCTION SQL_TO_HTML(v_SqlStatement VARCHAR2,
                       clob_Message   CLOB DEFAULT '') RETURN CLOB IS
    i_CurNum       INTEGER;
    curObj         refCur;
    clob_Data      CLOB := null;
  BEGIN
    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);
    clob_Data := CREATE_HTML(clob_Message, i_CurNum, '<html><body>', '</body></html>');

    RETURN clob_Data;
  END;

  FUNCTION ROW_TO_PIE_CHART_HTML(v_SqlStatement VARCHAR2,
                                 clob_Message   CLOB DEFAULT '') RETURN CLOB IS
    i_CurNum       INTEGER;
    curObj         refCur;
    clob_Data      CLOB := null;
    clob_JsData    CLOB := null;
  BEGIN
    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);
    clob_JsData := JS_PIE_FUNC(i_CurNum);

    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);

    clob_Data := CREATE_HTML(clob_Message, i_CurNum, '<html>' || clob_JsData || '<body onload="draw_pie()">', '<canvas id="canvas" width="300" height="300"></canvas></body></html>');

    RETURN clob_Data;
  END;



END UT_PLSQL ;
/
