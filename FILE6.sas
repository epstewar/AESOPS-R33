/**********************************************************************************************************************************************
**GOALS
***1. Get pre- mean MME, adjusted intervention and follow-up MME for control and intervention
***2. Get differences pre- to intervention and pre- to follow-up for control and intervention
***3. Get difference-in-differences
***4. Get bootstrapped 95% CIs for pre-, intervention, follow-up, differences, and difference-in-differences 
***5. Add coefficient P values and output diff-in-diff tables to xlsx 
***6. Use macro to execute above on each Rx type 
***********************************************************************************************************************************************/

*output tables;
ods excel file = "/directory/did_tables_3Oct25.xlsx";

*libname 	
libname results "/directory/";

*proc format 
proc format;
	value Parameterf 
	0 = "Prescribers (clinics)"
	1 = "Pre"
	2 = "Post"
	3 = 'Diff'
	4 = 'DiD';
run;

*macro to get adjusted post values and bootstrapped 95% CIs for each Rx type;
%macro did(bpa);
	
*import pre-intervention means from STATA;
proc import datafile =  "/directory/est_&bpa..dta"
	out = est&bpa
	dbms = dta;
run;

*pre-intervention means and CIs;
proc sort data = est&bpa;
	by assignment;
run;

proc means data = est&bpa noprint;
	var avg_total_mme;
	output out = cis (drop = _TYPE_ _FREQ_) mean = pre_mean lclm = pre_lcl uclm = pre_ucl;
	by assignment;
run;

*import 95% boostrapped CIs from FILE5.r;
proc import datafile = "/directory/&bpa._boot.csv"
	out = &bpa._boot
	dbms = csv;
run;

*transpose data;
proc transpose data = &bpa._boot out = &bpa._boott (drop = _NAME_);
	id VAR1;
run;

*create tables for coefficients and CIs to combine with pre- means and CIs;
%macro period(p);

*estimated changes from pre-to-post for control and intervention arms, during post- and follow-up period;
%do i = 0 %to 1;
	
proc sql;
	create table &p.cis&i as 
	select round(t.pre_mean, 0.1) as pre_mean, round(t.pre_lcl, 0.1) as pre_lcl, round(t.pre_ucl, 0.1) as pre_ucl, 
	round((exp(l.&p)-1)*t.pre_mean,0.1) as diff_mean,
	round((exp(l.&p._lcl)-1)*t.pre_lcl,0.1) as diff_lcl,
	round((exp(l.&p._ucl)-1)*t.pre_ucl,0.1) as diff_ucl
	from 
	%if &i = 0 %then %do;
	(select * from cis where assignment = 0) t,
	(select &p, &p._lcl, &p._ucl from &bpa._boott) l;
  %end;
  %else %do;
  (select * from cis where assignment = 1) t,
  (select (&p+&p._did) as &p,
  (&p._lcl+&p._did_lcl) as &p._lcl,
  (&p._ucl+&p._did_ucl) as &p._ucl
  from &bpa._boott) l;
  %end;
quit;

*post means;
data &p.cis&i;
	set &p.cis&i;
	post_mean = round(diff_mean + pre_mean,0.1);
	post_lcl = round(diff_lcl + pre_lcl,0.1);
	post_ucl = round(diff_ucl + pre_ucl,0.1);
run;

*rename columns and create row number to maintain format order;
%macro chng(var, no);
data &p.&var.&i;
	set &p.cis&i (rename = (&var._mean = mean&i &var._lcl = lcl&i &var._ucl = ucl&i));
	Parameter = &no;
	keep Parameter mean&i lcl&i ucl&i;
run;
%mend chng;
%chng(pre, 1);
%chng(diff, 3);
%chng(post, 2);

*combine pre, post, and diff;
data &p.mean&i;
	set &p.pre&i &p.post&i &p.diff&i;
run;
%end;

*combine control and intervention;
proc sql;
	create table &p.&bpa as 
	select t.*, l.mean1, l.lcl1, l.ucl1 from &p.mean0 t
	left join 
	&p.mean1 l 
	on t.Parameter = l.Parameter;
quit;

*difference-in-differenes;
data &p.&bpa.did;
	set &p.&bpa;
	did = round(mean1 - mean0,0.1);
	did_lcl = round(lcl1 - lcl0,0.1);
	did_ucl = round(ucl1 - ucl0,0.1);
	keep did did_lcl did_ucl;
	if parameter = 3 then output;
run;

*rename DiD;
data &p.&bpa;
	set &p.&bpa &p.&bpa.did (rename = (did = mean0 did_lcl = lcl0 did_ucl = ucl0));
	if parameter = . then parameter = 4;
run;

*combine DiD and 95% CIs;
proc sql;
create table &p.&bpa as
select parameter, 
catx(" ", mean0, cat("(", lcl0, ", ", ucl0,")")) as Control,
catx(" ", mean1, cat("(", lcl1, ", ", ucl1,")")) as Intervention
from &p.&bpa;
quit;

*number of clinicians and clinics;
proc sql;
	create table &p.&bpa.ct as 
	select assignment, cat(ct_prov, " (", ct_clinic, ")") as ct from
	(select count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, assignment from est&bpa
	group by assignment);
quit;

*transpose counts;
proc transpose data = &p.&bpa.ct out = &p.&bpa.ctt (drop = _NAME_);
	var ct;
run;

*rename columns and add parameter for format;
data &p.&bpa.ctt;
	set &p.&bpa.ctt (rename = (COL1 = Control COL2 = Intervention));
	parameter = 0;
run;

*append clinician and clinic counts to DiD table;
data &p.&bpa.total;
	retain parameter control intervention;
	set &p.&bpa.ctt &p.&bpa;
	if parameter = 4 then intervention = '';
run;

*print for ods excel with format;
proc print data = &p.&bpa.total;
	format parameter parameterf.;
	title "&bpa";
run;
	
*end time period macro;
%mend period;
%period(int);
%period(follow);

*end BPA macro;
%mend did;
%did(A);
%did(B);
%did(C);
%did(AB);
%did(ABC);
%did(None);
%did(total);
ods excel close;

