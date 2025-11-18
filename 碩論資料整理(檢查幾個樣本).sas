/* ========= A) 修復 ODS 錯誤 / 關閉預設 HTML ========= */
ods _all_ close;         /* 關掉所有 ODS 目的地，避免 _HTMLOUT 佔用 */
ods listing;             /* 用 LISTING，避免寫到無權限的 HTML 路徑 */
filename _htmlout clear; /* 把那個麻煩的 fileref 清掉（若存在） */

/* ========= B) 低噪設定 ========= */
options nonotes nostimer nosource msglevel=i;

/* ========= C) 匯入 Excel ========= */
proc import out=paper_effi_new3
    datafile="/home/u64061874/paper_effi_new3.xlsx"
    dbms=xlsx replace;
    getnames=yes;
run;

/* ========= D) 輕度清理鍵值（移除 NBSP/全形空白、首尾空白、統一大寫） ========= */
/* 說明：
   - translate(..., ' ', 'A0'x||'3000'x)  把 NBSP 與全形空白轉成一般空白
   - strip 去前後空白；upcase 統一大小寫
*/
data _prep;
    set paper_effi_new3;
    length companyID_key $64 companyName_key $128;

    companyID_key   = upcase(strip(translate(companyID  , ' ', 'A0'x||'3000'x)));
    companyName_key = upcase(strip(translate(companyName, ' ', 'A0'x||'3000'x)));
run;

/* ========= E) 你要的「不重複樣本」：每組 companyID+companyName 僅留一筆 ========= */
proc sort data=_prep out=unique_samples nodupkey;
    by companyID_key companyName_key;
run;

/* （可選）嚴格「只出現一次」的組合（dup_count = 1） */
proc sql;
    create table unique_only as
    select companyID_key, companyName_key, count(*) as dup_count
    from _prep
    group by companyID_key, companyName_key
    having calculated dup_count = 1;
quit;

/* （可選）把所有重複的原始列另存（方便稽核） */
proc sql;
    create table dup_rows as
    select a.*
    from _prep as a
    inner join (
        select companyID_key, companyName_key
        from _prep
        group by companyID_key, companyName_key
        having count(*) > 1
    ) as d
    on a.companyID_key=d.companyID_key and a.companyName_key=d.companyName_key;
quit;

/* ========= F) 匯出（可選） ========= */
proc export data=unique_samples
    outfile="/home/u64061874/paper_effi_new3_unique.xlsx"
    dbms=xlsx replace;
run;

proc export data=dup_rows
    outfile="/home/u64061874/paper_effi_new3_duplicates.xlsx"
    dbms=xlsx replace;
run;