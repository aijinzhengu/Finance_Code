/* 用中国A股数据复制 Dellavigna, S., & Pollet, J. M. (2009). 
Investor inattention and friday earnings announcements. 
The Journal of Finance, 64(2), 709–749. */


/*用到的数据集，来自CSMAR：
	IAR_Rept：盈余公告日期 
	Trd_Index：指数交易数据 
	dsf：个股交易数据 
	af_forecast：分析师预测数据 
	af_actual：实际盈余 
	Stk_mkt_thrfacday：日度三因子数据 */

* 输入数据和输出数据;
libname csmar ( "F:\CSMAR\AF"  "F:\CSMAR\FAnn"  "F:\CSMAR\TR" );
libname temp "C:\Users\wang123\Desktop\temp";


* 盈余公告日期，2007-2015年年报 ;
data FAnn (drop=Reptyp label='盈余公告日期（只包括2006-2015年年报）');
	set csmar.IAR_Rept (keep=stkcd accper Annodt Reptyp
		where=(Reptyp=4 and '01Jan2007'd<=accper<='31Dec2015'd));
	run;

* 建立交易日期的索引，‘2006-01-04’标记为1，下一个交易日标记为2，以此类推 ;
data tr_calendar (label='构建交易日历：将交易日和日历日建立1-1对应' drop=indexcd);
 	set csmar.Trd_Index (where=(indexcd=1 and '01Jan2005'd<=Trddt<='31Dec2016'd)
						 keep=Trddt indexcd);
run;

proc sort data=tr_calendar; by Trddt; run;

data tr_calendar;
	set tr_calendar;
	tr_index+1;
	run;

* 确定事件日;
* 如果盈余公告日是交易日日，以盈余公告日作为事件日；
  如果盈余公告日在非交易日期，则取下一个交易日期为事件日，如果下一个交易日发生距公告日不超过5天 ;
proc sql;  /* cost 53 secs */
	create table evt_date as 
	select a.stkcd, a.accper, a.annodt, b.trddt, b.tr_index from fann a
		left join tr_calendar b
	on a.annodt<=b.trddt<=a.annodt+5
	group by a.stkcd, a.annodt
	having b.trddt-a.annodt=min(b.trddt-a.annodt);
	quit;

data evt_date (label='事件时期数据');
	set evt_date;
	rename Trddt=evtdate;
	label  
		Stkcd='股票代码'
		Trddt='事件日期'
		Accper='会计截止日期'
		tr_index='自2005年以来第i个交易日'
		Annodt='报告公布日期';
run;

* 日度股票交易数据，剔除B股数据 ;
data dsf (drop=Markettype label='日各股交易数据');
	set csmar.dsf (keep=stkcd Trddt Clsprc Dretwd Markettype
		where=('01Jan2005'd<=Trddt<='31Dec2016'd and Markettype in (1,4,16) and 
				nmiss(stkcd, Trddt, Clsprc, Dretwd, Markettype)=0 and 
				dretwd <0.11 and dretwd >-0.11));
	label
		stkcd="证券代码"
		Trddt="交易日期"
		Clsprc="日收盘价"
		Dretwd="考虑现金红利再投资的日个股回报率";
	run;


* 分析师预测数据过滤，形成公司-年-分析师数据：
	（1）只保留盈余公告日最近12个月的盈利预测，并且
	（2）如果一个分析师有多项预测，则仅保留最近的一次预测 ;
proc sql;
	create table af_forecast as
	select a.stkcd "股票代码", a.Fenddt "会计截止日期", a.Feps "EPS预测"
		from csmar.af_forecast(where=('01Jan2006'd<=Fenddt<='31Dec2015'd)) a 
	inner join evt_date b
	on a.stkcd=b.stkcd and a.fenddt=b.accper and 
		intnx('month', b.Annodt, -12, 'B')<a.Rptdt<b.Annodt
	where nmiss(a.stkcd, a.Fenddt, a.Feps)=0
	group by a.stkcd, a.Fenddt, a.AnanmID
		having a.Rptdt=max(a.Rptdt);
quit;


* EPS一致预测（EPS consensus forecast），公司-年数据;
proc sql;
	create table eps_cons as  
	select stkcd, Fenddt, median(Feps) as eps_cons from af_forecast
		group by stkcd, Fenddt;
	quit;


data af_actual (label='实际公告的EPS');
	set csmar.af_actual (keep= stkcd Ddate Meps
		where=('01Jan2006'd<=ddate<='31Dec2015'd));
	run;

* 盈余公告日前5个交易日收盘价，作为SUE的分母;
proc sql;
	create table prc as
	select a.stkcd, a.accper, b.Clsprc as prc '基准收盘价'
	from evt_date a 
		inner join Tr_calendar c
	on a.tr_index-5=c.tr_index   
		inner join dsf b
	on a.stkcd=b.stkcd and b.Trddt=c.Trddt;
	quit;

* 盈余惊喜（earnings surprise）;
proc sql;
	create table sue as
	select a.stkcd, a.fenddt, (a.eps_cons-b.Meps)/c.prc as sue "盈余惊喜" from eps_cons a
		inner join af_actual b
	on a.stkcd=b.stkcd and a.fenddt=b.ddate
		inner join prc c
	on a.stkcd=c.stkcd and a.fenddt=c.Accper
	where not missing(calculated sue);
	quit;


* 事件研究估计窗口选择，取[-280, -34];
proc sql;
	create table pre_event as 
	select a.stkcd, a.accper, b.Dretwd,
		   d.RiskPremium1 as rm, d.SMB1 as smb, d.HML1 as hml from evt_date a
	left join tr_calendar c
		on a.tr_index-280 <=c.tr_index<=a.tr_index -34
	left join dsf b
		on b.Trddt=c.Trddt and b.stkcd=a.stkcd
	left join csmar.Stk_mkt_thrfacday (keep=TradingDate RiskPremium1 SMB1 HML1 MarkettypeID   
									   where=(MarkettypeID='P9709')) d
		on b.Trddt=d.TradingDate
	where nmiss(Dretwd, rm, smb, hml)=0
	order by stkcd, accper;
quit; 


/* 对每个事件，计算三因子模型的因子载荷 */
proc printto log=junk; run;
proc reg data=pre_event noprint outest=ff_est edf;
	by stkcd accper;
	model Dretwd = rm smb hml;
	quit;
proc printto; run;

data ff_est;
	set ff_est;
	obs=_EDF_+_P_;
	keep stkcd accper Intercept rm smb hml obs _RMSE_; 
	if obs>120;			/* 要求估计窗口的交易日期至少达到120天 */
	label Intercept="截距项估计值"
		  rm="市场因子系数"
		  smb="市值因子系数"
		  hml="价值因子系数"
		  obs="估计所用样本数目"
		  _RMSE_="标准误（se）";
	run;


* 利用事件前窗口估计所得系数，建立基准资产组合的收益率
	估计[0,75]的AR, CAR, BHAR;
proc sql;
create table post_event as
    select a.stkcd, a.accper, a.annodt, a.evtdate,
		   c.tr_index-a.tr_index as re_date "相对于事件日的相对交易日", b.Dretwd, 
		   e.Intercept+e.rm*d.RiskPremium1+e.smb*d.SMB1+e.hml*d.HML1 
		   as ret_bench "由三因子模型确定的基准收益率" from evt_date a
	left join tr_calendar c
		on a.tr_index <=c.tr_index<=a.tr_index +75
	left join dsf b
		on b.Trddt=c.Trddt and b.stkcd=a.stkcd
	left join csmar.Stk_mkt_thrfacday (keep=TradingDate RiskPremium1 SMB1 HML1 MarkettypeID   
									   where=(MarkettypeID='P9709')) d
		on b.Trddt=d.TradingDate
	left join ff_est e
		on a.stkcd=e.stkcd and a.accper=e.accper
	where nmiss(Dretwd, calculated ret_bench)=0
	order by stkcd, accper, re_date;
quit; 

data evt_stat (keep=stkcd accper re_date bhar label='时间研究所得的异常收益，个股层面');
	set post_event;
	by stkcd accper;
	ar=Dretwd-ret_bench;
	retain cumret cumbenchret car;
	cumret=cumret*(1+Dretwd);
	cumbenchret=cumbenchret*(1+ret_bench);
	car=car+ar;
	if first.accper then do;
		car=ar;
		cumret=1+Dretwd;
		cumbenchret=1+ret_bench;
	end;
	bhar=cumret-cumbenchret;
run;


data evt_car (label="股价的短期和长期反应"
			   where=(nmiss(bhar_s, bhar_all)=0));
	merge evt_stat (rename=(bhar=bhar_s) where=(re_date=1))
		  evt_stat (rename=(bhar=bhar_all) where=(re_date=75));
	by stkcd accper;
	run;

data evt_car;
	set evt_car;
	bhar_l=(bhar_all+1)/(bhar_s+1)-1;
	label bhar_s="股价的短期反应BHAR[0, 1]" 
          bhar_all="股价的全部反应[0,75]"
		  bhar_l="股价的短期反应BHAR[2, 75]";
	run;

* 和原文不同，我们对比在周五、周六(我们样本中周日没有公告)相对于周内公告的情况
	因为美国在周末几乎没有公告，国内周六公告仍然较多;
proc sql;
	create table evt_car as
	select a.*, weekday(b.Annodt)-1 as dayinweek "用1-7代指周一至周日", 
		weekday(b.Annodt) in (1, 6, 7) as weekend "周末公告的虚拟变量",
		c.sue from evt_car a 
	inner join fann b on a.stkcd=b.stkcd and a.accper=b.accper
	inner join sue c on a.stkcd=c.stkcd and a.accper=c.fenddt;
quit; 

proc freq data=evt_car;
	tables dayinweek  accper*weekend / nopercent nocol norow nocum;
run; 


* 在每年，分别对“周末公告组”和“周内公告组”按照盈余惊喜从小到大分成10组;
proc sort data=evt_car; by accper weekend; run;

proc rank data=evt_car groups=10 out=car_by_sue;
	by accper weekend;
	var sue;
	ranks sue_rank;
	run;

data car_by_sue (label='按照SUE分组的盈余公告异常收益');
	set car_by_sue;
	sue_rank+1;
	run;

proc sql;
	create table caar as 
	select weekend, sue_rank "SUE组合，10为盈余最高",
		mean(bhar_s) as bhaar_s "每组平均BHAR[0,1]", 
		mean(bhar_l) as bhaar_l "每组平均BHAR[2,75]",
		mean(bhar_all) as bhaar_all "每组平均BHAR[0,75]",
		mean(sue) as sue_avg "每组平均SUE"
	from car_by_sue
	group by weekend, sue_rank;
	quit; 


* 画图pp721-722;

proc sgplot data=caar;
	series x=sue_rank y=bhaar_s / group=weekend;
	refline 0 / axis=x;
run;

proc sgplot data=caar;
	series x=sue_rank y=bhaar_l / group=weekend;
run;

proc sgplot data=caar;
	series x=sue_avg y=bhaar_l / group=weekend;
run;






