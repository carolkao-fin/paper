reg3 ///
  (efficiency_real = LI total_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real total_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (total_acc_app   = efficiency_real LI ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_tot_nosquare.doc, replace


reg3 ///
  (efficiency_real = LI invention_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real invention_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (invention_acc_app   = efficiency_real LI ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_inv_nosquare.doc, replace


reg3 ///
  (efficiency_real = LI new_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real new_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (new_acc_app   = efficiency_real LI ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_new_nosquare.doc, replace


reg3 ///
  (efficiency_real = LI design_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real design_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (design_acc_app   = efficiency_real LI ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_des_nosquare.doc, replace


reg3 ///
  (efficiency_real = LI total_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real total_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (total_acc_app   = efficiency_real LI LI2 ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app LI2) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_tot_square.doc, replace

reg3 ///
  (efficiency_real = LI invention_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real invention_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (invention_acc_app   = efficiency_real LI LI2 ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app LI2) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_inv_square.doc, replace


reg3 ///
  (efficiency_real = LI new_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real new_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (new_acc_app   = efficiency_real LI LI2 ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app LI2) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_new_square.doc, replace


reg3 ///
  (efficiency_real = LI design_acc_app BS ln_BR age FHC_dummy Lev) ///
  (LI              = efficiency_real design_acc_app Lev current_ratio FHC_dummy MSO age) ///
  (design_acc_app   = efficiency_real LI LI2 ln_BR size Lev) ///
  , endog(efficiency_real LI total_acc_app LI2) 3sls

ssc install outreg2
cd "C:\Users\msi01\Downloads"
outreg2 using result_LI_des_square.doc, replace
