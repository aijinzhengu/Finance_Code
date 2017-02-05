
# Resample

放回和不放回的重抽样，包括treatment effect中控制组和控制组的匹配。

Finance中常常会用到resample，比如（1）做treatment effect时如果是不放回的匹配需要对样本进行随机化以避免匹配顺序对匹配结果的影响，（2）用bootstrap来获得标准误（standard error）。

先生成模拟数据`sim_dat`。

```sas
data sim_dat;
    call streaminit(1234);
    do id = 1 to 500;
        ps_score = rand('uniform', 0.3, 0.7);
        treat=id<=150;
        output;
    end;
run;

proc print data=sim_dat (firstobs=148 obs=152); run;
```



## 有放回的重抽样(resample with replacement)

bootstrap通常需要有放回的抽样，对原样本重抽样形成1000个bootstrap samples，然后对每个每个bootstrap sample计算感兴趣的统计量，形成1000个统计量。

```sas
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
```


## 无放回的重抽样(resample without replacement)
添加一个辅助列，生成一列随机数，按照这列排序即可。


```sas
data post_sim_dat_2;
    set sim_dat;
    index=ranuni(666);
run;

proc sort data=post_sim_dat_2; by index; run;

data post_sim_dat_2;
    new_id=_n_;
    set post_sim_dat_2 (drop=index);
run;

proc print data=post_sim_dat_2 (obs=4); run;

```


## 无放回的重抽样在treatment effect的应用
treatment effect分析时，匹配处理组和控制组比较常用的是不放回的抽样，对每个处理组观测，从控制组找到1个最接近（按照某种度量，这里以ps_score为例）的观测与之匹配。已经匹配过的观测不再参与匹配。

处理组观测的顺序会影响匹配结果，因此需要对处理组观测随机化。更加麻烦的是，为了让参加过匹配的控制组观测不参与匹配，需要一个动态的容器来装还可以参加匹配的控制组观测。因为，需要在匹配过程中维持一个散列表（hash table）。

在匹配前的预处理，过滤掉不符合overlap假设的样本，共过滤掉13个样本。


```sas
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
    where a.ps_score between b.lower and b.upper
    order by id;  
    quit;
```




对处理组观测随机排序，以消除匹配顺序对匹配结果的影响。


```sas
data treat_dat (rename=(id=idT ps_score=pscoreT));
    set pre_match (where=(treat=1));  
    index=ranuni(666);
    run;
    
proc sort data=treat_dat; by index; run;

data control_dat (rename=(id=idC ps_score=pscoreC));
    set pre_match (where=(treat=0));
    run;
```


利用散列表（hash table）做匹配,使用的是[macro PSmatching](http://home.uchicago.edu/~mcoca/docs/PSmatching.sas)。将文件`PSmatching.sas`放在目录`F:\sascode_macro`下，调用宏即可。

```sas
options sasautos=(sasautos 'F:\sascode_macro');
%PSMatching(datatreatment= treat_dat, datacontrol= control_dat, method= NN,
      numberofcontrols= 1, caliper=, replacement= no, out= post_match);
```
