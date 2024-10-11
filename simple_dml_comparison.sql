set feed off
set term on

-- Prepare Test
create table test_table(col1 varchar2(100))
/


-- Create template PL/SQL implementation
create or replace procedure simple_select_performance as
    l_test test_table.col1%type;
begin
    insert into test_table(col1)
    values('Test');

    select col1
    into l_test
    from test_table fetch first 1 rows only;

    update test_table
    set col1 = 'Updated Test';

    delete from test_table;
end simple_select_performance;
/


-- Create JavaScript module, implementing the same functionality
create or replace mle module simple_select_performance_module
language javascript AS
function simple_select_performance_js() {
    let connection;

    connection = oracledb.defaultConnection();

    let result = connection.execute(`
        insert into test_table(col1)
        values('Test')`
    );

    result = connection.execute(`
        select col1
    from test_table fetch first 1 rows only`
    );

    result = connection.execute(`
        update test_table
    set col1 = 'Updated Test'`
    );

    result = connection.execute(`
        delete from test_table`
    );
}
export { simple_select_performance_js };
/


-- Create PL/SQL wrapper to call JavaScript
create or replace procedure simple_select_performance_js
as mle module simple_select_performance_module
signature 'simple_select_performance_js';
/

set serverout on

prompt Test Results:

-- Run test
declare
    l_start_time timestamp;
begin
    l_start_time := systimestamp;
    simple_select_performance;
    dbms_output.put_line(
        'PL/SQL took ' || extract( second from (systimestamp - l_start_time) ) || ' seconds'
    );

    l_start_time := systimestamp;
    simple_select_performance_js;
    dbms_output.put_line(
        'JavaScript took ' || extract( second from (systimestamp - l_start_time) ) || ' seconds'
    );
end;
/

-- Cleanup
drop procedure simple_select_performance;
drop procedure simple_select_performance_js;
drop mle module simple_select_performance_module;
drop table test_table;