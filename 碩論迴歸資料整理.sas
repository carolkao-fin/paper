/* ==========================================================
   0) 基本設定（除錯時可把 notes 打開）
========================================================== */
options nonotes nostimer nosource msglevel=i;

/* ==========================================================
   1) 匯入資料
========================================================== */
proc import out=paper_patent_apply
    datafile="/home/u64061874/paper_patent_apply.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_LI_result_final2
    datafile="/home/u64061874/paper_LI_result_final2.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_HHI_final
    datafile="/home/u64061874/paper_HHI_final.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=frontier_efficiency
    datafile="/home/u64061874/frontier_efficiency.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=comparison_table
    datafile="/home/u64061874/comparison_table.xlsx"
    dbms=xlsx replace; getnames=yes; run;

/* ==========================================================
   2) 標準化鍵值
   - 將 sample 統一成字元欄位 sample_c（避免 strip() 型別錯誤）
   - 統一 companyID 為字元、去空白
========================================================== */
/* comparison_table → 取 sample→companyID 的唯一對應 */
data _ct;
    length sample_c $200 companyID $16;
    set comparison_table(keep=sample companyID);
    companyID = strip(companyID);
    if vtype(sample)='C' then sample_c = strip(sample);
    else sample_c = strip(put(sample, best32.)); /* 數值轉字元 */
run;
proc sort data=_ct nodupkey; by sample_c; run;

/* frontier_efficiency → 建立 sample_c 與 year_new(西元年) */
data _fe;
    length sample_c $200;
    set frontier_efficiency; /* 假設含 sample, year, efficiency_real */
    if vtype(sample)='C' then sample_c = strip(sample);
    else sample_c = strip(put(sample, best32.));
    year_new = year + 2002;  /* 1→2003, 2→2004, ... */
run;

/* 主表：維持西元年；只留指定欄位並去空白 */
data _patent_base;
    length companyID $16 companyName $200;
    set paper_patent_apply
        (keep=companyID companyName year
              invention_acc_app new_acc_app design_acc_app total_acc_app
              invention_sin_app new_sin_app design_sin_app total_sin_app);
    companyID   = strip(companyID);
    companyName = strip(companyName);
run;

/* LI/MC/LI：key = companyID + year */
data _li;
    length companyID $16;
    set paper_LI_result_final2(keep=companyID year P MC LI);
    companyID = strip(companyID);
run;

/* HHI：從 paper_HHI_final 取 hhi_raw，若為字串先轉數值，再改名為 hhi；去重（companyID-year 唯一） */
data _hhi_prep;
    length companyID $16 hhi 8;
    set paper_HHI_final(keep=companyID year hhi_raw);
    companyID = strip(companyID);
    if vtype(hhi_raw)='C' then do;
        hhi = input(compress(hhi_raw, ', '), best32.);
    end;
    else hhi = hhi_raw;
    drop hhi_raw;
run;
proc sort data=_hhi_prep out=_hhi_dedup nodupkey; by companyID year; run;

/* ==========================================================
   3) 由 sample_c 取得 companyID，並帶入效率與西元年
========================================================== */
proc sql;
    create table _eff as
    select 
        ct.companyID length=16,
        fe.sample_c,
        fe.year        as year_code,  /* 原始 1,2,3...（檢核用） */
        fe.year_new,                  /* 西元年 */
        fe.efficiency_real
    from _fe as fe
    left join _ct as ct
      on fe.sample_c = ct.sample_c
    ;
quit;

/* ==========================================================
   4) 合併（以主表為左表）
      - LI/MC/LI：companyID + year
      - HHI：companyID + year（使用 hhi_raw 轉來的 hhi）
      - 效率：companyID + (year_new = 主表 year)
========================================================== */
proc sql;
    create table _joined as
    select
        p.companyID,
        p.companyName,
        p.year,
        p.invention_acc_app,
        p.new_acc_app,
        p.design_acc_app,
        p.total_acc_app,
        p.invention_sin_app,
        p.new_sin_app,
        p.design_sin_app,
        p.total_sin_app,
        l.P,
        l.MC,
        l.LI,
        h.hhi,
        e.efficiency_real
    from _patent_base as p
    left join _li as l
      on p.companyID = l.companyID and p.year = l.year
    left join _hhi_dedup as h
      on p.companyID = h.companyID and p.year = h.year
    left join _eff as e
      on p.companyID = e.companyID and p.year = e.year_new
    ;
quit;

/* ==========================================================
   5) 產出未刪缺值版本（欄位順序固定）→ paper_patent_merge
========================================================== */
data paper_patent_merge;
    length companyID $16 companyName $200;
    retain
        companyID companyName year
        invention_acc_app new_acc_app design_acc_app total_acc_app
        invention_sin_app new_sin_app design_sin_app total_sin_app
        P MC LI hhi efficiency_real
    ;
    set _joined(keep=
        companyID companyName year
        invention_acc_app new_acc_app design_acc_app total_acc_app
        invention_sin_app new_sin_app design_sin_app total_sin_app
        P MC LI hhi efficiency_real
    );
run;

proc sort data=paper_patent_merge; by year companyID; run;

proc export data=paper_patent_merge
    outfile="/home/u64061874/paper_patent_merge.xlsx"
    dbms=xlsx replace;
    sheet="merged";
run;

/* ==========================================================
   6) 只要求 5 指標不缺，且樣本框限定為三表交集 → paper_patent_merge2
========================================================== */

/* 6-1) 建交集鍵（companyID + year） */
proc sql;
  create table _int_keys as
  select distinct p.companyID, p.year
  from (select distinct companyID, year from _patent_base) as p
  inner join (select distinct companyID, year from _li)        as l
    on p.companyID=l.companyID  and p.year=l.year
  inner join (select distinct companyID, year from _hhi_dedup) as h
    on p.companyID=h.companyID  and p.year=h.year
  inner join (select distinct companyID, year_new as year 
              from _eff where not missing(companyID))          as e
    on p.companyID=e.companyID  and p.year=e.year
  ;
quit;

/* 6-2) 依交集鍵過濾，再只卡五個指標欄位 */
proc sort data=paper_patent_merge out=paper_patent_merge_s; by companyID year; run;
proc sort data=_int_keys; by companyID year; run;

data paper_patent_merge2;
  merge paper_patent_merge_s(in=a) _int_keys(in=b);
  by companyID year;
  if a and b;  /* 只留交集的 key（你先前檢核為 1221） */
  if cmiss(of P MC LI hhi efficiency_real) = 0;  /* 只卡五欄不缺 */
run;

proc sort data=paper_patent_merge2; by year companyID; run;

/* 6-3) 快速檢核：行數與 key 數 */
proc sql;
  select count(*) as rows_merge2,
         count(distinct catx('_',companyID,year)) as keys_merge2
  from paper_patent_merge2;
quit;

/* 6-4) 匯出 */
proc export data=paper_patent_merge2
    outfile="/home/u64061874/paper_patent_merge2.xlsx"
    dbms=xlsx replace;
    sheet="merge2";
run;

/*合併控制變數*/
/* ======================================================
   0) 匯入資料
====================================================== */
proc import out=paper_patent_merge2
    datafile="/home/u64061874/paper_patent_merge2.xlsx"
    dbms=xlsx replace; 
    getnames=yes; 
run;

proc import out=paper_control1
    datafile="/home/u64061874/paper_control1.xlsx"
    dbms=xlsx replace; 
    getnames=yes; 
run;

proc import out=paper_control2
    datafile="/home/u64061874/paper_control2.xlsx"
    dbms=xlsx replace; 
    getnames=yes; 
run;

proc import out=paper_control3
    datafile="/home/u64061874/paper_control3.xlsx"
    dbms=xlsx replace; 
    getnames=yes; 
run;

proc import out=paper_control4
    datafile="/home/u64061874/paper_control4.xlsx"
    dbms=xlsx replace; 
    getnames=yes; 
run;


/* ======================================================
   1) 合併 control1~4
====================================================== */
proc sql;
    create table _merged as
    select a.*,
           b.total_asset,
           b.equity,
           b.carrent_ratio,
           c.MSO,
           c.BS,
           d.age,
           e.BR,
           e.UR
    from paper_patent_merge2 as a
    left join paper_control1 as b
        on a.companyID = b.companyID and a.year = b.year
    left join paper_control2 as c
        on a.companyID = c.companyID and a.year = c.year
    left join paper_control3 as d
        on a.companyID = d.companyID and a.year = d.year
    left join paper_control4 as e
        on a.companyID = e.companyID and a.year = e.year
    ;
quit;


/* ======================================================
   2) 衍生變數：size, Lev, ln_BR, ln_UR
====================================================== */
data _merged2;
    set _merged;

    /* size, Lev */
    if total_asset > 0 then size = log(total_asset);
    if equity ne 0 then Lev = total_asset / equity;

    /* BR/UR 轉數字（若原始是字串，先去掉逗號、空格） */
    length _BR_num _UR_num 8.;
    if vtype(BR) = 'C' then _BR_num = input(compress(BR, ', '), best32.);
    else _BR_num = BR;

    if vtype(UR) = 'C' then _UR_num = input(compress(UR, ', '), best32.);
    else _UR_num = UR;

    /* ln_BR, ln_UR：僅在正值時取 log */
    if _BR_num > 0 then ln_BR = log(_BR_num);
    if _UR_num > 0 then ln_UR = log(_UR_num);
run;


/* ======================================================
   3) 依 year、companyID 排序
====================================================== */
proc sort data=_merged2 out=_merged2_srt;
    by year companyID;
run;


/* ======================================================
   4) 僅保留並排序指定欄位
====================================================== */
data paper_patent_final;
    retain companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI hhi efficiency_real
           size Lev carrent_ratio MSO BS age
           ln_BR ln_UR;
    set _merged2_srt(keep=
           companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI hhi efficiency_real
           size Lev carrent_ratio MSO BS age
           ln_BR ln_UR);
run;

/* ======================================================
   5) 匯出 Excel
====================================================== */
proc export data=paper_patent_final
    outfile="/home/u64061874/paper_patent_final.xlsx"
    dbms=xlsx replace;
run;

/* 只留指定欄位（不含 ln_UR），並刪除 ln_BR / MSO / BS 缺失，並新增 LI2, hhi2 */
data paper_patent_final2;
    retain companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI LI2 hhi hhi2 efficiency_real
           size Lev carrent_ratio MSO BS age ln_BR;
    set paper_patent_final(
        keep=companyID companyName year
             invention_acc_app new_acc_app design_acc_app total_acc_app
             invention_sin_app new_sin_app design_sin_app total_sin_app
             P MC LI hhi efficiency_real
             size Lev carrent_ratio MSO BS age ln_BR
    );

    /* 新增平方項 */
    if not missing(LI)  then LI2  = LI**2;
    if not missing(hhi) then hhi2 = hhi**2;

    /* 刪掉缺失值觀測 */
    if missing(ln_BR) then delete;
    if missing(MSO)   then delete;
    if missing(BS)    then delete;
run;

/* 匯出 Excel */
proc export data=paper_patent_final2
    outfile="/home/u64061874/paper_patent_final2.xlsx"
    dbms=xlsx replace;
run;

proc sql;
    select 
        sum(missing(companyID))      as miss_companyID,
        sum(missing(companyName))    as miss_companyName,
        sum(missing(year))           as miss_year,
        sum(missing(invention_acc_app)) as miss_invention_acc_app,
        sum(missing(new_acc_app))    as miss_new_acc_app,
        sum(missing(design_acc_app)) as miss_design_acc_app,
        sum(missing(total_acc_app))  as miss_total_acc_app,
        sum(missing(invention_sin_app)) as miss_invention_sin_app,
        sum(missing(new_sin_app))    as miss_new_sin_app,
        sum(missing(design_sin_app)) as miss_design_sin_app,
        sum(missing(total_sin_app))  as miss_total_sin_app,
        sum(missing(P))              as miss_P,
        sum(missing(MC))             as miss_MC,
        sum(missing(LI))             as miss_LI,
        sum(missing(hhi))            as miss_hhi,
        sum(missing(efficiency_real)) as miss_efficiency_real,
        sum(missing(size))           as miss_size,
        sum(missing(Lev))            as miss_Lev,
        sum(missing(carrent_ratio))  as miss_carrent_ratio,
        sum(missing(MSO))            as miss_MSO,
        sum(missing(BS))             as miss_BS,
        sum(missing(age))            as miss_age,
        sum(missing(ln_BR))          as miss_ln_BR
    from paper_patent_final2;
quit;