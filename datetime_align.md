#日期（时间）数据对齐

在finance领域，将时间序列对齐（align）是数据处理中经常要用到的，这种对齐可能是时点的对齐（point-in-time），如匹配公司上一年末的财报信息，也可能要对齐到一个区间（interval），如根据过去6个月的股票收益构建投资组合，根据过去8个季度的盈余计算盈余的波动性。利用SAS时间序列处理函数`INTNX`可以比较容易的移动时间序列数据，请看下面的例子。

```
data datetime;
    input stkcd date ;
    date_in_point1=intnx('month', date, 1, 'E');     /* 移动到下个月初 */
    date_in_point2=intnx('month', date, 1, 'B');     /* 移动到下个月末 */
    date_in_point3=intnx('year', date, -1, 'E');     /* 移动到去年末 */
    date_in_point4=intnx('qtr', date, -1, 'E');      /* 移动到上个季度底 */
    * 取[-1, -13]月度窗口;
    date_interval_right1=intnx('month', date, -2, 'E');
    date_interval_left1=intnx('month', date, -13, 'B');
    * 取过去8个季度;
    date_interval_right2=intnx('qtr', date, -1, 'E');
    date_interval_left2=intnx('qtr', date, -8, 'B');

    format date date_in_point1 date_in_point2 date_in_point3 date_in_point4
    date_interval_left1 date_interval_left2 date_interval_right1 date_interval_right2
    mmddyy10.;
    
    label   date_in_point1='移动到下个月初'
            date_in_point2='移动到下个月初' 
            date_in_point3='移动到去年末'      
            date_in_point4='移动到上个季度底'
            date_interval_left1='取[-1, -13]月度窗口开始'  
            date_interval_right1='取[-1, -13]月度窗口结束'
            date_interval_left2='取过去8个季度开始'  
            date_interval_right2='取过去8个季度结束';
            
datalines;
0000001 20000
0000001 20030
0000002 20060
6000003 20090
6000020 20120
;
run;

proc print data=datetime label; run;
```



