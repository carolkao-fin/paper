*匯入資料;
proc import out=efficiency_result
     datafile= '/home/u64061874/efficiency_result.xlsx'
     dbms=xlsx replace;
run;

/*計算基本統計量*/
proc means data=efficiency_result n max std min mean median;
           var efficiency;
run;

/*分群基本統計量用年和樣本分群並排序*/
proc sort data=efficiency_result;
          by year sample;
run;

/*分群基本統計量用年分群*/
proc means data=efficiency_result n max std min mean median;
           var efficiency;
           by year;
run;

/*分群基本統計量用樣本分群*/
proc means data=efficiency_result n max std min mean median;
    class sample;
    var efficiency;
run;
