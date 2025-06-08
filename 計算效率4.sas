/* 匯入資料 */
proc import out=eff_ver2
     datafile= '/home/u64061874/eff_ver2.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/* 匯入資料 */
proc import out=CPI_adj2
     datafile= '/home/u64061874/CPI_adj2.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/*合併表格*/
proc sql;
    create table eff_data1 as
    select 
        e.*, 
        s.adjust
    from 
        eff_ver2 as e
    left join 
        CPI_adj2 as s
    on 
      e.year = s.year
    ;
quit;

/*資料排序*/
proc sort data=eff_data1;
     by year sample;
run;

*匯出資料;
proc export data=eff_data1
     outfile='/home/u64061874/eff_data1.xlsx'
     dbms=xlsx replace;
run;

/*：計算加權後的各項變數 */
data eff_calc1;
    set eff_data1;

    total_cost_adj   = total_cost   * adjust;
    total_asset_adj  = total_asset  * adjust;
    capital_cost_adj = capital_cost * adjust;
    capital_adj      = capital      * adjust;
    labour_cost_adj  = labour_cost  * adjust;
run;

/* 計算單位成本 */
data eff_calc2;
    set eff_calc1;

    capital_unit_cost = capital_cost_adj / capital_adj;
    labour_unit_cost  = labour_cost_adj  / labour;
run;

/* 取對數 */
data eff_calc3;
    set eff_calc2;

    lnTC  = log(total_cost_adj);
    lnY   = log(total_asset_adj);
    lnw1  = log(capital_unit_cost);
    lnw2  = log(labour_unit_cost);
run;

/*標準化*/
data eff_calc4;
    set eff_calc3;

    lnTC_w1 = lnTC-lnw1;
    lnw2_w1 = lnw2-lnw1;
run;

/* 計算交互與平方項 */
data eff_final;
    set eff_calc4;

    lny11 = lnY**2;
    lnyw2_w1 = lnY * lnw2_w1;
run;

/* 只保留指定欄位並重新命名（如需重新命名變數本身可再加步驟） */
data eff_output(keep=sample year lnTC_w1 lnY lnw2_w1 lny11 lnyw2_w1);
	retain sample year lnTC_w1 lnY lnw2_w1 lny11 lnyw2_w1;
    set eff_final;
run;

/* 資料處理：刪除期貨商資料 */
DATA eff_try3;
    set eff_output;
    if sample in (19, 20, 21, 22) then delete;
run;

/* 計算不重複樣本數量 */
proc sql;
    select distinct sample
    from eff_try3;
quit;

/* 匯出資料 */
proc export data=eff_try3
     outfile='/home/u64061874/eff_try3.xlsx'
     dbms=xlsx replace;
run;

/* 先計算 TC_w1 與 TC，並只保留 sample/year 以及新變數 */
data extra_vars;
    set eff_calc2;
    TC_w1 = total_cost_adj / capital_unit_cost;
    Y = total_asset_adj;
    keep sample year TC_w1 Y;
run;

/* 合併 eff_try3 與 extra_vars */
proc sql;
    create table LI_data1 as
    select a.*, b.TC_w1, b.Y
    from eff_try3 as a
    left join extra_vars as b
    on a.sample = b.sample and a.year = b.year;
quit;

/*計算MC*/
data LI_result_MC;
    set LI_data1;

    /* 第一部分 */
    partial = -11.322187 
            + 1.3781303 * lnY
            + 1.9827821 * lnw2_w1
            - 0.0036934314 * lny11
            - 0.10381022 * lnyw2_w1;

    /* 第二部分 */
    division = TC_w1 / Y;

    /* 最後結果 */
    MC = partial * division;
run;

/*計算P*/

/*匯入資料*/
proc import out=total_revenue
     datafile= '/home/u64061874/total_revenue.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/*匯入資料*/
proc import out=year
     datafile= '/home/u64061874/year.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/*合併表格*/
proc sql;
    create table total_revenue1 as
    select 
        e.*, 
        s.year
    from 
        total_revenue as e
    left join 
        year as s
    on 
      e.year_real = s.year_real
    ;
quit;

/*合併表格*/
proc sql;
    create table P_data1 as
    select 
        e.*, 
        s.total_asset
    from 
        total_revenue1 as e
    left join 
        eff_ver2 as s
    on 
      e.year = s.year and e.sample = s.sample
    ;
quit;

/*計算P*/
data LI_result_P;
    retain id name sample year year_real total_revenue total_asset P;
    set P_data1;
    P = total_revenue / total_asset;
run;

/*計算競爭程度-合併 P 和 MC*/
proc sql;
    create table LI_final as
    select 
        a.*, 
        b.MC
    from 
        LI_result_P as a
    left join 
        LI_result_MC as b
    on 
        a.sample = b.sample and a.year = b.year
    ;
quit;

/*計算競爭程度-計算 LI*/
data LI_final;
    set LI_final;
    LI = (P - MC) / P;
run;

/*結果*/
data LI_final_keep_nmiss;
    retain id name sample year P MC LI;
    set LI_final;
    keep id name sample year P MC LI;
    if nmiss(P, MC, LI) = 0;
run;

/*資料排序*/
proc sort data=LI_final_keep_nmiss;
     by year sample;
run;

/* 資料處理：刪除期貨商資料 */
DATA LI_final_result;
    set LI_final_keep_nmiss;
    if sample in (19, 20, 21, 22) then delete;
run;

*匯出資料;
proc export data=LI_final_result
     outfile='/home/u64061874/LI_final_result.xlsx'
     dbms=xlsx replace;
run;

/* 匯入資料 */
proc import out=year
     datafile= '/home/u64061874/year.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/* 匯入資料 */
proc import out=efficiency_result1_ver1
     datafile= '/home/u64061874/efficiency_result1_ver1.xlsx'
     dbms=xlsx replace;
     getnames=yes;
run;

/*合併表格*/
proc sql;
    create table efficiency_result2_ver1 as
    select 
        e.*, 
        s.year_real
    from 
        efficiency_result1_ver1 as e
    left join 
        year as s
    on 
      e.year = s.year
    ;
quit;

/*資料排序*/
proc sort data=efficiency_result2_ver1;
     by year sample;
run;

*匯出資料;
proc export data=efficiency_result2_ver1
     outfile='/home/u64061874/efficiency_result2_ver1.xlsx'
     dbms=xlsx replace;
run;