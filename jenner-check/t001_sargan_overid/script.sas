/* ==========================================================
   Joint Sargan over-identification test — from 過度識別(穩健性測試).sas
   The Sargan-statistic aggregation and chi-square p-value are computed
   entirely from the per-equation statistics already reported by
   PROC SYSLIN, so this block runs stand-alone (no external data file).
   ========================================================== */

/* 4. Lerner 系統的 joint Sargan 統計與 p 值 */
data sargan_Lerner2;
    system2 = "Lerner";
    Sargan_CE2 = 1.24651;
    df_CE2 = 6;
    Sargan_LI2 = .40773;
    df_LI2 = 5;
    Sargan_lnPSY2 = 2.25362;
    df_lnPSY2 = 5;
    S_joint2 = Sargan_CE2 + Sargan_LI2 + Sargan_lnPSY2;
    df_joint2 = df_CE2 + df_LI2 + df_lnPSY2;
    p_value2 = 1 - probchi(S_joint2, df_joint2);
    output;
run;

/* 7. HHI 系統的 joint Sargan 統計與 p 值 */
data sargan_hhi2;
    system2 = "HHI";
    Sargan_CE2 = 1.04874;
    df_CE2 = 6;
    Sargan_HHI2 = 5.45527 ;
    df_HHI2 = 5;
    Sargan_lnPSY2 = 5.25016 ;
    df_lnPSY2 = 5;
    S_joint2 = Sargan_CE2 + Sargan_HHI2 + Sargan_lnPSY2;
    df_joint2 = df_CE2 + df_HHI2 + df_lnPSY2;
    p_value2 = 1 - probchi(S_joint2, df_joint2);
    output;
run;

/* 8. 合併 joint Sargan 結果成表格 */
data joint_sargan_all2;
    set sargan_Lerner2 sargan_hhi2;
    keep system2 S_joint2 df_joint2 p_value2;
run;

proc print data=joint_sargan_all2 label noobs;
    label
        system2 = '系統'
        S_joint2 = 'Joint Sargan Statistic'
        df_joint2 = 'Joint df'
        p_value2 = 'p-value';
run;
