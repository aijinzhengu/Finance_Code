*本程序演示将sas数据文件批量转化为csv文件，使用内置的SASHELP库中180个数据文件;

proc sql;
   title 'All Tables and Views in the SASHELP Library';
   create table work.filename as 
   select memname
		from dictionary.tables
   where libname = 'SASHELP'and memtype='DATA';

data _null_;
	set work.filename  end=eof;
	call symput('file'||left(_N_), trim(memname));	/*对每个输入数据都用一个宏变量装载，生成180个宏变量file1-file180*/
	if eof then call symput('nfile', _n_);	/*生成宏变量记录行数，也就是输入文件的个数*/
	run;


proc printto  log=junk; run;

%macro sas2csv;
%do i=1 %to &nfile;
proc export data=SASHELP.&&file&i
	outfile="E:\CSVFILE\&&file&i...csv" dbms=csv replace;	/*输出到目录“E:\CSVFILE\”*/
	run;
%end;
%mend sas2csv;

%sas2csv
proc printto  log; run;

