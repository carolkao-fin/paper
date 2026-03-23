ivregress 2sls efficiency_real (LI  total_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real total_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls total_acc_app (efficiency_real LI = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI  invention_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real invention_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls invention_acc_app (efficiency_real LI = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI  new_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real new_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls new_acc_app (efficiency_real LI = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI  design_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real design_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls design_acc_app (efficiency_real LI = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI total_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real total_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls total_acc_app (efficiency_real LI LI2 = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI invention_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real invention_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls invention_acc_app (efficiency_real LI LI2 = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI new_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real new_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls new_acc_app (efficiency_real LI LI2 = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


ivregress 2sls efficiency_real (LI design_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) BS ln_BR age FHC_dummy Lev 
estat overid

ivregress 2sls LI (efficiency_real design_acc_app = size BS ln_BR Lev current_ratio MSO age FHC_dummy) Lev current_ratio FHC_dummy MSO age
estat overid

ivregress 2sls design_acc_app (efficiency_real LI LI2 = size BS ln_BR Lev current_ratio MSO age FHC_dummy) ln_BR size Lev 
estat overid


