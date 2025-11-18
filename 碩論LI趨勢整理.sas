/* 匯入 Excel 資料為 SAS 資料集 */
proc import out=paper_patent_final2
     datafile="/home/u64061874/paper_patent_final2.xlsx"
     dbms=xlsx replace;
     getnames=yes;    
run;

/* 計算基本統計量（整體） */
proc means data=paper_patent_final2 n max std min mean median;
    var LI;
run;

/* 分群基本統計量：先依 年、公司 排序（供 BY 或其他處理用） */
proc sort data=paper_patent_final2;
    by year companyID;
run;

/* 分群基本統計量：按年 */
proc means data=paper_patent_final2 n max std min mean median;
    var LI;
    by year;
run;

/* =========================================
   核心：每個 companyID 的統計量 + 帶出 companyName
   ========================================= */

/* 1) 先做每個 companyID 的統計量（只保留最細層，排除總體列） */
proc means data=paper_patent_final2 nway noprint
           n max std min mean median;
    class companyID;
    var LI;
    output out=stat_byID(drop=_type_ _freq_)
        n   = N
        max = 最大值
        std = 標準差
        min = 最小值
        mean= 平均值
        median = 中位數;
run;

/* 2) 保留 companyID 與對應的 companyName（去重） */
proc sort data=paper_patent_final2(keep=companyID companyName)
          out=company_info nodupkey;
    by companyID;
run;

/* 3) 兩邊都確保排序後再合併 */
proc sort data=stat_byID;    by companyID; run;
proc sort data=company_info; by companyID; run;

data stat_final;
    merge stat_byID(in=a) company_info(in=b);
    by companyID;
    if a; /* 只保留有統計量的公司 */
    /* 加上中文欄位名（label），便於輸出顯示 */
    label
      companyID = 'companyID'
      companyName = 'companyName'
      N      = '觀測值數目'
      最大值  = '最大值'
      標準差  = '標準差'
      最小值  = '最小值'
      平均值  = '平均值'
      中位數  = '中位數';
run;

/* 4) 依你要求的欄位順序輸出（用 label 顯示中文） */
proc print data=stat_final label noobs;
    var companyID companyName N 最大值 標準差 最小值 平均值 中位數;
run;

proc export data=stat_final
    outfile="/home/u64061874/LI_trend_companyID.xlsx"
    dbms=xlsx replace;
run;
