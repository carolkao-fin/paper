/* ========= 0) 匯入 ========= */
proc import out=paper_patent_final2
     datafile="/home/u64061874/paper_patent_final2.xlsx"
     dbms=xlsx replace;
     getnames=yes;
run;

/* 先刪掉舊的（避免沿用錯誤結構） */
proc datasets lib=work nolist;
  delete joint_sargan_all;
quit;

/* 正確初始化：把四個欄位都「宣告」出來（0 筆，但欄位齊全） */
data joint_sargan_all;
  length system $32;
  system = '';           /* 避免 uninitialized NOTE */
  S_joint = .;           /* numeric */
  df_joint = .;          /* numeric */
  p_value = .;           /* numeric */
  format p_value best12.8;
  stop;                  /* 建 0 筆觀測值的「表頭」 */
run;

/* ========= 2) 每個情境：跑 3SLS → 立刻計算並 append joint Sargan ========= */

/* 無平方 × 全部專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI total_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI total_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real total_acc_app Lev current_ratio FHC_dummy MSO age;
    model total_acc_app   = efficiency_real LI ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_nosquare_tot";
    s1=.005652; df1=8;      /* efficiency_real */
    s2=1.4076;  df2=8;      /* LI */
    s3=1.11315; df3=6;      /* total_acc_app */
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 無平方 × 發明專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI invention_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI invention_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real invention_acc_app Lev current_ratio FHC_dummy MSO age;
    model invention_acc_app = efficiency_real LI ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_nosquare_inv";
    s1=.174468; df1=8;
    s2=3.82817; df2=8;
    s3=.800195; df3=6;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 無平方 × 新型專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI new_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI new_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real new_acc_app Lev current_ratio FHC_dummy MSO age;
    model new_acc_app     = efficiency_real LI ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_nosquare_new";
    s1=.029337; df1=8;
    s2=3.17794; df2=8;
    s3=1.49602; df3=6;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 無平方 × 設計專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI design_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI design_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real design_acc_app Lev current_ratio FHC_dummy MSO age;
    model design_acc_app  = efficiency_real LI ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_nosquare_des";
    s1=.492493; df1=8;
    s2=1.29254; df2=8;
    s3=2.75985; df3=6;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 含平方 × 全部專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI LI2 total_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI total_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real total_acc_app Lev current_ratio FHC_dummy MSO age;
    model total_acc_app   = efficiency_real LI LI2 ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_square_tot";
    s1=.005652; df1=8;
    s2=1.4076;  df2=8;
    s3=.181044; df3=7;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 含平方 × 發明專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI LI2 invention_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI invention_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real invention_acc_app Lev current_ratio FHC_dummy MSO age;
    model invention_acc_app = efficiency_real LI LI2 ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_square_inv";
    s1=.174468; df1=8;
    s2=3.82817; df2=8;
    s3=.191012; df3=7;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 含平方 × 新型專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI LI2 new_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI new_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real new_acc_app Lev current_ratio FHC_dummy MSO age;
    model new_acc_app     = efficiency_real LI LI2 ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_square_new";
    s1=.029337; df1=8;
    s2=3.17794; df2=8;
    s3=1.2281;  df3=7;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* 含平方 × 設計專利 */
proc syslin data=paper_patent_final2 3sls outest=est3sls;
    endogenous efficiency_real LI LI2 design_acc_app;
    instruments size BS ln_BR Lev current_ratio MSO age FHC_dummy;
    model efficiency_real = LI design_acc_app BS ln_BR age FHC_dummy Lev;
    model LI              = efficiency_real design_acc_app Lev current_ratio FHC_dummy MSO age;
    model design_acc_app  = efficiency_real LI LI2 ln_BR size Lev;
run;

data _tmp;
    length system $32;
    system   = "Lerner_square_des";
    s1=.492493; df1=8;
    s2=1.29254; df2=8;
    s3=.689041; df3=7;
    S_joint = sum(s1,s2,s3);
    df_joint = sum(df1,df2,df3);
    p_value = 1 - probchi(S_joint, df_joint);
    keep system S_joint df_joint p_value;
run;
proc append base=joint_sargan_all data=_tmp force; run;

/* ========= 3) 檢視與匯出 ========= */
proc print data=joint_sargan_all label noobs;
    label system  = '系統'
          S_joint = 'Joint Sargan Statistic'
          df_joint= 'Joint df'
          p_value = 'p-value';
    format p_value best12.8;
run;

proc export data=joint_sargan_all
     outfile="/home/u64061874/joint_sargan_all.xlsx"
     dbms=xlsx replace;
run;