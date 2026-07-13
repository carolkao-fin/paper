/* ==========================================================
   建立要保留的 companyID 名單 — from 碩論效率資料整理_20250911.sas (step 7)
   The keep-list is defined inline via DATALINES, then summarised with
   PROC SQL / PROC FREQ, so this block runs stand-alone.
   ========================================================== */

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

/* 名單筆數與是否有重複 */
proc sql;
  create table keep_ids_summary as
  select count(*) as n_ids,
         count(distinct companyID) as n_distinct
  from keep_ids;
quit;

proc print data=keep_ids_summary noobs;
  title "保留公司代號名單摘要";
run;

/* 依代號前綴（首碼類型）快速盤點 */
data keep_ids_flag;
  set keep_ids;
  length id_type $12;
  if substr(companyID,1,3) = '000' then id_type = 'zero-prefix';
  else id_type = 'other';
run;

proc freq data=keep_ids_flag;
  tables id_type / nocum;
run;
