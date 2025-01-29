*匯入資料1;
proc import out=efficiency_data1
     datafile= '/home/u64061874/efficiency_data1.xlsx'
     dbms=xlsx replace;
run;

/*資料處理*/
DATA efficiency_data3;
    set efficiency_data1;
    drop G H;
run;

/*資料排序*/
proc sort data=efficiency_data3;
     by year;
run;

*匯入資料2;
proc import out=efficiency_data2 
     datafile= '/home/u64061874/efficiency_data2.xlsx'
     dbms=xlsx replace;
run;

/*資料處理*/
DATA efficiency_data4;
    set efficiency_data2;

/* 刪除缺失值 */
/*這段未成功刪除*/
if Brokerage_Revenue = . then delete;
if Underwriting_Revenue = . then delete;
if Director_Compensation = . then delete;
run;

/*資料排序*/
proc sort data=efficiency_data4;
     by year;
run;

/*合併表格*/
proc sql;
create table efficiency_data5 as select e.*,s.*
from efficiency_data3 as e
left join efficiency_data4 as s
on e.company=s.company and e.year=s.year;
quit;
run;

/*資料排序*/
proc sort data=efficiency_data5;
     by year;
run;

/*顯示data*/
proc print DATA=efficiency_data5;
run;

/*刪除未使用到的結果*/
proc delete data=efficiency_data6;
run;

/*匯出檔案*/
proc export data=efficiency_data5 
    outfile='/home/u64061874/efficiency_data5.xlsx'
    dbms=xlsx replace;
run;

*匯入資料6;
proc import out=efficiency_data6
     datafile= '/home/u64061874/efficiency_data6.xlsx'
     dbms=xlsx replace;
run;

/*資料排序*/
proc sort data=efficiency_data6;
     by year;
run;

/*合併表格*/
proc sql;
create table efficiency_data7 as select e.*,s.*
from efficiency_data5 as e
left join efficiency_data6 as s
on e.company=s.company and e.year=s.year;
quit;
run;

/*資料排序*/
proc sort data=efficiency_data7;
     by year;
run;

/*顯示data*/
proc print DATA=efficiency_data7;
run;

/*匯出檔案*/
proc export data=efficiency_data7 
    outfile='/home/u64061874/efficiency_data7.xlsx'
    dbms=xlsx replace;
run;
