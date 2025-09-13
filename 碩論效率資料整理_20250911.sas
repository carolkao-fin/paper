/* ===== 0) 基本設定 ===== */
options notes stimer source msglevel=i;

/* ===== 1) 匯入 ===== */
proc import out=paper_effi_new
    datafile="/home/u64061874/paper_effi_new.xlsx"
    dbms=xlsx replace;
    getnames=yes;
run;

proc import out=CPI_adj
    datafile="/home/u64061874/CPI_adj.xlsx"
    dbms=xlsx replace;
    getnames=yes;
run;

/* ===== 2) CPI_adj 若有 index 就改成 CPI_index ===== */
proc sql noprint;
  select count(*) into :has_cpi_index
  from dictionary.columns
  where libname='WORK' and memname='CPI_ADJ' and upcase(name)='CPI_INDEX';

  select count(*) into :has_index
  from dictionary.columns
  where libname='WORK' and memname='CPI_ADJ' and upcase(name)='INDEX';
quit;

%if &has_cpi_index=0 and &has_index>0 %then %do;
  proc datasets lib=work nolist;
    modify CPI_adj;
    rename index = CPI_index;
  quit;
%end;

/* ===== 3) CPI：year / CPI_index 轉數值（用 ?? 安靜處理錯誤） ===== */
data CPI_adj_clean;
  set CPI_adj(rename=(year=year_c CPI_index=CPI_index_c));
  length year CPI_index 8;
  year      = input(year_c,      ?? best32.);
  CPI_index = input(CPI_index_c, ?? best32.);
  keep year CPI_index;
run;

/* ===== 4) 主表：year 與成本/資產/資本/勞動欄位 → 數值（用 ??） ===== */
data paper_effi_new_num;
  set paper_effi_new(rename=(
    year         = year_c
    cost_payment = cost_payment_c
    cost_health  = cost_health_c
    cost_retire  = cost_retire_c
    cost_food    = cost_food_c
    cost_welfare = cost_welfare_c
    cost_other   = cost_other_c
    total_asset  = total_asset_c
    cost_capital = cost_capital_c
    capital      = capital_c
    labour       = labour_c
  ));

  length year 8
         cost_payment cost_health cost_retire cost_food cost_welfare
         cost_other total_asset cost_capital capital labour 8;

  year         = input(year_c,         ?? best32.);
  cost_payment = input(cost_payment_c, ?? best32.);
  cost_health  = input(cost_health_c,  ?? best32.);
  cost_retire  = input(cost_retire_c,  ?? best32.);
  cost_food    = input(cost_food_c,    ?? best32.);
  cost_welfare = input(cost_welfare_c, ?? best32.);
  cost_other   = input(cost_other_c,   ?? best32.);
  total_asset  = input(total_asset_c,  ?? best32.);
  cost_capital = input(cost_capital_c, ?? best32.);
  capital      = input(capital_c,      ?? best32.);
  labour       = input(labour_c,       ?? best32.);

  drop year_c
       cost_payment_c cost_health_c cost_retire_c cost_food_c cost_welfare_c
       cost_other_c total_asset_c cost_capital_c capital_c labour_c;
run;

/* ===== 5) 排序準備合併 ===== */
proc sort data=paper_effi_new_num; by year; run;
proc sort data=CPI_adj_clean;      by year; run;

/* ===== 6) 合併 + CPI 平減（/CPI_index * 100）+ 計算 ===== */
data paper_effi_new_all;
  merge paper_effi_new_num (in=a)
        CPI_adj_clean      (in=b);
  by year;
  if a;

  array v_orig {*} 
      cost_payment cost_health cost_retire cost_food cost_welfare
      cost_other total_asset cost_capital capital;
  array v_adj  {*} 
      cost_payment_adj cost_health_adj cost_retire_adj cost_food_adj cost_welfare_adj
      cost_other_adj   total_asset_adj  cost_capital_adj capital_adj;

  do j = 1 to dim(v_orig);
    if not missing(CPI_index) and CPI_index>0 then
      v_adj[j] = divide(v_orig[j], CPI_index) * 100;
    else v_adj[j] = .;
  end;

  /* 原始合計（未調整） */
  labour_cost = sum(of cost_payment cost_health cost_retire cost_food cost_welfare cost_other);
  total_cost  = sum(labour_cost, cost_capital);

  /* 調整後合計 */
  labour_cost_adj = sum(of cost_payment_adj cost_health_adj cost_retire_adj
                        cost_food_adj     cost_welfare_adj cost_other_adj);
  total_cost_adj  = sum(labour_cost_adj, cost_capital_adj);

  /* 命名對齊 */
  capital_cost     = cost_capital;
  capital_cost_adj = cost_capital_adj;

  /* 價格指標（調整後） */
  price_capital_adj = divide(capital_cost_adj, capital_adj);
  price_labour_adj  = divide(labour_cost_adj, labour);

  /* ln（>0 才取） */
  if total_cost_adj    > 0 then ln_total_cost_adj    = log(total_cost_adj);    else ln_total_cost_adj    = .;
  if total_asset_adj   > 0 then ln_total_asset_adj   = log(total_asset_adj);   else ln_total_asset_adj   = .;
  if price_capital_adj > 0 then ln_price_capital_adj = log(price_capital_adj); else ln_price_capital_adj = .;
  if price_labour_adj  > 0 then ln_price_labour_adj  = log(price_labour_adj);  else ln_price_labour_adj  = .;
run;

/* ===== 7) 建立要保留的 companyID 名單 ===== */
data keep_ids;
  length companyID $10;
  infile datalines truncover;
  input companyID :$10.;
datalines;
000020
000022
000025
0000A1
000102
000104
000109
000116
000138
000218
000511
000532
000538
000546
000560
000566
000569
000586
000587
000596
000611
000615
000616
000620
000621
000638
000645
000646
000662
000695
000700
000702
000707
000708
000712
000736
000767
000775
000778
000779
000790
000815
000838
000849
000852
000856
000866
000871
000877
000884
000885
000888
000889
000930
000960
000980
0009A0
2854
2855
2856
30119
30514
30518
30588
30660
30666
30696
30752
30753
30769
30808
30843
30879
30880
5864
6003
6004
6005
6008
6010
6012
6015
6016
6020
6021
6022
6026
6027
60732
000098
30106
30110
30219
30535
30537
30598
30634
30697
30846
30855
30867
30872
30883
30886
6002
6017
30559
;
run;

/* ===== 8) 過濾年份 & 公司，並固定輸出欄位順序 ===== */
proc sql;
  create table paper_effi_new2 as
  select 
    strip(a.companyID)   as companyID length=200,
    a.companyName,
    a.year,
    a.total_cost,
    a.total_cost_adj,
    a.ln_total_cost_adj,
    a.total_asset,
    a.total_asset_adj,
    a.ln_total_asset_adj,
    a.capital_cost,
    a.capital_cost_adj,
    a.capital,
    a.capital_adj,
    a.price_capital_adj,
    a.ln_price_capital_adj,
    a.labour_cost,
    a.labour_cost_adj,
    a.labour,
    a.price_labour_adj,
    a.ln_price_labour_adj,
    a.CPI_index
  from paper_effi_new_all as a
  inner join keep_ids      as k
    on strip(a.companyID) = strip(k.companyID)
  where a.year >= 2003
  order by a.year, a.companyID
  ;
quit;

/* ===== 9) 匯出 Excel（資料集 & 檔名：paper_effi_new2） ===== */
proc export data=paper_effi_new2
    outfile="/home/u64061874/paper_effi_new2.xlsx"
    dbms=xlsx replace;
run;

/* ===== 10) 刪除缺失值 → paper_effi_new3 ===== */
/* 說明：
   - cmiss()：同時檢查字元與數值是否缺失（例如 companyID, companyName）
   - nmiss()：只檢查數值是否缺失（其餘數值欄位全列）
*/
proc sql;
  create table paper_effi_new3 as
  select *
  from paper_effi_new2
  where 
    /* 文字欄不可缺：*/
    cmiss(companyID, companyName) = 0

    /* 數值欄不可缺：*/
    and nmiss(
      year,
      total_cost, total_cost_adj, ln_total_cost_adj,
      total_asset, total_asset_adj, ln_total_asset_adj,
      capital_cost, capital_cost_adj,
      capital, capital_adj,
      price_capital_adj, ln_price_capital_adj,
      labour_cost, labour_cost_adj,
      labour, price_labour_adj, ln_price_labour_adj,
      CPI_index
    ) = 0
  order by year, companyID
  ;
quit;

/* ===== 11) 匯出 Excel（paper_effi_new3） ===== */
proc export data=paper_effi_new3
    outfile="/home/u64061874/paper_effi_new3.xlsx"
    dbms=xlsx replace;
run;

/*改成Frontier4.1匯入的格式*/
/* ===== 1) 匯入 ===== */
proc import out=comparison_table
    datafile="/home/u64061874/comparison_table.xlsx"
    dbms=xlsx replace;
    getnames=yes;
run;

/* === A) 改名 + trend + year 轉成連續值 === */
data _renamed_trend;
  set paper_effi_new3;

  /* 改名（保留新名即可） */
  lnTC = ln_total_cost_adj;
  lnY  = ln_total_asset_adj;
  lnw2 = ln_price_capital_adj;
  lnw1 = ln_price_labour_adj;

  /* 2003->1, 2004->2, ... ；並把 year 欄位本身也改成此連續值 */
  trend = year - 2002;
  year  = trend;

  drop ln_total_cost_adj ln_total_asset_adj ln_price_capital_adj ln_price_labour_adj;
run;

/* === B) 與 comparison_table 合併（以 companyID 對應 sample） === */
proc sql;
  create table _merged as
  select 
    b.sample,
    a.*
  from _renamed_trend as a
  left join comparison_table as b
    on strip(a.companyID) = strip(b.companyID)
  order by a.year, a.companyID
  ;
quit;

/* === C) 派生變數計算 === */
data paper_effi_new4;
  set _merged;

  /* 指定公式 */
  lnTC_w1    = lnTC - lnw1;
  lnw2_w1    = lnw2 - lnw1;
  /* lnY 保留原樣 */
  lny11      = 0.5 * (lnY**2);
  lnw22_w1   = 0.5 * (lnw2_w1**2);
  lnyw2_w1   = lnY * lnw2_w1;
  trend2_reg = 0.5 * (trend**2);
  lny_trend  = lnY * trend;
  lnw2_trend = lnw2_w1 * trend;

  /* 依你指定的欄位順序輸出 */
  retain sample year lnTC_w1 lnY lny11 lnw2_w1 lnw22_w1 lnyw2_w1 trend trend2_reg lny_trend lnw2_trend;
  keep   sample year lnTC_w1 lnY lny11 lnw2_w1 lnw22_w1 lnyw2_w1 trend trend2_reg lny_trend lnw2_trend;
run;

/* === D) 匯出 === */
proc export data=paper_effi_new4
    outfile="/home/u64061874/paper_effi_new4.xlsx"
    dbms=xlsx replace;
run;

/*Lerner index計算（含 CPI 調整：total_revenue_adj = total_revenue / index * 100）*/
/* ===========================================
   0) 低噪版 LOG（驗完可打開 notes）
=========================================== */
options nonotes nostimer nosource msglevel=i;

/* ===========================================
   1) 匯入
=========================================== */
proc import out=Lerner
    datafile="/home/u64061874/Lerner.xlsx" dbms=xlsx replace; getnames=yes; run;
proc import out=paper_effi_new2
    datafile="/home/u64061874/paper_effi_new2.xlsx" dbms=xlsx replace; getnames=yes; run;
proc import out=paper_effi_new4
    datafile="/home/u64061874/paper_effi_new4.xlsx" dbms=xlsx replace; getnames=yes; run;
proc import out=comparison_table
    datafile="/home/u64061874/comparison_table.xlsx" dbms=xlsx replace; getnames=yes; run;

/* ① 匯入 CPI 表：year（西元年）、index（CPI 指數）— 本版忽略 adjust 欄位 */
proc import out=CPI_adj
    datafile="/home/u64061874/CPI_adj.xlsx"
    dbms=xlsx replace;
    getnames=yes;
run;

/* ===========================================
   2) 小工具（標準化）
=========================================== */
%macro std_company_id(invar, outvar);
  length &outvar $200;
  if vtype(&invar)='N' then &outvar = putn(&invar, 'z6.');
  else &outvar = upcase(strip(&invar));
%mend;

%macro std_sample(invar, outvar);
  length &outvar $200;
  &outvar = upcase(strip(vvaluex("&invar")));
%mend;

%macro make_years(invar, year_out, yearnew_out);
  &year_out = input(vvaluex("&invar"), best32.);
  &year_out = floor(&year_out);
  if missing(&year_out) then &yearnew_out=.;
  else &yearnew_out = &year_out - 2002;  /* 2003→1, 2004→2, ... */
%mend;

/* ===========================================
   3) comparison_table → 雙向對照
=========================================== */
data comp_clean;
  length companyID $200 sample $200;
  set comparison_table(rename=(companyID=companyID_raw sample=sample_raw));
  %std_company_id(companyID_raw, companyID);
  %std_sample(sample_raw, sample);
  keep companyID sample;
run;

proc sort data=comp_clean nodupkey out=comp_map_id2s; by companyID sample; run;
proc sort data=comp_clean nodupkey out=comp_map_s2id; by sample companyID; run;
proc sort data=comp_map_id2s nodupkey; by companyID; run; /* companyID → 唯一 sample */
proc sort data=comp_map_s2id nodupkey; by sample;    run; /* sample    → 唯一 companyID */

/* ===========================================
   4) 標準化三份主表
=========================================== */
data Lerner_std;
  length companyID $200;
  set Lerner(rename=(companyID=companyID_raw year=year_raw));
  %std_company_id(companyID_raw, companyID);
  %make_years(year_raw, year_num, year_new);   /* 先產索引年 */
  year = coalesce(year_num, year_new + 2002);  /* 同步保留西元年（備用）*/
  drop companyID_raw year_raw;
run;

data pe2_std;
  length companyID $200;
  set paper_effi_new2(rename=(companyID=companyID_raw year=year_raw));
  %std_company_id(companyID_raw, companyID);
  %make_years(year_raw, year, year_new);       /* 這裡的 year 是西元年；year_new 作為索引年 */
  drop companyID_raw year_raw;
run;

proc sql;
  create table pe2_aug as
  select a.companyID,
         a.year,                /* 西元年（僅供檢視）*/
         a.year_new,            /* ← 合併計算用 */
         a.total_cost_adj, a.total_asset_adj,
         b.sample
  from pe2_std a
  left join comp_map_id2s b
    on a.companyID = b.companyID;
quit;

/* pe4：用 sample→companyID 補 id；保留原始 year（將用來對 year_new） */
data pe4_std;
  length sample $200;
  set paper_effi_new4(rename=(year=year_raw sample=sample_raw));
  %std_sample(sample_raw, sample);
  year = input(vvaluex("year_raw"), best32.);
  year = floor(year); /* 這個 year 會與 pe2.year_new 對齊 */
  drop year_raw sample_raw;
run;

proc sql;
  create table pe4_aug as
  select c.companyID, a.sample,
         a.year,  /* 這裡的 year 會等於 pe2 的 year_new */
         a.lnTC_w1, a.lnY, a.lny11, a.lnw2_w1, a.lnw22_w1, a.lnyw2_w1,
         a.trend, a.trend2_reg, a.lny_trend, a.lnw2_trend
  from pe4_std a
  left join comp_map_s2id c
    on a.sample = c.sample;
quit;

/* ===========================================
   5) Lerner 收入名目合計（未調整）→ total_revenue
      並保留 year_new & year（西元年）
=========================================== */
%macro build_total_rev(ds_in=, ds_out=);
  %let varlist=
    BR UR STOR PDEAL PUND NPOS RDERI
    Handling_fee_revenues Income_securities_lendings
    Future_commission_revenue Securities_commission_revenue
    Revenue_consignment Management_fee_revenues
    Revenue_from_advisory Interest_revenue_operate
    Dividend_revenue_opetate Interest_revenue_operate_CFO
    Dividend_revenue_opetate_CFO Interest_revenue_outside
  ;

  data &ds_out;
    length _raw _half _keep $32767;
    set &ds_in;

    %local i v list_n; %let list_n=;
    %let i=1;
    %do %while(%scan(&varlist,&i) ne );
      %let v=%scan(&varlist,&i);

      if vtypex("&v")='N' then do;
        &v._n = &v;
      end;
      else do;
        _raw  = vvaluex("&v");
        _half = translate(_raw, '0123456789.-', '０１２３４５６７８９．－');
        _keep = compress(_half, '0123456789.-', 'k');
        if _keep in ('', '-', '.') then &v._n = .;
        else &v._n = inputn(_keep, 'best32.');
      end;

      %let list_n=&list_n &v._n;
      %let i=%eval(&i+1);
    %end;

    /* 名目收入合計（未經 CPI 調整） */
    if n(of &list_n)=0 then total_revenue = .;
    else total_revenue = sum(of &list_n);

    if _error_ then _error_ = 0;

    /* 同步保留年欄位（下步用西元 year 與 CPI 年對齊） */
    year = coalesce(year_num, year_new + 2002);
    keep companyID year_num year_new year total_revenue;
  run;
%mend;

%build_total_rev(ds_in=Lerner_std, ds_out=Lerner_revenue);

/* 5b) 以西元年 year 連接 CPI，計算實質收入 total_revenue_adj = total_revenue / index * 100 */
proc sql;
  create table Lerner_revenue_cpi as
  select a.companyID,
         a.year_num,
         a.year_new,
         a.year,                    /* 西元年 */
         a.total_revenue,           /* 名目收入（保留） */
         b.index    as CPI_index,
         case 
           when b.index > 0 then (a.total_revenue / b.index) * 100
           else .
         end        as total_revenue_adj      /* ← 實質收入（給下游用） */
  from Lerner_revenue a
  left join CPI_adj   b
    on a.year = b.year;
quit;

/* ===========================================
   6) companyID + year_new 合併算 P（用實質收入）
   並保留名目版 P_nominal 供稽核
=========================================== */
proc sql;
  create table P_company_yearnew as
  select a.companyID,
         a.year_new,
         (a.total_revenue_adj / b.total_asset_adj) as P,          /* 實質版 */
         (a.total_revenue     / b.total_asset_adj) as P_nominal   /* 名目版（對照） */
  from Lerner_revenue_cpi a
  left join pe2_aug       b
    on a.companyID = b.companyID
   and a.year_new  = b.year_new;
quit;

proc sql;
  create table P_by_sample_yearnew as
  select c.sample, p.year_new, p.P, p.P_nominal, p.companyID
  from P_company_yearnew p
  left join comp_map_id2s c
    on p.companyID = c.companyID;
quit;

/* ===========================================
   7) 以 companyID 對齊；年份規則：pe4.year = pe2.year_new（原本模式）
=========================================== */
proc sql;
  create table merged_for_MC as
  select p2.companyID, p2.sample, 
         p2.year_new,                  /* 索引年 */
         p2.total_cost_adj, p2.total_asset_adj,
         p4.lnY, p4.lnw2_w1, p4.trend
  from pe2_aug as p2
  left join pe4_aug as p4
    on  p2.companyID = p4.companyID
    and p4.year      = p2.year_new;    /* 關鍵：原本的對齊規則 */
quit;

data MC_by_company_yearnew;
  set merged_for_MC;
  if missing(total_asset_adj) or total_asset_adj=0 then division=.;
  else division = total_cost_adj / total_asset_adj;

  if nmiss(lnY, lnw2_w1, trend)=0 then
      partial = 0.57904344
              + 0.35839460E-01*lnY
              + 0.80478373E-01*lnw2_w1
              - 0.32038563E-02*trend;
  else partial=.;

  if nmiss(partial,division)=0 then MC=partial*division;
  else MC=.;

  keep companyID sample year_new MC;
run;

/* ===========================================
   8) 合併 P 與 MC（companyID + year_new）→ LI
   並在此層「轉成西元年」year = year_new + 2002
=========================================== */
proc sql;
  create table final_LI_export as
  select coalesce(p.sample, m.sample) as sample length=200,
         coalesce(p.companyID, m.companyID) as companyID,
         (coalesce(p.year_new, m.year_new) + 2002) as year,  /* 西元年 */
         coalesce(p.year_new, m.year_new) as year_new,       /* 索引年（備查） */
         p.P,                    /* 實質 P */
         p.P_nominal,            /* 名目 P（稽核用） */
         m.MC,
         case when p.P ne . and m.MC ne . and p.P ne 0
              then (p.P - m.MC)/p.P
              else .
         end as LI
  from P_by_sample_yearnew p
  full join MC_by_company_yearnew m
    on p.companyID = m.companyID and p.year_new = m.year_new
  order by sample, year;
quit;

/* ===========================================
   9) 診斷／稽核
=========================================== */

/* B0：pe4_aug 由 sample 併回 companyID 的覆蓋率 */
proc sql;
    create table diag_b0 as
    select count(b.companyID) as mapped,
           count(a.sample)    as total,
           calculated mapped / calculated total * 100 as map_rate
    from pe4_aug a
    left join comp_clean b
      on a.sample = b.sample;
quit;

proc print data=diag_b0 noobs; run;

/* B1：companyID + (year_new ↔ year) 命中率（原本模式） */
proc sql;
    create table diag_b1 as
    select sum(case when b.companyID is not null then 1 else 0 end) as matched,
           sum(case when b.companyID is null then 1 else 0 end)     as unmatched,
           calculated matched / (calculated matched+calculated unmatched) * 100 as hit_rate
    from pe2_aug a
    left join pe4_aug b
      on a.companyID=b.companyID and a.year_new=b.year;
quit;

proc print data=diag_b1 noobs; run;

/* B2：對不到的清單（完整存檔） */
proc sql;
    create table diag_b2 as
    select a.companyID, a.sample, a.year_new
    from pe2_aug a
    left join pe4_aug b
      on a.companyID=b.companyID and a.year_new=b.year
    where b.companyID is null
    order by a.companyID, a.year_new;
quit;

proc print data=diag_b2 (obs=50) noobs; run;

/* D：最終欄位缺失率（含 year / year_new） */
proc means data=final_LI_export n nmiss;
    var year year_new P P_nominal MC LI;
run;

/* ===========================================
   10) 公司白名單（join 篩選）
=========================================== */
data id_whitelist;
    length companyID $200;
    infile datalines truncover;
    input companyID :$200.;
datalines;
000020
000022
000025
0000A1
000102
000104
000109
000116
000138
000218
000511
000532
000538
000546
000560
000566
000569
000586
000587
000596
000611
000615
000616
000620
000621
000638
000645
000646
000662
000695
000700
000702
000707
000708
000712
000736
000767
000775
000778
000779
000790
000815
000838
000849
000852
000856
000866
000871
000877
000884
000885
000888
000889
000930
000960
000980
0009A0
2854
2855
2856
30119
30514
30518
30588
30660
30666
30696
30752
30753
30769
30808
30843
30879
30880
5864
6003
6004
6005
6008
6010
6012
6015
6016
6020
6021
6022
6026
6027
60732
000098
30106
30110
30219
30535
30537
30598
30634
30697
30846
30855
30867
30872
30883
30886
6002
6017
30559
;
run;

/* 篩選（year >= 2003）並排序 year, companyID */
proc sql;
  create table filtered_data as
  select f.*
  from final_LI_export f
  inner join id_whitelist w
    on f.companyID = w.companyID
  where f.year >= 2003
  order by f.year, f.companyID;
quit;

proc print data=filtered_data (obs=50); run;

/* ===========================================
   11) 匯出（依照 year, sample 排序）
=========================================== */
proc sort data=final_LI_export out=final_LI_export_sorted;
  by year sample;
run;

proc sort data=filtered_data out=filtered_data_sorted;
  by year sample;
run;

proc export data=final_LI_export_sorted
    outfile="/home/u64061874/paper_LI_result.xlsx"
    dbms=xlsx replace;
run;

proc export data=filtered_data_sorted
    outfile="/home/u64061874/paper_LI_result_sorted.xlsx"
    dbms=xlsx replace;
run;

/* （可選）一致性檢查：year 與 year_new 對應關係（應為 year = year_new + 2002） */
proc freq data=final_LI_export;
  tables year*year_new / list missing;
run;

/* 1) 刪除缺失值（保留名目與實質 P） */
data final_LI_no_missing;
    set final_LI_export;
    if cmiss(of year year_new P MC LI) = 0; 
run;

/* 2) 合併回公司名稱 */
proc sql;
    create table final_LI_with_name as
    select a.sample,
           a.companyID,
           b.companyName,
           a.year,
           a.year_new,
           a.P,
           a.P_nominal,
           a.MC,
           a.LI
    from final_LI_no_missing a
    left join comparison_table b
      on a.companyID = b.companyID;
quit;

/* 3) 新增數值型 sample，用於正確排序 */
data final_LI_with_name2;
    set final_LI_with_name;
    sample_num = input(sample, best32.);   /* 若 sample 含字母則會變成缺失 */
run;

/* 4) 按照 year、sample_num 排序，並輸出固定欄位順序 */
proc sort data=final_LI_with_name2 out=paper_LI_result_final;
    by year sample_num;
run;

data paper_LI_result_final;
    set paper_LI_result_final;
    keep sample companyID companyName year year_new P P_nominal MC LI;
run;

/* 5) 匯出（含公司名與 P_nominal） */
proc export data=paper_LI_result_final
    outfile="/home/u64061874/paper_LI_result_final.xlsx"
    dbms=xlsx replace;
run;

/*LI負數檢查*/
/*計算整體LI為負的比率*/
proc sql;
  select year,
         count(*) as total_n,
         sum(case when LI_fix<0 then 1 else 0 end) as n_neg,
         sum(case when LI_fix<0 then 1 else 0 end)*100.0 / count(*) as pct_neg
  from LI_fix
  where LI_fix is not null
  group by year;
quit;

/*計算樣本LI為負的比率*/
/* ========== 1) 展開成長格式：一列一個版本，方便統計 ========== */
data LI_long;
  set LI_grid;
  array LIv[4] LI_total_raw LI_oper_raw LI_total_t0 LI_oper_t0;
  array NM[4] $12 _temporary_ ('total_raw','oper_raw','total_t0','oper_t0');

  do k=1 to 4;
    LI = LIv[k];
    MCname = NM[k];
    if not missing(LI) then output;
  end;

  keep year companyID sample MCname LI;
run;

/* ========== 2) 逐年逐版本統計 ========== */
proc sql;
  create table LI_stats as
  select MCname, year,
         count(LI) as N_nonnull,
         sum(case when LI<0 then 1 else 0 end) as N_neg,
         mean(LI) as avg_LI,
         calculated N_neg*100.0 / calculated N_nonnull as pct_neg
  from LI_long
  group by MCname, year
  order by MCname, year;
quit;

proc print data=LI_stats; run;

/*將LI為負的值強制轉為0*/
/* 產生截斷版（保留原始 LI_raw，LI<0 → 0） */
data paper_LI_result_final2;
    set paper_LI_result_final;

    /* 保留原始值 */
    LI_raw = LI;

    /* 截斷：小於 0 → 0 */
    if not missing(LI) and LI < 0 then LI = 0;
run;

/* 稽核：同時檢查 LI_raw 與 LI */
proc means data=paper_LI_result_final2 n mean min p5 p50 p95 max;
    var LI_raw LI;
run;

/* 匯出 */
proc export data=paper_LI_result_final2
    outfile="/home/u64061874/paper_LI_result_final2.xlsx"
    dbms=xlsx replace;
run;