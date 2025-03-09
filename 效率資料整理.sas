*匯入資料;
proc import out=efficiency_ver1
     datafile= '/home/u64061874/efficiency_ver1.xlsx'
     dbms=xlsx replace;
run;

/*資料處理*/
DATA efficiency_ver2;
    set efficiency_ver1;

/* 刪除缺失值 */
if total_revenue = . then delete;
if capital = . then delete;
if operating_expense = . then delete;
if labour = . then delete;
run;

/*資料排序*/
proc sort data=efficiency_ver2;
     by year;
run;

/*顯示data*/
proc print DATA=efficiency_ver2;
run;

*匯出資料;
proc export data=efficiency_ver2
     outfile='/home/u64061874/efficiency_ver2.xlsx'
     dbms=xlsx replace;
run;
