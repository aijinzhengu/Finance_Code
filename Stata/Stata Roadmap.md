# Stata Roadmap

####	从STATA USER’S GUIDE起步

Stata是个大的工具箱，我们得知道这个工具箱有哪些工具，哪些工具能够帮助我们解决哪些常用的问题。`STATA USER’S GUIDE`是overview，介绍这个软件有哪些特色，哪些模块。


在数据处理中遇到问题，可以对问题分类，判断问题落入USER’S GUIDE哪个章节里。Stata的基本语法，看`11 Language syntax`。如果处理日期型数据，要先读`24 Working with dates and times`。Stata能做哪些估计，有`26 Overview of Stata estimation commands`，如果要做久期分析再找`26.20 Survival-time (failure-time) models`。做假设检验看`20.12 Performing hypothesis tests on the coefficients`。


STATA USER’S GUIDE只是对Stata粗勾轮廓，应当每个部分都比较清楚。

####	从问题导向学习具体命令

学好关键命令，如描述统计有**summarize / tabstat / table / tabulate / collapse**，要清楚它们的区别。

####	具备一点编程基础，算是进阶

1. 会写循环foreach / forvalues。如对变量循环。

2. 善用macro。如用来记录不同组的控制变量。

3. 会写Program，带参数的。如将事件研究打包成一个Program。

4. 如果具备矩阵知识，最好会点Mata。Stata很多底层换成Mata实现，快。

####	阅读别人的代码，以下是一些经典论文及stata实现

- iv估计: [Acemoglu, Johnson, and Robinson (2001)](http://economics.mit.edu/faculty/acemoglu/data/ajr2001)

- did分析：[Qian and Nunn (2011)](http://aida.wss.yale.edu/~nq3/NANCYS_Yale_Website/resources/papers/NUNN_QIAN_QJE_2011_REPLICATION_FILES.zip)

- rdd分析：[Angrist and Lavy (1999)](http://economics.mit.edu/faculty/angrist/data1/data/anglavy99)

- 分位数回归：[Angrist, Chernozhukov, and Fernandez-Val (2006)](http://economics.mit.edu/faculty/angrist/data1/data/angchefer06)

####	有做一个项目的意识

- 建立自己的流程，有个系统的观点。总结与提高的过程，然后不断实践。
    + [Code and Data for the Social Sciences: A Practitioner's Guide](http://web.stanford.edu/~gentzkow/research/CodeAndData.xhtml#magicparlabel-20)
    + [The Workflow of Data Analysis Using Stata](http://www.stata.com/bookstore/workflow-data-analysis-stata/)


- 实例，一篇论文，成熟度复杂度比较高的项目
    + 如 http://economics.mit.edu/files/11790

####	其他Stata优质资源

- [Germán Rodríguez Stata Tutorial](http://data.princeton.edu/stata/)

- [UCLA stata](http://statistics.ats.ucla.edu/stat/stata/)（初学上路） 

- [Stata Journal](http://www.stata-journal.com)（专题，深入谈一个问题） 

- [Statalist](http://www.statalist.org/forums/)（论坛，提问回答，解决小问题） 


