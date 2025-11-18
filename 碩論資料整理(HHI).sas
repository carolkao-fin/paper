/* ==========================================================
   0) 基本設定（通過後想看詳情可把 notes 打開）
========================================================== */
options nonotes nostimer nosource msglevel=i;

/* ==========================================================
   1) 匯入：income（含 companyID, companyName, year, BR）
            hhidata（含 companyID, year, industry）
========================================================== */
proc import out=income
    datafile="/home/u64061874/income.xlsx"
    dbms=xlsx replace; getnames=yes;
run;

proc import out=hhidata
    datafile="/home/u64061874/HHI.xlsx"
    dbms=xlsx replace; getnames=yes;
run;

/* ==========================================================
   2) 建立不改內容的 join key（companyID_key），並把 BR→income_num
   - companyID_key：不補零、不截斷，僅去除前後空白（以便和未來資料對齊）
   - income_num：容錯字串/數值/含千分位，遇到 '-', '.', 'NA', 'NULL' 視為缺
========================================================== */
data income_key;
  set income;
  length companyID_key $64 _br_char $200;

  /* companyID 原樣字串化做 key（避免型別 484） */
  companyID_key = strip(vvalue(companyID));

  /* BR 轉數值 */
  _br_char = compress(vvalue(BR), ', ');
  if missing(_br_char) or upcase(_br_char) in ('-', '.', 'NA', 'NULL') then income_num = .;
  else income_num = inputn(_br_char, 'best32.');

  drop _br_char;
run;

/* 可選：排除彙總/分類列，避免把「整體」當公司計算（若無這些代碼可略） */
data income_key;
  set income_key;
  if upcase(companyID_key) in ('T3000','M3000','OTC30') then delete;
run;

data hhidata_key;
  set hhidata;
  length companyID_key $64;
  companyID_key = strip(vvalue(companyID));
  keep companyID_key year industry;
run;

/* ==========================================================
   3) 先用 companyID 合併 industry；若有同年紀錄則同年優先，否則退回僅用 companyID
========================================================== */
proc sql;
  /* 只用 companyID 聚合出一個 industry（若同公司多產業，之後仍以同年優先） */
  create table hhi_by_id as
  select companyID_key, /* 任取一個 industry 作後備（這裡以第一筆為準） */
         max(industry) as industry length=40
  from hhidata_key
  group by companyID_key;

  /* 同年優先合併，退回僅 companyID 的後備 industry */
  create table merged_data as
  select a.companyID,
         a.companyName,
         a.year,
         a.income_num,
         coalesce(b.industry, c.industry) as industry length=40
  from income_key as a
  left join hhidata_key as b
    on a.companyID_key=b.companyID_key and a.year=b.year
  left join hhi_by_id as c
    on a.companyID_key=c.companyID_key
  ;
quit;

/* （檢查用，可保留或移除）
proc sql;
  select count(*) as n_all,
         sum(missing(year))      as miss_year,
         sum(missing(industry))  as miss_industry,
         sum(missing(income_num))as miss_income
  from merged_data;
quit;
*/

/* ==========================================================
   4) 以 income 計算 HHI：每年×產業總收入 → 市佔率 → HHI（0–1 與 ×10000）
========================================================== */
proc sql;
  create table industry_total as
  select year, industry, sum(income_num) as total_income
  from merged_data
  group by year, industry;
quit;

proc sql;
  create table hhi_prep as
  select a.*,
         b.total_income,
         case when b.total_income>0 then a.income_num / b.total_income
              else . end as share
  from merged_data as a
  left join industry_total as b
    on a.year=b.year and a.industry=b.industry;
quit;

proc sql;
  create table hhi_result as
  select year, industry,
         sum(share*share) as hhi_raw,
         calculated hhi_raw*10000 as hhi_10000
  from hhi_prep
  group by year, industry;
quit;

/* === 加入 industry_number 對照表 === */
data hhi_result2;
    set hhi_result;
    length industry_number 8;
    select (industry);
        when ('投資')      industry_number = 1;
        when ('投顧')      industry_number = 2;
        when ('期貨')      industry_number = 3;
        when ('證券')      industry_number = 4;
        when ('證金公司')  industry_number = 5;
        when ('其他')      industry_number = 6;
        otherwise industry_number = .;
    end;
run;

/* === 排序 === */
proc sort data=hhi_result2 out=hhi_result2_sorted;
    by year industry_number;
run;

/* === 匯出檢查用 === */
proc export data=hhi_result2_sorted
    outfile="/home/u64061874/hhi_result2_sorted.xlsx"
    dbms=xlsx replace;
run;

/* === 合併 sample === */
proc sql;
    create table paper_HHI_merged as
    select e.*, s.hhi_raw, s.hhi_10000
    from paper_sample_HHI as e
    left join hhi_result2_sorted as s
      on e.year = s.year 
     and e.industry_number = s.industry_number;
quit;

/* === 最終表 === */
proc sql;
  create table paper_HHI_final as
  select
    companyID,
    companyName,
    year,
    industry,
    industry_number,
    hhi_raw,
    hhi_10000
  from paper_HHI_merged;
quit;

/* === 排序並輸出 === */
proc sort data=paper_HHI_final out=paper_HHI_final_sorted;
    by year companyID;
run;

proc export data=paper_HHI_final_sorted
    outfile="/home/u64061874/paper_HHI_final.xlsx"
    dbms=xlsx replace;
run;