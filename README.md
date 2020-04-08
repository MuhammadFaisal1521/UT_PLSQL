# UT_PLSQL
Utility for Trace PLSQL Code and generate its Log File 


# Enter Log 


begin 
/*Add Transaction*/
ut_plsql.ADD_LOG(P_LOG_NAME => 'Log Name Here',P_LOG_VALUES => 'Log values');
commit;

end;

#View Log by id or Query From its Table
begin 
/*View log Details*/
ut_plsql.DISPLAY_LOG(P_LOG_ID => 1);
end;


Select * from PLSQL_LOG
