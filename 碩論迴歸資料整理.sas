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

/* ======================================================
   合併控制變數 + 依「起始年」併入 FHC_dummy（逐年）
   - 支援重跑（作法B：自動刪除舊 FHC_dummy）
====================================================== */
options nonotes nostimer nosource msglevel=i;

/* ======================================================
   0) 匯入資料
====================================================== */
proc import out=paper_patent_merge2
    datafile="/home/u64061874/paper_patent_merge2.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_control1
    datafile="/home/u64061874/paper_control1.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_control2
    datafile="/home/u64061874/paper_control2.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_control3
    datafile="/home/u64061874/paper_control3.xlsx"
    dbms=xlsx replace; getnames=yes; run;

proc import out=paper_control4
    datafile="/home/u64061874/paper_control4.xlsx"
    dbms=xlsx replace; getnames=yes; run;

/* 讀入 FHC 起始年檔（欄位：companyID companyName FHC_dummy year=起始年） */
proc import out=paper_FHC
    datafile="/home/u64061874/paper_FHC.xlsx"
    dbms=xlsx replace; getnames=yes; run;

/* ======================================================
   1) 合併 control1~4
====================================================== */
proc sql;
    create table _merged as
    select a.*,
           b.total_asset,
           b.equity,
           b.current_ratio,
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
   4) 僅保留並排序指定欄位 → paper_patent_final
====================================================== */
data paper_patent_final;
    retain companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI hhi efficiency_real
           size Lev current_ratio MSO BS age
           ln_BR ln_UR;
    set _merged2_srt(keep=
           companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI hhi efficiency_real
           size Lev current_ratio MSO BS age
           ln_BR ln_UR);
run;

/* 先輸出一版（可檢視） */
proc export data=paper_patent_final
    outfile="/home/u64061874/paper_patent_final.xlsx"
    dbms=xlsx replace; run;

/* ======================================================
   5) 只留指定欄位（不含 ln_UR），刪除 ln_BR / MSO / BS 缺失，新增 LI2, hhi2 → paper_patent_final2
====================================================== */
data paper_patent_final2;
    retain companyID companyName year
           invention_acc_app new_acc_app design_acc_app total_acc_app
           invention_sin_app new_sin_app design_sin_app total_sin_app
           P MC LI LI2 hhi hhi2 efficiency_real
           size Lev current_ratio MSO BS age ln_BR;
    set paper_patent_final(
        keep=companyID companyName year
             invention_acc_app new_acc_app design_acc_app total_acc_app
             invention_sin_app new_sin_app design_sin_app total_sin_app
             P MC LI hhi efficiency_real
             size Lev current_ratio MSO BS age ln_BR
    );

    /* 新增平方項 */
    if not missing(LI)  then LI2  = LI**2;
    if not missing(hhi) then hhi2 = hhi**2;

    /* 刪掉缺失值觀測 */
    if missing(ln_BR) then delete;
    if missing(MSO)   then delete;
    if missing(BS)    then delete;
run;

/* 先輸出一版（可檢視） */
proc export data=paper_patent_final2
    outfile="/home/u64061874/paper_patent_final2.xlsx"
    dbms=xlsx replace; run;

/* ======================================================
   6) 將 FHC 起始年整理為公司層級，並回填逐年 dummy
   定義：
   - 在 paper_FHC.xlsx 中：FHC_dummy=1 的 year 為「起始年」；
   - 每家公司取最早起始年；
   - 樣本年 >= 起始年 → FHC_dummy=1；否則 0；
   - 從未成為金控 → 全期 0。
====================================================== */

/* 6.1 標準化 FHC：year→start_year（只對 FHC=1 解析），FHC_dummy→數值旗標 */
data _fhc_norm;
    length companyID $32 companyName $200;
    set paper_FHC;

    companyID   = strip(companyID);
    companyName = strip(companyName);

    /* FHC_dummy → 數值 (允許 '是/否','Y/N','1/0') */
    length FHC_flag 8;
    if vtype(FHC_dummy)='C' then do;
        length _t $16;
        _t = upcase(strip(FHC_dummy));
        if _t in ('1','Y','YES','是') then FHC_flag=1;
        else if _t in ('0','N','NO','否','') then FHC_flag=0;
        else FHC_flag = input(_t, best32.);
    end;
    else FHC_flag = FHC_dummy;
    if missing(FHC_flag) then FHC_flag=0;

    /* year → start_year（僅在 FHC_flag=1 時解析；字串允許「2002年」） */
    length start_year 8;
    if FHC_flag=1 then do;
        if vtype(year)='C' then start_year = input(compress(year,,'kd'), best32.);
        else start_year = year;
    end;
    else start_year = .;

    keep companyID companyName FHC_flag start_year;
run;

/* 6.2 每家公司取最早起始年；兼存是否曾為金控（ever_fhc） */
proc sql;
    create table _fhc as
    select companyID,
           min(start_year) as start_year,
           max(FHC_flag)   as ever_fhc
    from _fhc_norm
    group by companyID
    ;
quit;

/* ======================================================
   作法 B：小巨集，若資料集中存在某變數，就 drop 掉（避免 Warning）
====================================================== */
%macro dropvar_if_exists(ds, var);
    %local has;
    proc sql noprint;
        select count(*) into :has
        from dictionary.columns
        where libname='WORK'
          and memname=upcase("%scan(&ds,1,. )")
          and upcase(name)=upcase("&var");
    quit;
    %if &has %then %do;
        proc datasets nolist;
            modify &ds;
            drop &var;
        quit;
    %end;
%mend;

/* ======================================================
   7) 併回 paper_patent_final（依起始年逐年標示）
====================================================== */

/* 先確保舊的 FHC_dummy 移除（可重跑不噴警告） */
%dropvar_if_exists(paper_patent_final, FHC_dummy)

data _ppf_y;
    set paper_patent_final;
    length Y_num 8;
    if vtype(year)='C' then Y_num = input(compress(year,,'kd'), best32.);
    else Y_num = year;
run;

proc sql;
    create table paper_patent_final as
    select a.*,
           case
               when b.start_year is not null and a.Y_num >= b.start_year then 1
               else 0
           end as FHC_dummy
    from _ppf_y as a
    left join _fhc  as b
      on a.companyID=b.companyID
    ;
quit;

proc sort data=paper_patent_final; by year companyID; run;

/* 產出四欄檢視表（companyID companyName FHC_dummy year） */
data paper_FHC_yearly_from_final;
    keep companyID companyName FHC_dummy year;
    set paper_patent_final(keep=companyID companyName FHC_dummy year);
run;

/* 匯出（最新版，含 FHC_dummy） */
proc export data=paper_patent_final
    outfile="/home/u64061874/paper_patent_final.xlsx"
    dbms=xlsx replace; run;

proc export data=paper_FHC_yearly_from_final
    outfile="/home/u64061874/paper_FHC_yearly_from_final.xlsx"
    dbms=xlsx replace; run;

/* ======================================================
   8) 併回 paper_patent_final2（同規則）
====================================================== */

/* 先確保舊的 FHC_dummy 移除（可重跑不噴警告） */
%dropvar_if_exists(paper_patent_final2, FHC_dummy)

data _ppf2_y;
    set paper_patent_final2;
    length Y_num 8;
    if vtype(year)='C' then Y_num = input(compress(year,,'kd'), best32.);
    else Y_num = year;
run;

proc sql;
    create table paper_patent_final2 as
    select a.*,
           case
               when b.start_year is not null and a.Y_num >= b.start_year then 1
               else 0
           end as FHC_dummy
    from _ppf2_y as a
    left join _fhc  as b
      on a.companyID=b.companyID
    ;
quit;

proc sort data=paper_patent_final2; by year companyID; run;

/* 匯出（最新版，含 FHC_dummy） */
proc export data=paper_patent_final2
    outfile="/home/u64061874/paper_patent_final2.xlsx"
    dbms=xlsx replace; run;
    
proc import out=paper_patent_final2
    datafile="/home/u64061874/paper_patent_final2.xlsx"
    dbms=xlsx replace; getnames=yes; run;
    
/* === 建立不屬金控(nFHC) 與 屬金控(yFHC) 兩份資料 === */
data paper_patent_final2_nFHC(drop=_fhc)
     paper_patent_final2_yFHC(drop=_fhc);
    set paper_patent_final2;

    /* 穩健處理：無論 FHC_dummy 是數值或字串都轉成 0/1 */
    length _fhc 8;
    if vtype(FHC_dummy)='C' then _fhc = input(compress(FHC_dummy,,'kd'), best32.);
    else _fhc = FHC_dummy;
    if missing(_fhc) then _fhc=0;  /* 沒填視為 0（可依需要改） */

    if _fhc=1 then output paper_patent_final2_yFHC;
    else if _fhc=0 then output paper_patent_final2_nFHC;
run;

/* 排序（維持你一貫的 year/companyID 排序） */
proc sort data=paper_patent_final2_nFHC; by year companyID; run;
proc sort data=paper_patent_final2_yFHC; by year companyID; run;

/* 快速檢核：總筆數與分組筆數 */
proc sql;
  select count(*) as n_all from paper_patent_final2;
  select 'nFHC(0)' as grp, count(*) as n from paper_patent_final2_nFHC
  union all
  select 'yFHC(1)' as grp, count(*) from paper_patent_final2_yFHC;
quit;

/*（可選）按年分佈看看是否合理 */
title "FHC_dummy=0（nFHC）按年分佈";
proc freq data=paper_patent_final2_nFHC; tables year / nocum; run;
title "FHC_dummy=1（yFHC）按年分佈";
proc freq data=paper_patent_final2_yFHC; tables year / nocum; run;
title;

/* 匯出成 Excel（方便你後續檢視或丟進 Stata） */
proc export data=paper_patent_final2_nFHC
    outfile="/home/u64061874/paper_patent_final2_nFHC.xlsx"
    dbms=xlsx replace; sheet="nFHC"; run;

proc export data=paper_patent_final2_yFHC
    outfile="/home/u64061874/paper_patent_final2_yFHC.xlsx"
    dbms=xlsx replace; sheet="yFHC"; run;

/* （選用）快速檢查：FHC_dummy 分布與各年計數 */
proc freq data=paper_patent_final;
    tables FHC_dummy / missing;
    title "paper_patent_final 的 FHC_dummy 分布";
run;

proc means data=paper_patent_final n nmiss;
    var FHC_dummy;
    class year;
    title "各年 FHC_dummy 計數（paper_patent_final）";
run;

/* 收尾把 notes 打開 */
options notes;