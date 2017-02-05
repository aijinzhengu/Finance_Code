data sim_dat;
    call streaminit(1234);
    do id = 1 to 500;
        ps_score = rand('uniform', 0.3, 0.7);
        treat=id<=150;
        output;
    end;
run;

proc print data=sim_dat (firstobs=148 obs=152); run;

data post_sim_dat (drop=i);
           
    do i=1 to 500*1000;
        sample_id=ceil(i/500);
        pickit=ceil(ranuni(666)*totobs);    /* 设置随机数种子666 */
        set sim_dat point=pickit nobs=totobs;
        output;
    end;
    stop; 
    label sample_id='对bootstrap samples编号，用于后续分析'
    ;
run;

proc print data=post_sim_dat (firstobs=498 obs=502);
     title ’1000 Bootstrap Samples’;
run;

data post_sim_dat_2;
    set sim_dat;
    index=ranuni(666);
run;

proc sort data=post_sim_dat_2; by index; run;

data post_sim_dat_2;
    new_id=_n_;
    set post_sim_dat_2 (drop=index);
run;



proc sort data=sim_dat; by treat; run;

proc means data=sim_dat noprint;
    by treat;
    var ps_score;
    output out=temp min=ps_min max=ps_max;
    run;

proc means data=temp noprint;
    var ps_min ps_max;
    output out=range_ps (keep=lower upper) 
        min(ps_max)=upper max(ps_min)=lower;
    run;

proc sql;
    create table pre_match as
    select a.* from sim_dat a, range_ps b
    where a.ps_score between b.lower and b.upper and nmiss(id, ps_score)=0;
    order by id;  
    quit;

data treat_dat (rename=(id=idT ps_score=pscoreT));
    set pre_match (where=(treat=1));  
    index=ranuni(666);
    run;
    
proc sort data=treat_dat; by index; run;

data control_dat (rename=(id=idC ps_score=pscoreC));
    set pre_match (where=(treat=0));
    run;


options sasautos=(sasautos 'F:\sascode_macro');
%PSMatching(datatreatment= treat_dat, datacontrol= control_dat, method= NN,
	  numberofcontrols= 1, caliper=, replacement= no, out= post_match);

