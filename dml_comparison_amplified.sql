set feed off
set term on

-- Prepare Test
create table test_table(col1 varchar2(100))
/

insert into test_table(col1)
values('Test')
/


-- Create template PL/SQL implementation

create or replace procedure loop_select_performance as
    l_test test_table.col1%type;
begin

    for i in 1..100000 loop
        select col1
        into l_test
        from test_table fetch first 1 rows only;

        update test_table
            set col1 = l_test;
    end loop;

end loop_select_performance;
/


-- Create JavaScript module, implementing the same functionality
create or replace mle module loop_select_performance_module
language javascript AS
function loop_select_performance_js() {
    let connection;
    let result;

    connection = oracledb.defaultConnection();

    for (let i = 0; i < 100000; i++) {
        result = connection.execute(`
        select col1
        from test_table fetch first 1 rows only`
        );

        connection.execute(`update test_table
            set col1 = :val`, [result.rows[0].COL1]);
    }

}
export { loop_select_performance_js };
/


-- Create PL/SQL wrapper to call JavaScript
create or replace procedure loop_select_performance_js
as mle module loop_select_performance_module
signature 'loop_select_performance_js';
/

set serverout on


prompt Test Results:

-- Run test
declare
    l_start_time integer;
begin
    l_start_time := dbms_utility.get_cpu_time();
    loop_select_performance;
    dbms_output.put_line(
        'PL/SQL took ' || to_char(dbms_utility.get_cpu_time() - l_start_time) || ' hsecs'
    );

    l_start_time := dbms_utility.get_cpu_time();
    loop_select_performance_js;
    dbms_output.put_line(
        'JavaScript took ' || to_char(dbms_utility.get_cpu_time() - l_start_time) || ' hsecs'
    );
end;
/


-- Cleanup
drop procedure loop_select_performance;
drop procedure loop_select_performance_js;
drop mle module loop_select_performance_module;
drop table test_table;