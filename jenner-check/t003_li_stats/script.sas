/* ==========================================================
   每個 companyID 的 LI 統計量 + 帶出 companyName
   — analysis logic from 碩論LI趨勢整理.sas.
   The original imports paper_patent_final2.xlsx; here the same
   columns (companyID, companyName, year, LI) are supplied inline so
   the PROC MEANS / PROC SORT / MERGE / PROC PRINT logic runs verbatim.
   ========================================================== */

data paper_patent_final2;
    length companyID $10 companyName $24;
    input companyID $ companyName $ year LI;
datalines;
000116 日盛證券 2019 0.142
000116 日盛證券 2020 0.165
000116 日盛證券 2021 0.151
000616 中信證券 2019 0.088
000616 中信證券 2020 0.097
000616 中信證券 2021 0.110
000779 國票證券 2019 0.203
000779 國票證券 2020 0.188
000779 國票證券 2021 0.199
6005 群益證券 2019 0.121
6005 群益證券 2020 0.134
6005 群益證券 2021 0.129
6021 大慶證券 2019 0.076
6021 大慶證券 2020 0.081
6021 大慶證券 2021 0.079
;
run;

/* 計算基本統計量（整體） */
proc means data=paper_patent_final2 n max std min mean median;
    var LI;
run;

/* 分群基本統計量：先依 年、公司 排序 */
proc sort data=paper_patent_final2;
    by year companyID;
run;

/* 分群基本統計量：按年 */
proc means data=paper_patent_final2 n max std min mean median;
    var LI;
    by year;
run;

/* 1) 每個 companyID 的統計量（只保留最細層） */
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

/* 3) 兩邊都排序後再合併 */
proc sort data=stat_byID;    by companyID; run;
proc sort data=company_info; by companyID; run;

data stat_final;
    merge stat_byID(in=a) company_info(in=b);
    by companyID;
    if a; /* 只保留有統計量的公司 */
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

/* 4) 依欄位順序輸出（用 label 顯示中文） */
proc print data=stat_final label noobs;
    var companyID companyName N 最大值 標準差 最小值 平均值 中位數;
run;
