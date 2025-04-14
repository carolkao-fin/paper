/* 匯入 Excel 資料為 SAS 資料集 */
proc import out=effi_ver4
     datafile="/home/u64061874/effi_ver4.xlsx"
     dbms=xlsx replace;
     sheet="Sheet1"; /* 修改成實際的工作表名稱 */
     getnames=yes;    /* 如果有欄位名稱列 */
run;

/*計算基本統計量*/
proc means data=effi_ver4 n max std min mean median;
           var real_efficiency;
run;

/*分群基本統計量用年和樣本分群並排序*/
proc sort data=effi_ver4;
          by year firm;
run;

/*分群基本統計量用年分群*/
proc means data=effi_ver4 n max std min mean median;
           var real_efficiency;
           by year;
run;

/*分群基本統計量用樣本分群*/
proc means data=effi_frontier n max std min mean median;
    class firm;
    var real_efficiency;
run;