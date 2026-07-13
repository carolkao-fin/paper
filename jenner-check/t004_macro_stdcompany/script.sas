/* ==========================================================
   小工具巨集：標準化 companyID + 年份轉換
   — %std_company_id and %make_years from 碩論效率資料整理_20250911.sas.
   The macros are defined verbatim; a small inline caller dataset with
   both numeric and character companyID values and a raw year column
   exercises the vtype()/putn() branch and the year→yearnew mapping.
   ========================================================== */

%macro std_company_id(invar, outvar);
  length &outvar $200;
  if vtype(&invar)='N' then &outvar = putn(&invar, 'z6.');
  else &outvar = upcase(strip(&invar));
%mend;

%macro make_years(invar, year_out, yearnew_out);
  &year_out = input(vvaluex("&invar"), best32.);
  &year_out = floor(&year_out);
  if missing(&year_out) then &yearnew_out=.;
  else &yearnew_out = &year_out - 2002;  /* 2003→1, 2004→2, ... */
%mend;

/* 混合輸入：數值代號（需補零）與字串代號（需去空白/大寫） */
data raw_in;
  length companyID_c $10 rawyear $8;
  input companyID_n companyID_c $ rawyear $;
datalines;
116 . 2003
616 . 2010
. 6005 2015
. 000779 2019
. 30559abc 2021
;
run;

/* 對數值代號套用 std_company_id；對字串代號亦套用；並做年份轉換 */
data std_out;
  set raw_in;
  %std_company_id(companyID_n, id_from_num)
  %std_company_id(companyID_c, id_from_char)
  %make_years(rawyear, year, yearnew)
run;

proc print data=std_out noobs;
  var companyID_n companyID_c id_from_num id_from_char rawyear year yearnew;
  title "標準化 companyID 與年份轉換結果";
run;
