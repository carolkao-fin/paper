/* 1. 匯入資料 */
proc import out=final_efficiency_data_final2
     datafile="/home/u64061874/final_efficiency_data_final2.xlsx"
     dbms=xlsx replace;
     getnames=yes;
run;

/* 2. Lerner-3SLS */
proc syslin data=final_efficiency_data_final2 3sls outest=est3sls;
    endogenous LI lnPSY;
    instruments DC MSO BS UR FHC size;
    model CE = LI lnPSY size BS FHC;
    model LI = CE lnPSY UR DC;
    model lnPSY = CE LI MSO UR;
run;

/* 3. Lerner-2SLS */
proc syslin data=final_efficiency_data_final2 2sls;
    endogenous LI lnPSY;
    instruments DC MSO BS UR FHC size;
    model CE = LI lnPSY size BS FHC;
run;

proc syslin data=final_efficiency_data_final2 2sls;
    endogenous CE lnPSY;
    instruments DC MSO BS UR FHC size;
    model LI = CE lnPSY UR DC;
run;

proc syslin data=final_efficiency_data_final2 2sls;
    endogenous CE LI;
    instruments DC MSO BS UR FHC size;
    model lnPSY = CE LI MSO UR;
run;

/* 4. Lerner系統的 joint Sargan 統計與p值 */
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

/* 5. HHI-3SLS */
proc syslin data=final_efficiency_data_final2 3sls outest=est3sls;
    endogenous LI lnPSY;
    instruments DC MSO BS UR FHC size;
    model CE = HHI_sd lnPSY size BS FHC;
    model HHI_sd = CE lnPSY UR DC;
    model lnPSY = CE HHI_sd MSO UR;
run;

/* 6. HHI-2SLS */
proc syslin data=final_efficiency_data_final2 2sls;
    endogenous HHI_sd lnPSY;
    instruments DC MSO BS UR FHC size;
    model CE = HHI_sd lnPSY size BS FHC;
run;

proc syslin data=final_efficiency_data_final2 2sls;
    endogenous CE lnPSY;
    instruments DC MSO BS UR FHC size;
    model HHI_sd = CE lnPSY UR DC;
run;

proc syslin data=final_efficiency_data_final2 2sls;
    endogenous CE HHI_sd;
    instruments DC MSO BS UR FHC size;
    model lnPSY = CE HHI_sd MSO UR;
run;

/* 7. HHI系統的 joint Sargan 統計與p值 */
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

/* 匯出 */
proc export data=joint_sargan_all2
     outfile="/home/u64061874/joint_sargan_all2.xlsx"
     dbms=xlsx replace;
run;