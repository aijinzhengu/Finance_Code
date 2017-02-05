/* ���й�A�����ݸ��� Dellavigna, S., & Pollet, J. M. (2009). 
Investor inattention and friday earnings announcements. 
The Journal of Finance, 64(2), 709�C749. */


/*�õ������ݼ�������CSMAR��
	IAR_Rept��ӯ�๫������ 
	Trd_Index��ָ���������� 
	dsf�����ɽ������� 
	af_forecast������ʦԤ������ 
	af_actual��ʵ��ӯ�� 
	Stk_mkt_thrfacday���ն����������� */

* �������ݺ��������;
libname csmar ( "F:\CSMAR\AF"  "F:\CSMAR\FAnn"  "F:\CSMAR\TR" );
libname temp "C:\Users\wang123\Desktop\temp";


* ӯ�๫�����ڣ�2007-2015���걨 ;
data FAnn (drop=Reptyp label='ӯ�๫�����ڣ�ֻ����2006-2015���걨��');
	set csmar.IAR_Rept (keep=stkcd accper Annodt Reptyp
		where=(Reptyp=4 and '01Jan2007'd<=accper<='31Dec2015'd));
	run;

* �����������ڵ���������2006-01-04�����Ϊ1����һ�������ձ��Ϊ2���Դ����� ;
data tr_calendar (label='���������������������պ������ս���1-1��Ӧ' drop=indexcd);
 	set csmar.Trd_Index (where=(indexcd=1 and '01Jan2005'd<=Trddt<='31Dec2016'd)
						 keep=Trddt indexcd);
run;

proc sort data=tr_calendar; by Trddt; run;

data tr_calendar;
	set tr_calendar;
	tr_index+1;
	run;

* ȷ���¼���;
* ���ӯ�๫�����ǽ������գ���ӯ�๫������Ϊ�¼��գ�
  ���ӯ�๫�����ڷǽ������ڣ���ȡ��һ����������Ϊ�¼��գ������һ�������շ����๫���ղ�����5�� ;
proc sql;  /* cost 53 secs */
	create table evt_date as 
	select a.stkcd, a.accper, a.annodt, b.trddt, b.tr_index from fann a
		left join tr_calendar b
	on a.annodt<=b.trddt<=a.annodt+5
	group by a.stkcd, a.annodt
	having b.trddt-a.annodt=min(b.trddt-a.annodt);
	quit;

data evt_date (label='�¼�ʱ������');
	set evt_date;
	rename Trddt=evtdate;
	label  
		Stkcd='��Ʊ����'
		Trddt='�¼�����'
		Accper='��ƽ�ֹ����'
		tr_index='��2005��������i��������'
		Annodt='���湫������';
run;

* �նȹ�Ʊ�������ݣ��޳�B������ ;
data dsf (drop=Markettype label='�ո��ɽ�������');
	set csmar.dsf (keep=stkcd Trddt Clsprc Dretwd Markettype
		where=('01Jan2005'd<=Trddt<='31Dec2016'd and Markettype in (1,4,16) and 
				nmiss(stkcd, Trddt, Clsprc, Dretwd, Markettype)=0 and 
				dretwd <0.11 and dretwd >-0.11));
	label
		stkcd="֤ȯ����"
		Trddt="��������"
		Clsprc="�����̼�"
		Dretwd="�����ֽ������Ͷ�ʵ��ո��ɻر���";
	run;


* ����ʦԤ�����ݹ��ˣ��γɹ�˾-��-����ʦ���ݣ�
	��1��ֻ����ӯ�๫�������12���µ�ӯ��Ԥ�⣬����
	��2�����һ������ʦ�ж���Ԥ�⣬������������һ��Ԥ�� ;
proc sql;
	create table af_forecast as
	select a.stkcd "��Ʊ����", a.Fenddt "��ƽ�ֹ����", a.Feps "EPSԤ��"
		from csmar.af_forecast(where=('01Jan2006'd<=Fenddt<='31Dec2015'd)) a 
	inner join evt_date b
	on a.stkcd=b.stkcd and a.fenddt=b.accper and 
		intnx('month', b.Annodt, -12, 'B')<a.Rptdt<b.Annodt
	where nmiss(a.stkcd, a.Fenddt, a.Feps)=0
	group by a.stkcd, a.Fenddt, a.AnanmID
		having a.Rptdt=max(a.Rptdt);
quit;


* EPSһ��Ԥ�⣨EPS consensus forecast������˾-������;
proc sql;
	create table eps_cons as  
	select stkcd, Fenddt, median(Feps) as eps_cons from af_forecast
		group by stkcd, Fenddt;
	quit;


data af_actual (label='ʵ�ʹ����EPS');
	set csmar.af_actual (keep= stkcd Ddate Meps
		where=('01Jan2006'd<=ddate<='31Dec2015'd));
	run;

* ӯ�๫����ǰ5�����������̼ۣ���ΪSUE�ķ�ĸ;
proc sql;
	create table prc as
	select a.stkcd, a.accper, b.Clsprc as prc '��׼���̼�'
	from evt_date a 
		inner join Tr_calendar c
	on a.tr_index-5=c.tr_index   
		inner join dsf b
	on a.stkcd=b.stkcd and b.Trddt=c.Trddt;
	quit;

* ӯ�ྪϲ��earnings surprise��;
proc sql;
	create table sue as
	select a.stkcd, a.fenddt, (a.eps_cons-b.Meps)/c.prc as sue "ӯ�ྪϲ" from eps_cons a
		inner join af_actual b
	on a.stkcd=b.stkcd and a.fenddt=b.ddate
		inner join prc c
	on a.stkcd=c.stkcd and a.fenddt=c.Accper
	where not missing(calculated sue);
	quit;


* �¼��о����ƴ���ѡ��ȡ[-280, -34];
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


/* ��ÿ���¼�������������ģ�͵������غ� */
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
	if obs>120;			/* Ҫ����ƴ��ڵĽ����������ٴﵽ120�� */
	label Intercept="�ؾ������ֵ"
		  rm="�г�����ϵ��"
		  smb="��ֵ����ϵ��"
		  hml="��ֵ����ϵ��"
		  obs="��������������Ŀ"
		  _RMSE_="��׼��se��";
	run;


* �����¼�ǰ���ڹ�������ϵ����������׼�ʲ���ϵ�������
	����[0,75]��AR, CAR, BHAR;
proc sql;
create table post_event as
    select a.stkcd, a.accper, a.annodt, a.evtdate,
		   c.tr_index-a.tr_index as re_date "������¼��յ���Խ�����", b.Dretwd, 
		   e.Intercept+e.rm*d.RiskPremium1+e.smb*d.SMB1+e.hml*d.HML1 
		   as ret_bench "��������ģ��ȷ���Ļ�׼������" from evt_date a
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

data evt_stat (keep=stkcd accper re_date bhar label='ʱ���о����õ��쳣���棬���ɲ���');
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


data evt_car (label="�ɼ۵Ķ��ںͳ��ڷ�Ӧ"
			   where=(nmiss(bhar_s, bhar_all)=0));
	merge evt_stat (rename=(bhar=bhar_s) where=(re_date=1))
		  evt_stat (rename=(bhar=bhar_all) where=(re_date=75));
	by stkcd accper;
	run;

data evt_car;
	set evt_car;
	bhar_l=(bhar_all+1)/(bhar_s+1)-1;
	label bhar_s="�ɼ۵Ķ��ڷ�ӦBHAR[0, 1]" 
          bhar_all="�ɼ۵�ȫ����Ӧ[0,75]"
		  bhar_l="�ɼ۵Ķ��ڷ�ӦBHAR[2, 75]";
	run;

* ��ԭ�Ĳ�ͬ�����ǶԱ������塢����(��������������û�й���)��������ڹ�������
	��Ϊ��������ĩ����û�й��棬��������������Ȼ�϶�;
proc sql;
	create table evt_car as
	select a.*, weekday(b.Annodt)-1 as dayinweek "��1-7��ָ��һ������", 
		weekday(b.Annodt) in (1, 6, 7) as weekend "��ĩ������������",
		c.sue from evt_car a 
	inner join fann b on a.stkcd=b.stkcd and a.accper=b.accper
	inner join sue c on a.stkcd=c.stkcd and a.accper=c.fenddt;
quit; 

proc freq data=evt_car;
	tables dayinweek  accper*weekend / nopercent nocol norow nocum;
run; 


* ��ÿ�꣬�ֱ�ԡ���ĩ�����顱�͡����ڹ����顱����ӯ�ྪϲ��С����ֳ�10��;
proc sort data=evt_car; by accper weekend; run;

proc rank data=evt_car groups=10 out=car_by_sue;
	by accper weekend;
	var sue;
	ranks sue_rank;
	run;

data car_by_sue (label='����SUE�����ӯ�๫���쳣����');
	set car_by_sue;
	sue_rank+1;
	run;

proc sql;
	create table caar as 
	select weekend, sue_rank "SUE��ϣ�10Ϊӯ�����",
		mean(bhar_s) as bhaar_s "ÿ��ƽ��BHAR[0,1]", 
		mean(bhar_l) as bhaar_l "ÿ��ƽ��BHAR[2,75]",
		mean(bhar_all) as bhaar_all "ÿ��ƽ��BHAR[0,75]",
		mean(sue) as sue_avg "ÿ��ƽ��SUE"
	from car_by_sue
	group by weekend, sue_rank;
	quit; 


* ��ͼpp721-722;

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






