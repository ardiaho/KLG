# ZFARR_DOWNLOAD_CREDIT_LIMIT: KNKK remediation plan (Q-006)

Status: analysis only, nothing written or changed on KSD. Plan awaits approval.
Read from: client 100 (program, DDIC), client 300 (sample data). Date: 2026-11-23.

Program: `ZFARR_DOWNLOAD_CREDIT_LIMIT`, RICEF R340, package **ZFI**, report "Download Credit Limit Customer".
Existing tag: MOD001 (TR KSDK903462, "use ECC structure" option). Next free tag: **MOD002**.
No includes. Where-used list is empty (nobody calls it; it runs as a report or background job).

## 1. Where KNKK is used

The program only reads. It never writes KNKK. No joins on KNKK.

| # | Place | What |
|---|---|---|
| 1 | `DATA i_knkk TYPE STANDARD TABLE OF knkk`, `wa_knkk TYPE knkk` | Typing of the working table |
| 2 | Constant `c_knkk = 'KNKK'` | Table name passed to the output step. It drives the file name, the DD03L column list and, with option ECC, the RFC call for the ECC structure |
| 3 | Selection screen: `s_knkli FOR wa_knkk-knkli`, `s_kkber FOR wa_knkk-kkber` (obligatory), `s_aedat FOR wa_knkk-aedat`, `s_erdat FOR wa_knkk-erdat` | Four selection criteria typed on KNKK fields |
| 4 | `f_retrieve_data`: `SELECT * FROM knkk INTO TABLE i_knkk WHERE knkli IN s_knkli AND kkber IN s_kkber AND aedat IN s_aedat AND erdat IN s_erdat` | The only database read. All 36 fields |
| 5 | `f_retrieve_data`: `SELECT * FROM s066 / s067 ... FOR ALL ENTRIES IN i_knkk WHERE kkber = i_knkk-kkber AND knkli = i_knkk-knkli` | S066 and S067 are driven by the KNKK result |
| 6 | `START-OF-SELECTION`: `IF i_knkk[] IS INITIAL. "No data found" EXIT.` | If the KNKK read returns nothing, S066 and S067 are never downloaded either |
| 7 | `PERFORM f_process_data USING i_knkk c_knkk cb_knkk`, `cb_knkk` checkbox, `f_append_table`, `dd03l` read with `tabname IN r_tabname` | Output of the table as a delimited file. Columns come from DD03L of KNKK (and from ECC with `cb_ecc`) |

Important: the file layout is the KNKK layout (36 columns). A receiving system probably depends on it, so the plan keeps that layout.

## 2. Field mapping KNKK to UKMBP_CMS / UKMBP_CMS_SGM

Keys differ:
- KNKK key: MANDT, **KUNNR** (customer), **KKBER** (credit control area).
- UKMBP_CMS key: CLIENT, **PARTNER** (business partner). Master data per BP, not per area.
- UKMBP_CMS_SGM key: CLIENT, PARTNER, **CREDIT_SGMNT** (credit segment). Limit and block per BP and segment.
- Customer to BP: `CVI_CUST_LINK` (CUSTOMER to PARTNER_GUID), then `BUT000` (PARTNER_GUID to PARTNER). Do not assume PARTNER = KUNNR. In 300 both exist: customers `A001`, `D003` have BP ids equal to the customer number, and BP ids like `1000000185` exist too.
- Credit control area to segment: assumed 1:1 by name (T014 has `KLGC`, `KLGD`; UKMCRED_SGM0C has `KLGC`, `KLGD` in 300). **To confirm with the functional team**, there is no technical link table I verified.

Confidence: H = same meaning, M = likely, L = guess, N = no equivalent in these two tables.

| KNKK field | Meaning | Target | Conf. | Note |
|---|---|---|---|---|
| KUNNR | Customer | CVI_CUST_LINK-CUSTOMER (via PARTNER) | H | Join key, not stored in CMS |
| KKBER | Credit control area | UKMBP_CMS_SGM-CREDIT_SGMNT | M | Assumes area = segment |
| KLIMK | Credit limit | UKMBP_CMS_SGM-CREDIT_LIMIT | H | Currency from UKMCRED_SGM0C-CURRENCY (IDR for KLGC, KLGD) |
| KNKLI | Credit account | UKMBP_CMS-ALTERNATE_BP, else own customer | M | Alternate BP is a BP number, map back to customer via CVI_CUST_LINK. Blank alternate = own account |
| CTLPC | Risk category | UKMBP_CMS-RISK_CLASS | H | 300 sample: `001` on both sides |
| CRBLB | Credit block | UKMBP_CMS_SGM-XBLOCKED | H | |
| SBGRP | Credit rep. group | UKMBP_CMS_SGM-COORDINATOR (credit analyst) | L | Different concept (group vs user) |
| GRUPP | Customer credit group | UKMBP_CMS-CREDIT_GROUP | M | CHAR 3 to NUMC 4, conversion needed |
| KDGRP | Customer group | UKMBP_CMS_SGM-CUST_GROUP | M | |
| NXTRV | Next review | UKMBP_CMS_SGM-FOLLOW_UP_DT | M | Resubmission date |
| DTREV | Last internal review | UKMBP_CMS-RATING_CHG_DATE | L | |
| AEDAT | Changed on | UKMBP_CMS_SGM-LIMIT_CHG_DATE | M | Limit change date only, not any change |
| ERDAT / ERNAM | Created on / by | BUT000-CRDAT / CRUSR | L | Date the BP was created, not the credit data. No creation date in CMS tables |
| AENAM | Changed by | none | N | |
| SAUFT, SKFOR, SSOBL, ABSBT | Sales value, receivables, special liabilities, secured receivables | none | N | Not master data. In S/4 these come from the credit exposure (UKM_ITEM / FSCM API), not from the two tables |
| UEDAT | Limit exceeded date | none | N | |
| XCHNG, AETXT, KRAUS | Flags, text change date, info number | none | N | |
| PAYDB, DBRAT, REVDB, DBPAY, DBRTG, DBEKR, DBWAE, DBMON | D&B data | none | N | FSCM has no D&B fields in CMS. Check if KLG filled them at all |
| CASHD, CASHA, CASHC | Last payment | none | N | From FI, not CMS |
| SBDAT | Reference date | none | N | |

Result: only about 10 of 36 fields have a real home. The rest can be blank, derived elsewhere, or dropped. This is the main decision for you (see section 5).

S066 / S067: tables still exist in S/4. In 300, S066 returned 0 rows. They are keyed by KKBER and KNKLI (customer number), and the program reads them only via i_knkk. They are not on your KNKK list but break with it (point 6 above).

## 3. Proposed code change

Object touched: **only** `ZFARR_DOWNLOAD_CREDIT_LIMIT` (PROG/P, package **ZFI**). `ZCL_UTIL` and the DDIC stay unchanged. The table KNKK still exists in S/4 (typing `TYPE knkk` stays valid), so the output pipeline and the ECC option keep working.

Change MOD002 in `f_retrieve_data` and the selection-screen (everything tagged per `klg-code-standards.md`):
1. Header: add modification log entry 02 (MOD002, new transport number, change description).
2. Replace the KNKK SELECT with one Open SQL read, old SELECT commented out between `"MOD002.Begin.Change` / `"MOD002.End.Change`:
   `UKMBP_CMS_SGM` INNER JOIN `UKMBP_CMS` ON partner, INNER JOIN `BUT000` ON partner, INNER JOIN `CVI_CUST_LINK` ON partner_guid. Select only the mapped columns (no `SELECT *`).
   WHERE: `cvi_cust_link~customer IN s_knkli` (use customer number as before), `credit_sgmnt IN s_kkber` (select option stays, now means segment), `limit_chg_date IN s_aedat`, `but000~crdat IN s_erdat` (open question).
3. Fill `i_knkk` (still TYPE KNKK): KUNNR = customer, KKBER = segment, mapped fields as in section 2, the rest initial. Output keeps the same column layout.
4. Keep S066 / S067 FOR ALL ENTRIES against `i_knkk` unchanged (they use KKBER / KNKLI, which still get filled). Guard against an empty `i_knkk` is already there.
5. Selection screen texts: update text elements only if you want the label to say "Credit segment" (text change, same MOD tag).
6. Quality: extended program check, ATC with S/4 Readiness variant (the program still reads S066/S067), unit test not feasible for a report; test via client 300 (section 4).

Transport: a **new workbench transport**, created after your approval, description per standard, e.g. `R1:R340:Credit limit download read from UKMBP_CMS_SGM_1.0`, written in 100 via `zabap-mcp`. Not KSDK909575 (unrelated upload work). Not KSDK903462 (released).

## 4. Test in client 300

Before (run on the current program, no change yet) and after (new version), same selection, option ECC off and on, output to the application server or local file. Compare:

| Check | How |
|---|---|
| Row count | KNKK-version rows (KKBER KLGC and KLGD) vs new rows. Unequal counts are expected for customers without a BP link or without a CMS segment row |
| Key coverage | List of KUNNR + KKBER in old file vs new file, list the differences both ways |
| Mapped fields | KLIMK, CTLPC, CRBLB, GRUPP, KDGRP, NXTRV per KUNNR+KKBER: old file vs new file |
| Conversion | GRUPP value, currency of KLIMK, BP-to-customer mapping for BPs with a different number than the customer (e.g. `1000000185` style ids) |
| Layout | Header line and column count identical (36 columns), with and without `cb_ecc` |
| S066 / S067 | Same rows downloaded before and after |
| Edge cases | Customer without BP link, customer in segment KLGD only, `s_kkber` empty segment, large selection (runtime) |

Sample numbers I read in 300: KNKK showed one customer (`A001`, area KLGC, limit 0.01). UKMBP_CMS_SGM has many BP rows in segment KLGC (for example BP 1000000002, limit 30,000,000). I could not count rows: data preview is capped at 100 rows and filtered preview is blocked (see `../sap-abap-knowledge/zabap-mcp-known-issues.md`). For counts, run the program itself or SE16N in 300.

An important consequence to validate: in 300 KNKK seems nearly empty (customers were migrated to BP/CMS). The "before" file may be almost empty, so the comparison baseline should be the data in UKMBP_CMS_SGM, or a copy of an ECC extract.

## 5. Risks and open questions for you

1. **Which fields are needed?** The file has 36 KNKK columns, only about 10 can be filled from the two tables. Does the receiving system need exposure (SAUFT, SKFOR, SSOBL, ABSBT), D&B fields and last payment? If yes, they need other sources (UKM_ITEM / FSCM API), which is a bigger change.
2. **Keep the KNKK file layout** (recommended) or move to a new CMS-based layout and change the receiver?
3. **KKBER = credit segment**: confirm 1:1 (KLGC, KLGD) with the functional analyst.
4. **KNKLI**: is the credit account always the customer itself, or do groups exist (ALTERNATE_BP)? Also the S066/S067 FOR ALL ENTRIES uses it.
5. **ERDAT selection**: no credit creation date exists. Use BP creation date, or drop the selection field.
6. **S066 / S067**: still used? They were empty in the 300 sample. Keep, drop the checkboxes, or exclude from this change.
7. **ECC option (MOD001)**: it moves KNKK data into the ECC structure by field name. Unfilled fields stay blank in the file. Confirm that is acceptable.
8. **Customers with several segments**: one KNKK row per KUNNR+KKBER stays, so no duplication, but BPs without a customer link are dropped.
9. Risk: AEDAT meaning changes (limit change only). Risk: GRUPP type conversion. Risk: a joined read on large data, run in background.
10. Unverified: where-used covered only objects the ADT scope searches. Jobs (SM36) calling this report by name were not checked.

Next step on approval: `architect` plan is this document. Then `dev` builds MOD002 in 100 on a new transport, I run check and ATC, and `qa`/me compare in 300. TDD question (none / now / after build): not asked yet, decide at approval.

Lessons: none.
