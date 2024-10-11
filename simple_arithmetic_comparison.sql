set feed off
set term on

-- Create template PL/SQL implementation
create or replace function simple_performance_plsql(
    i_starting_number number
    ,i_iterations number
) 
return number as

    l_result number := i_starting_number;
begin
    for i in 1..i_iterations loop
        l_result := l_result + i_starting_number;
		l_result := l_result - i_starting_number / 3;
    end loop;

    return l_result;
end simple_performance_plsql;
/

-- Create JavaScript module, implementing the same functionality
create or replace mle module simple_performance_module
language javascript as
function simple_performance_js(startingNumber, iterations) {
    let result = startingNumber;
    for (let i = 0; i < iterations; i++) {
        result += startingNumber;
        result -= startingNumber / 3;
    }
    return result;
}
export { simple_performance_js };
/

-- Create PL/SQL wrapper to call JavaScript
create or replace function simple_performance_js_wrapper(
    i_starting_number number
    ,i_iterations number
) 
return number as
  mle module
  simple_performance_module signature 'simple_performance_js(number, number)';
/


-- Create performance test
create or replace procedure compare_arithmetic_performance(
    i_starting_number number
    ,i_iterations number
) 
as
    l_result number;
    l_cpu_start_time integer;
begin
    l_cpu_start_time := dbms_utility.get_cpu_time();

    l_result := simple_performance_plsql(i_starting_number, i_iterations);

    dbms_output.put_line(l_result);
    dbms_output.put_line(
        'PL/SQL took ' || to_char(dbms_utility.get_cpu_time() - l_cpu_start_time) || ' hsecs'
    );

    l_cpu_start_time := dbms_utility.get_cpu_time();

    l_result := simple_performance_js_wrapper(i_starting_number, i_iterations);

    dbms_output.put_line(l_result);
    dbms_output.put_line(
        'JavaScript took ' || to_char(dbms_utility.get_cpu_time() - l_cpu_start_time) || ' hsecs'
    );
end;
/


set serverout on

prompt Test Results (Starting Number: 9, Iterations: 100,000,000)

-- Run different tests
begin
    compare_arithmetic_performance(9, 100000000);
end;
/

prompt Test Results (Starting Number: 9, Iterations: 1,000,000,000)

begin
    compare_arithmetic_performance(9, 1000000000);
end;
/

prompt Test Results (Starting Number: 10, Iterations: 100,000,000)

begin
    compare_arithmetic_performance(10, 100000000);
end;
/


-- Change PL/SQL implementation to binary datatypes
create or replace function simple_performance_plsql(
    i_starting_number binary_integer
    ,i_iterations binary_integer
) 
return binary_double as

    l_result binary_double := i_starting_number;

begin
    for i in 1..i_iterations loop
        l_result := l_result + i_starting_number;
		l_result := l_result - i_starting_number / 3;
    end loop;

    return l_result;
end simple_performance_plsql;
/


-- Run tests again
prompt Test Results (Starting Number: 9, Iterations: 100,000,000, Binary Types)

begin
    compare_arithmetic_performance(9, 100000000);
end;
/

prompt Test Results (Starting Number: 10, Iterations: 100,000,000, Binary Types)

begin
    compare_arithmetic_performance(10, 100000000);
end;
/


-- Cleanup
drop function simple_performance_plsql;
drop procedure compare_arithmetic_performance;
drop function simple_performance_js_wrapper;
drop mle module simple_performance_module;