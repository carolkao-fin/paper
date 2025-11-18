/* 匯入 Excel 資料為 SAS 資料集 */
proc import out=paper_patent_final2
     datafile="/home/u64061874/paper_patent_final2.xlsx"
     dbms=xlsx replace;
     getnames=yes;    
run;

/*計算基本統計量*/
proc means data=paper_patent_final2 n max std min mean median;
           var efficiency_real;
run;

/*分群基本統計量用年和樣本分群並排序*/
proc sort data=paper_patent_final2;
          by year companyID;
run;

/*分群基本統計量用年分群*/
proc means data=paper_patent_final2 n max std min mean median;
           var efficiency_real;
           by year;
run;

/* 每個 companyID 的統計量 */
proc means data=paper_patent_final2 noprint n max std min mean median;
    class companyID;
    var efficiency_real;
    output out=stat_byID(drop=_type_ _freq_) 
        n=N max=最大值 std=標準差 min=最小值 mean=平均值 median=中位數;
run;

/* 保留 companyID 與對應的 companyName */
proc sort data=paper_patent_final2(keep=companyID companyName) nodupkey 
          out=company_info;
    by companyID;
run;

/* 合併統計結果與公司名稱 */
data stat_final;
    merge stat_byID company_info;
    by companyID;
run;

/* 指定輸出欄位順序 */
proc sql;
    create table stat_final_ordered as
    select companyID, companyName, N, 最大值, 標準差, 最小值, 平均值, 中位數
    from stat_final;
quit;

proc print data=stat_final_ordered;
run;

proc export data=stat_final_ordered
    outfile="/home/u64061874/eff_trend_companyID.xlsx"
    dbms=xlsx replace;
run;
