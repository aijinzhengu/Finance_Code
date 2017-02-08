/* Generate temp datasets for explorary analysis and debugging, 
	name each dataset with '_dataset_name' */
data _temp1;
	* do something;
run;


/* House cleaning: delete temporary tables.  */
proc datasets;
	delete _:(gennum=all);
run;


/* Validate key variable (id1, id2) actually can identify unique value for variable of interest: var1.
		If _temp2 is not null, then duplicate values exist and you need to figure out why.  
*/
proc sql;
	create table _temp2 as   
	select id1, id2, 
	count(var1) as n_var1 from your_data
	group by id1, id2
	having count(var1)>1;
quit;


/* Delete missing observations for variables of interest */
data your_data;
	set your_data;
	/* var1, var2 are numeric and var3, var4 are char but var5 can be either numeric or char.
	 Delete obs if any var from var1-var5 is missing */
	if nmiss(var1, var2)=0 and cmiss(var3, var4)=0 and not missing(var5);
run;

/* Inspect the distribution of variable 
		Does mean deviates a lot from median?
		If p1 and p99 exhibit large absolute values, that means winsore cannot cure this problem */
proc means data=your_data n p1 p25 mean p50 p75 p99 std;
	var var1;
run;


/* Redirect your log file */
proc printto; log=junk; run;		/* Sink your log file, especially for loops such as regession by group */
proc printto; run;					/* Resume to show log */

filename myfile 'c:\mydir\mylog.log';     /* Export your log file */
proc printto log=myfile;
run;

/* use macros */
options sasautos=('your_macro_dir1' 'your_macro_dir2' sasautos);
