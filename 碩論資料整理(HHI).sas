/* 步驟1：匯入 Excel 檔案（不指定 sheet，直接抓第一個工作表） */
proc import out=hhidata
    datafile="/home/u64061874/HHI.xlsx"
    dbms=xlsx
    replace;
    getnames=yes;
run;

/* 步驟2：將 asset 轉為數值型態（asset_num） */
data hhidata2;
    set hhidata;
    /* 移除千分位符號與空白，再轉成數值 */
    asset_clean = compress(asset, ', ');
    asset_num = input(asset_clean, best32.);
run;

/* 步驟3：計算每年每產業總資產 */
proc sql;
    create table industry_total as
    select year, industry, sum(asset_num) as total_asset
    from hhidata2
    group by year, industry;
quit;

/* 步驟4：計算每公司市佔率 */
proc sql;
    create table hhi_prep as
    select a.*, 
           b.total_asset,
           (a.asset_num / b.total_asset) as share
    from hhidata2 as a
    left join industry_total as b
    on a.year = b.year and a.industry = b.industry;
quit;

/* 步驟5：計算 HHI 指數（*10000） */
proc sql;
    create table hhi_result as
    select year, industry, 
           sum(share*share) as hhi_raw,
           sum(share*share)*10000 as hhi
    from hhi_prep
    group by year, industry;
quit;

/* 步驟6：輸出結果為 Excel 檔案 */
proc export data=hhi_result
    outfile="/home/u64061874/hhi_result.xlsx"
    dbms=xlsx
    replace;
run;

/* === 1) 在 hhi_result 加入 industry_number 對照表 === */
data hhi_result2;
    set hhi_result;
    length industry_number 8;  /* 確保是數值型態 */

    select (industry);
        when ('投資')      industry_number = 1;
        when ('投顧')      industry_number = 2;
        when ('期貨')      industry_number = 3;
        when ('證券')      industry_number = 4;
        when ('證金公司')  industry_number = 5;
        when ('其他')      industry_number = 6;
    end;
run;

/* === 2) 按照 industry_number、year 排序 hhi_result2 === */
proc sort data=hhi_result2 out=hhi_result2_sorted;
    by year industry_number;
run;

/* === 3) 匯出 hhi_result2_sorted === */
proc export data=hhi_result2_sorted
    outfile="/home/u64061874/hhi_result2_sorted.xlsx"
    dbms=xlsx replace;
run;

/* === 4) 跟 paper_sample_HHI 合併 (共通點：year + industry_number) === */
proc sql;
    create table paper_HHI_merged as
    select e.*, s.hhi_raw, s.hhi
    from paper_sample_HHI as e
    left join hhi_result2_sorted as s
      on e.year = s.year 
     and e.industry_number = s.industry_number;
quit;

/* === 5) 建立 paper_HHI_final，並重命名與指定欄位順序 === */
proc sql;
  create table paper_HHI_final as
  select
    id   as companyID   length=200,
    name as companyName length=200,
    year,
    industry,
    industry_number,
    hhi_raw,
    hhi
  from paper_HHI_merged;
quit;

/* === 6) 排序並輸出 === */
proc sort data=paper_HHI_final out=paper_HHI_final_sorted;
    by year companyID;
run;

proc export data=paper_HHI_final_sorted
    outfile="/home/u64061874/paper_HHI_final.xlsx"
    dbms=xlsx replace;
run;