***************************************************************;
* ��csv�ļ�����תΪSAS�ļ���
		��csmar�й�Ʊ�ս��׵�28��csv�ļ��ϲ���һ��SAS�ļ�
***************************************************************;

libname out "C:\Users\dsf";	 /* ������ݵ�Ŀ¼ */

* ��4�������Ǵ�ѭ�����ļ�Ŀ¼�б�;
data temp (keep=file);
	input dir $ date $ time $ file $;
datalines;
  <dir>   1/16/17  0:21  12gkzzxx          
  <dir>   1/16/17  0:21  3b1t3qw2          
  <dir>   1/16/17  0:21  a3yeqmqd          
  <dir>   1/16/17  0:21  blkqdh2n          
  <dir>   1/16/17  0:21  cdfnkvaw          
  <dir>   1/16/17  0:21  eovbprla          
  <dir>   1/16/17  0:21  fyoncmrb          
  <dir>   1/16/17  0:21  gnkjxu14          
  <dir>   1/16/17  0:21  gx3wcteu          
  <dir>   1/16/17  0:21  hgpu1q0a          
  <dir>   1/16/17  0:21  itulofqs          
  <dir>   1/16/17  0:21  jmt2sfes          
  <dir>   1/16/17  0:21  lwhbt2a4          
  <dir>   1/16/17  0:21  oq21vpiy          
  <dir>   1/16/17  0:21  ovavtb01          
  <dir>   1/16/17  0:21  pfcrlumc          
  <dir>   1/16/17  0:21  qamldgj5          
  <dir>   1/16/17  0:21  qgyqrcu0          
  <dir>   1/16/17  0:21  qy0tszut          
  <dir>   1/16/17  0:21  r0wtaytr          
  <dir>   1/16/17  0:21  r2c52j2d          
  <dir>   1/16/17  0:21  rptu3ox3          
  <dir>   1/16/17  0:21  u2rhpuu2          
  <dir>   1/16/17  0:21  vconc3ee          
  <dir>   1/16/17  0:21  wfeizbss          
  <dir>   1/16/17  0:21  xcfyj2eg          
  <dir>   1/16/17  0:21  xcncc3rm          
  <dir>   1/16/17  0:21  ybaet4p3          
;
run;


*��ÿһ���ļ�Ŀ¼������1�������;
data _null_;
	set temp  end=eof;
	call symput('file'||left(_N_), trim(file));	
	if eof then call symput('nfile', _n_);	
	run;



proc printto  log=junk; run;
%macro csv2sas;
%do i=1 %to &nfile;
proc import datafile="C:\Users\dsf\&&file&i\TRD_Dalyr.csv"	* csv�ļ���Ŀ¼;
	out=work.dsf&i dbms=dlm  replace;	
	delimter='09'x;		* csmar��csv�ļ���tab�ָ���;
	run;
%end;
%mend sas2csv;
proc printto; run;

%csv2sas

*�ϲ����ݼ�Ϊ���������ļ�;
data out.dsf;
	set dsf1-dsf28;
	run;

* ɾȥ��ʱ���ݼ�dsf1-saf28;
proc datasets;
	delete dsf1-dsf28;
	quit;
    
