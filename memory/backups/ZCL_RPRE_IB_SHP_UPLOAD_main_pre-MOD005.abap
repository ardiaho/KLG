*======================================================================*
* M O D I F I C A T I O N  L O G
*----------------------------------------------------------------------*
* 01. Changed on   : 23.11.2026
*     Changed by   : (PWC.ARDIA)
*     Change No.   : KSDK909575
*     Modif. Tag   : MOD001
*     Description  : Upload no longer converts the file's partner
*                    function with CONVERSION_EXIT_PARVW_INPUT. The file
*                    value is the internal key, as in the ZVL31N
*                    dropdown. SP was turned into AG and rejected.
*
* 02. Changed on   : 23.11.2026
*     Changed by   : (PWC.ARDIA)
*     Change No.   : KSDK909575
*     Modif. Tag   : MOD002
*     Description  : Country of Origin: the uploaded value is kept when
*                    the info record (EINA-URZLA) has none. Before, the
*                    file value was cleared and every item failed with
*                    Please fill Country of Origin.
*
* 03. Changed on   : 23.11.2026
*     Changed by   : (PWC.ARDIA)
*     Change No.   : KSDK909575
*     Modif. Tag   : MOD003
*     Description  : Shipping type column is no longer mandatory in the
*                    Header sheet. It is still checked against T173 when
*                    filled. ZVL31N data has the shipping type blank.
*
* 04. Changed on   : 23.11.2026
*     Changed by   : (PWC.ARDIA)
*     Change No.   : KSDK909575
*     Modif. Tag   : MOD004
*     Description  : Inbound delivery posting no longer fails on ERNUM
*                    when the delivery was created and the log has only
*                    information messages (VL 074 delivery date in the
*                    past). Success is LT_VBLS filled and no E or A log.
*======================================================================*
CLASS zcl_rpre_ib_shp_upload DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_tech_no TYPE zrprt_ibshp_log-tech_no.
    TYPES ty_t_tech_no TYPE STANDARD TABLE OF ty_tech_no WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_msg,
        msgty TYPE symsgty,
        text  TYPE string,
      END OF ty_s_msg,
      ty_t_msg TYPE STANDARD TABLE OF ty_s_msg WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_hdr,
        tech_no       TYPE ty_tech_no,
        legacy_vbeln  TYPE zrprt_ibshp_log-legacy_vbeln,
        legacy_tknum  TYPE zrprt_ibshp_log-legacy_tknum,
        bolnr         TYPE zrprt_pib_uplhdr-bill_of_ladding,
        vsart         TYPE zrprt_pib_uplhdr-ship_type,
        lfdat         TYPE zrprt_pib_uplhdr-eta_wh,
        aju_no        TYPE zrprt_pib_uplhdr-aju_no,
        aju_date      TYPE zrprt_pib_uplhdr-aju_date,
        pricing_date  TYPE zrprt_pib_uplhdr-pricing_date,
        etd_load_port TYPE zrprt_pib_uplhdr-etd_load_port,
        eta_dst_port  TYPE zrprt_pib_uplhdr-eta_dst_port,
        ship_doc_date TYPE zrprt_pib_uplhdr-ship_doc_date,
        pib_int_ind   TYPE zrprt_pib_uplhdr-pib_int_ind,
        handling      TYPE zrprt_pib_uplhdr-handling,
        curr_handling TYPE zrprt_pib_uplhdr-curr_handling,
        admin_fee     TYPE zrprt_pib_uplhdr-admin_fee,
        curr_admin    TYPE zrprt_pib_uplhdr-curr_admin,
        insurance     TYPE zrprt_pib_uplhdr-insurance,
        curr_insur    TYPE zrprt_pib_uplhdr-curr_insur,
        row           TYPE i,
      END OF ty_s_hdr.
    TYPES:
      BEGIN OF ty_s_partner,
        tech_no TYPE ty_tech_no,
        row     TYPE i,
        parvw   TYPE zrprt_pib_uplhdr-partner_func,
        lifnr   TYPE zrprt_pib_uplhdr-partner,
        name1   TYPE zrprt_pib_uplhdr-partner_name,
        stras   TYPE zrprt_pib_uplhdr-partner_street,
        pstlz   TYPE zrprt_pib_uplhdr-partner_post_code1,
        ort01   TYPE zrprt_pib_uplhdr-partner_city,
        ktokk   TYPE lfa1-ktokk,
        found   TYPE abap_bool,
      END OF ty_s_partner,
      ty_t_partner TYPE STANDARD TABLE OF ty_s_partner WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_po,
        found_po   TYPE abap_bool,
        found_item TYPE abap_bool,
        open_found TYPE abap_bool,
        bukrs      TYPE ekko-bukrs,
        ekorg      TYPE ekko-ekorg,
        bsart      TYPE ekko-bsart,
        waers      TYPE ekko-waers,
        frgke      TYPE ekko-frgke,
        frgrl      TYPE ekko-frgrl,
        matnr      TYPE ekpo-matnr,
        werks      TYPE ekpo-werks,
        menge      TYPE ekpo-menge,
        meins      TYPE ekpo-meins,
        bpumz      TYPE ekpo-bpumz,
        bpumn      TYPE ekpo-bpumn,
        infnr      TYPE ekpo-infnr,
        netpr      TYPE ekpo-netpr,
        ntgew      TYPE ekpo-ntgew,
        mtart      TYPE ekpo-mtart,
        zuebpo     TYPE ekpo-zuebpo,
        loekz      TYPE ekpo-loekz,
        elikz      TYPE ekpo-elikz,
        bstae      TYPE ekpo-bstae,
        open_qty   TYPE komdlgn-lfimg,
        vrkme      TYPE komdlgn-vrkme,
      END OF ty_s_po,
      BEGIN OF ty_s_item,
        tech_no  TYPE ty_tech_no,
        row      TYPE i,
        fob_file TYPE abap_bool,
        po       TYPE ty_s_po,
        pib      TYPE zrprt_pib_item,
      END OF ty_s_item,
      ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_tech,
        tech_no   TYPE ty_tech_no,
        hdr       TYPE ty_s_hdr,
        hdr_count TYPE i,
        partners  TYPE ty_t_partner,
        items     TYPE ty_t_item,
        parents   TYPE ty_t_item,
        bukrs     TYPE ekko-bukrs,
        ekorg     TYPE ekko-ekorg,
        waers     TYPE ekko-waers,
        tplst     TYPE vttk-tplst,
        shtyp     TYPE vttk-shtyp,
        file_msg  TYPE ty_t_msg,
      END OF ty_s_tech,
      ty_t_tech TYPE STANDARD TABLE OF ty_s_tech WITH EMPTY KEY,
      BEGIN OF ty_s_pkg,
        pkg_no TYPE i,
        tech   TYPE ty_t_tech,
      END OF ty_s_pkg,
      ty_t_pkg TYPE STANDARD TABLE OF ty_s_pkg WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_param,
        test      TYPE abap_bool,
        i007      TYPE abap_bool,
        file_name TYPE zrprt_ibshp_log-file_name,
        run_id    TYPE zrprt_ibshp_log-run_id,
        source    TYPE char1,
      END OF ty_s_param,
      BEGIN OF ty_s_result,
        tech_no      TYPE ty_tech_no,
        legacy_vbeln TYPE zrprt_ibshp_log-legacy_vbeln,
        legacy_tknum TYPE zrprt_ibshp_log-legacy_tknum,
        docnr        TYPE zrprt_ibshp_log-docnr,
        vbeln        TYPE zrprt_ibshp_log-vbeln,
        tknum        TYPE zrprt_ibshp_log-tknum,
        fknum        TYPE zrprt_ibshp_log-fknum,
        status       TYPE zrprt_ibshp_log-status,
        msgty        TYPE zrprt_ibshp_log-msgty,
        message      TYPE string,
      END OF ty_s_result,
      ty_t_result TYPE STANDARD TABLE OF ty_s_result WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_cost_item,
        inbound_item_no TYPE zrprt_pib_item-inbound_item_no,
        fob             TYPE zrprt_pib_item-fob,
      END OF ty_s_cost_item,
      ty_t_cost_item TYPE SORTED TABLE OF ty_s_cost_item WITH NON-UNIQUE KEY inbound_item_no,
      BEGIN OF ty_s_cost_partner,
        parvw TYPE zrprt_pib_header-partner_func,
        lifnr TYPE zrprt_pib_header-partner,
      END OF ty_s_cost_partner,
      ty_t_cost_partner TYPE STANDARD TABLE OF ty_s_cost_partner WITH EMPTY KEY,
      BEGIN OF ty_s_cost_input,
        aju_no        TYPE zrprt_pib_header-aju_no,
        pricing_date  TYPE zrprt_pib_header-pricing_date,
        handling      TYPE zrprt_pib_header-handling,
        curr_handling TYPE zrprt_pib_header-curr_handling,
        admin_fee     TYPE zrprt_pib_header-admin_fee,
        curr_admin    TYPE zrprt_pib_header-curr_admin,
        insurance     TYPE zrprt_pib_header-insurance,
        curr_insur    TYPE zrprt_pib_header-curr_insur,
        bukrs         TYPE ekko-bukrs,
        waers         TYPE ekko-waers,
        tplst         TYPE vttk-tplst,
        shtyp         TYPE vttk-shtyp,
        partners      TYPE ty_t_cost_partner,
        items         TYPE ty_t_cost_item,
      END OF ty_s_cost_input.
    TYPES:
      BEGIN OF ty_s_lips,
        posnr TYPE lips-posnr,
        mtart TYPE lips-mtart,
      END OF ty_s_lips,
      ty_t_lips TYPE STANDARD TABLE OF ty_s_lips WITH EMPTY KEY,
      BEGIN OF ty_s_split,
        tabix TYPE sytabix,
        posnr TYPE lips-posnr,
        value TYPE scprcurr,
      END OF ty_s_split,
      ty_t_split TYPE STANDARD TABLE OF ty_s_split WITH EMPTY KEY,
      BEGIN OF ty_s_open,
        ebeln TYPE ekpo-ebeln,
        ebelp TYPE ekpo-ebelp,
        lfimg TYPE komdlgn-lfimg,
        vrkme TYPE komdlgn-vrkme,
      END OF ty_s_open,
      ty_t_open TYPE SORTED TABLE OF ty_s_open WITH NON-UNIQUE KEY ebeln ebelp.
    TYPES ty_r_run TYPE RANGE OF zrprt_ibshp_log-run_id.
    TYPES ty_r_tech TYPE RANGE OF zrprt_ibshp_log-tech_no.

    CONSTANTS:
      BEGIN OF c_status,
        validated TYPE char1 VALUE 'V',
        error     TYPE char1 VALUE 'E',
        inbound   TYPE char1 VALUE 'I',
        shipment  TYPE char1 VALUE 'S',
        complete  TYPE char1 VALUE 'C',
      END OF c_status,
      c_source_local TYPE char1 VALUE 'L',
      c_source_appl  TYPE char1 VALUE 'A',
      c_asm_article  TYPE mara-mtart VALUE 'ZASM',
      c_shcost_max_rows TYPE sytabix VALUE 5,
      c_sheet_header   TYPE string VALUE `Header`,
      c_sheet_partners TYPE string VALUE `Partners`,
      c_sheet_items    TYPE string VALUE `Items`,
      c_task_fm        TYPE rs38l_fnam VALUE 'Z_RPR_IB_SHP_UPL_TASK'.

    METHODS constructor
      IMPORTING is_param     TYPE ty_s_param
                iv_max_tasks TYPE i DEFAULT 5
                iv_group     TYPE rzlli_apcl OPTIONAL.
    METHODS read_file
      IMPORTING iv_source TYPE c
                iv_path   TYPE string
      EXPORTING ev_xlsx   TYPE xstring
      RAISING   zcx_excel.
    METHODS parse_workbook
      IMPORTING iv_xlsx TYPE xstring
      EXPORTING et_tech TYPE ty_t_tech
                et_msg  TYPE ty_t_msg.
    METHODS validate_file
      CHANGING ct_tech   TYPE ty_t_tech
               ct_result TYPE ty_t_result.
    METHODS build_packages
      IMPORTING it_tech       TYPE ty_t_tech
      RETURNING VALUE(rt_pkg) TYPE ty_t_pkg.
    METHODS process_sequential
      IMPORTING it_tech   TYPE ty_t_tech
      CHANGING  ct_result TYPE ty_t_result.
    METHODS process_parallel
      IMPORTING it_pkg    TYPE ty_t_pkg
      CHANGING  ct_result TYPE ty_t_result.
    METHODS on_task_end
      IMPORTING p_task TYPE clike.

    CLASS-METHODS process_package
      IMPORTING is_param  TYPE ty_s_param
                it_tech   TYPE ty_t_tech
      EXPORTING et_result TYPE ty_t_result.
    CLASS-METHODS process_tech_no
      IMPORTING is_param  TYPE ty_s_param
                is_tech   TYPE ty_s_tech
      CHANGING  cs_result TYPE ty_s_result.
    CLASS-METHODS lock_log
      IMPORTING iv_tech_no   TYPE zrprt_ibshp_log-tech_no
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS unlock_log
      IMPORTING iv_tech_no TYPE zrprt_ibshp_log-tech_no.
    CLASS-METHODS read_log
      IMPORTING iv_tech_no    TYPE zrprt_ibshp_log-tech_no
      RETURNING VALUE(rs_log) TYPE zrprt_ibshp_log.
    CLASS-METHODS write_log
      IMPORTING is_param  TYPE ty_s_param
                is_result TYPE ty_s_result.
    CLASS-METHODS derive_data
      CHANGING  cs_tech       TYPE ty_s_tech
      RETURNING VALUE(rt_msg) TYPE ty_t_msg.
    CLASS-METHODS validate_tech
      IMPORTING is_tech       TYPE ty_s_tech
      RETURNING VALUE(rt_msg) TYPE ty_t_msg.
    CLASS-METHODS create_hold_document
      IMPORTING is_tech       TYPE ty_s_tech
      CHANGING  cv_docnr      TYPE zde_vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS create_inbound_delivery
      EXPORTING ev_vbeln      TYPE vbeln_vl
                ev_split      TYPE abap_bool
      CHANGING  cs_tech       TYPE ty_s_tech
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS save_pib_data
      IMPORTING is_tech       TYPE ty_s_tech
                iv_docnr      TYPE zde_vbeln_vl
                iv_vbeln      TYPE vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS send_i007
      IMPORTING iv_vbeln      TYPE vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS wait_delivery_unlocked
      IMPORTING iv_vbeln     TYPE vbeln_vl
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS create_shipment
      IMPORTING iv_vbeln      TYPE vbeln_vl
                is_cost_input TYPE ty_s_cost_input
      EXPORTING ev_tknum      TYPE tknum
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS add_shipment_partners
      IMPORTING iv_tknum      TYPE tknum
                is_cost_input TYPE ty_s_cost_input
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS create_shipment_cost
      IMPORTING iv_vbeln      TYPE vbeln_vl
                iv_tknum      TYPE tknum
                is_cost_input TYPE ty_s_cost_input
                iv_fknum      TYPE fknum OPTIONAL
      EXPORTING ev_fknum      TYPE fknum
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS read_cost_input
      IMPORTING iv_vbeln             TYPE vbeln_vl
      RETURNING VALUE(rs_cost_input) TYPE ty_s_cost_input.
    CLASS-METHODS download_template.
    CLASS-METHODS build_template
      RETURNING VALUE(rv_xlsx) TYPE xstring
      RAISING   zcx_excel.
    CLASS-METHODS display_result
      IMPORTING it_result TYPE ty_t_result.
    CLASS-METHODS display_log
      IMPORTING it_run_id  TYPE ty_r_run
                it_tech_no TYPE ty_r_tech.

    CLASS-METHODS msg
      IMPORTING iv_id         TYPE symsgid DEFAULT 'ZM_KLG'
                iv_no         TYPE symsgno
                iv_msgty      TYPE symsgty DEFAULT 'E'
                iv_v1         TYPE simple OPTIONAL
                iv_v2         TYPE simple OPTIONAL
                iv_v3         TYPE simple OPTIONAL
                iv_v4         TYPE simple OPTIONAL
      RETURNING VALUE(rs_msg) TYPE ty_s_msg.
    CLASS-METHODS msg055
      IMPORTING iv_text       TYPE csequence
                iv_msgty      TYPE symsgty DEFAULT 'E'
      RETURNING VALUE(rs_msg) TYPE ty_s_msg.
    CLASS-METHODS msg_text
      IMPORTING it_msg         TYPE ty_t_msg
                iv_msgty       TYPE symsgty
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS parse_date
      IMPORTING iv_value     TYPE csequence
      EXPORTING ev_date      TYPE d
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS check_aju
      IMPORTING iv_aju_no      TYPE zrprt_pib_uplhdr-aju_no
                iv_pib_int_ind TYPE zrprt_pib_uplhdr-pib_int_ind
                iv_aju_date    TYPE zrprt_pib_uplhdr-aju_date
      RETURNING VALUE(rt_msg)  TYPE ty_t_msg.
    CLASS-METHODS check_cumulative_qty
      IMPORTING it_open TYPE ty_t_open
                it_skip TYPE ty_t_tech_no
      CHANGING  ct_tech TYPE ty_t_tech.
    CLASS-METHODS compute_fob
      IMPORTING iv_qty        TYPE zrprt_pib_item-qty
                iv_netpr      TYPE ekpo-netpr
                iv_bpumz      TYPE ekpo-bpumz
                iv_bpumn      TYPE ekpo-bpumn
      RETURNING VALUE(rv_fob) TYPE zrprt_pib_item-fob.
    CLASS-METHODS split_cost
      IMPORTING it_lips         TYPE ty_t_lips
                it_items        TYPE ty_t_cost_item
                VALUE(iv_total) TYPE scprcurr
                VALUE(iv_value) TYPE scprcurr
      RETURNING VALUE(rt_split) TYPE ty_t_split.
    CLASS-METHODS get_scost_index
      IMPORTING iv_tabix   TYPE sytabix
                iv_tbl_idx TYPE i
      EXPORTING ev_idx     TYPE numc2
                ev_push    TYPE sytabix.
    CLASS-METHODS get_titles
      IMPORTING iv_sheet        TYPE string
      RETURNING VALUE(rt_title) TYPE string_table.

  PRIVATE SECTION.
    TYPES ty_t_int TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_raw,
        row   TYPE i,
        cells TYPE string_table,
      END OF ty_s_raw,
      ty_t_raw TYPE STANDARD TABLE OF ty_s_raw WITH EMPTY KEY,
      BEGIN OF ty_s_task,
        task   TYPE char32,
        result TYPE ty_t_result,
      END OF ty_s_task,
      BEGIN OF ty_s_alv,
        icon         TYPE icon_d,
        tech_no      TYPE ty_tech_no,
        legacy_vbeln TYPE zrprt_ibshp_log-legacy_vbeln,
        legacy_tknum TYPE zrprt_ibshp_log-legacy_tknum,
        docnr        TYPE zrprt_ibshp_log-docnr,
        vbeln        TYPE zrprt_ibshp_log-vbeln,
        tknum        TYPE zrprt_ibshp_log-tknum,
        fknum        TYPE zrprt_ibshp_log-fknum,
        status       TYPE zrprt_ibshp_log-status,
        msgty        TYPE zrprt_ibshp_log-msgty,
        message      TYPE char255,
        sortkey      TYPE i,
      END OF ty_s_alv.

    DATA ms_param TYPE ty_s_param.
    DATA mv_max_tasks TYPE i.
    DATA mv_group TYPE rzlli_apcl.
    DATA mv_sent TYPE i.
    DATA mv_received TYPE i.
    DATA mv_running TYPE i.
    DATA mt_result TYPE ty_t_result.
    DATA mt_task TYPE STANDARD TABLE OF ty_s_task WITH EMPTY KEY.

    METHODS read_sheet
      IMPORTING io_excel TYPE REF TO zcl_excel
                iv_sheet TYPE string
                iv_cols  TYPE i
      EXPORTING et_rows  TYPE ty_t_raw
      CHANGING  ct_msg   TYPE ty_t_msg
      RAISING   zcx_excel.
    CLASS-METHODS fill_struct
      IMPORTING is_raw       TYPE ty_s_raw
                iv_sheet     TYPE string
                it_fields    TYPE string_table
                it_mandatory TYPE ty_t_int
      CHANGING  cs_struct    TYPE any
                ct_msg       TYPE ty_t_msg.
    CLASS-METHODS conv_value
      IMPORTING iv_value  TYPE string
                iv_label  TYPE string
      CHANGING  cv_target TYPE any
                ct_msg    TYPE ty_t_msg.
    CLASS-METHODS conv_exit
      IMPORTING iv_exit  TYPE string
      CHANGING  cv_value TYPE any.
    CLASS-METHODS finish_error
      IMPORTING is_param   TYPE ty_s_param
                iv_msg     TYPE string
                iv_pib_log TYPE abap_bool DEFAULT abap_false
                iv_aju_no  TYPE zrprt_pib_header-aju_no OPTIONAL
      CHANGING  cs_result  TYPE ty_s_result.
    CLASS-METHODS merge_results
      IMPORTING it_new    TYPE ty_t_result
      CHANGING  ct_result TYPE ty_t_result.
    METHODS fail_package
      IMPORTING it_result TYPE ty_t_result
                iv_msg    TYPE string.
ENDCLASS.



CLASS zcl_rpre_ib_shp_upload IMPLEMENTATION.

  METHOD constructor.
    ms_param = is_param.
    mv_max_tasks = COND #( WHEN iv_max_tasks < 1 THEN 1 WHEN iv_max_tasks > 20 THEN 20 ELSE iv_max_tasks ).
    mv_group = iv_group.
  ENDMETHOD.


  METHOD read_file.
    DATA lt_solix TYPE solix_tab.
    DATA lv_len TYPE i.

    CLEAR ev_xlsx.
    IF iv_source = c_source_local.
      cl_gui_frontend_services=>gui_upload(
        EXPORTING filename   = iv_path
                  filetype   = 'BIN'
        IMPORTING filelength = lv_len
        CHANGING  data_tab   = lt_solix
        EXCEPTIONS OTHERS    = 1 ).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_excel EXPORTING error = |File { iv_path } cannot be read|.
      ENDIF.
      ev_xlsx = cl_bcs_convert=>solix_to_xstring( it_solix = lt_solix iv_size = lv_len ).
    ELSE.
      TRY.
          OPEN DATASET iv_path FOR INPUT IN BINARY MODE.
          IF sy-subrc <> 0.
            RAISE EXCEPTION TYPE zcx_excel EXPORTING error = |File { iv_path } cannot be opened|.
          ENDIF.
          READ DATASET iv_path INTO ev_xlsx.
          CLOSE DATASET iv_path.
        CATCH cx_sy_file_access_error INTO DATA(lx_file).
          RAISE EXCEPTION TYPE zcx_excel EXPORTING error = lx_file->get_text( ).
      ENDTRY.
    ENDIF.
    IF ev_xlsx IS INITIAL.
      RAISE EXCEPTION TYPE zcx_excel EXPORTING error = |File { iv_path } is empty|.
    ENDIF.
  ENDMETHOD.


  METHOD get_titles.
    CASE iv_sheet.
      WHEN c_sheet_header.
        rt_title = VALUE #( ( `Tech No` ) ( `Legacy delivery` ) ( `Legacy shipment` ) ( `Bill of lading` )
          ( `Shipping type` ) ( `Delivery date` ) ( `AJU No` ) ( `AJU date` ) ( `Pricing date` )
          ( `ETD loading port` ) ( `ETA destination port` ) ( `Shipment doc date` )
          ( `PIB interface indicator` ) ( `Handling` ) ( `Handling currency` ) ( `Admin fee` )
          ( `Admin currency` ) ( `Insurance` ) ( `Insurance currency` ) ).
      WHEN c_sheet_partners.
        rt_title = VALUE #( ( `Tech No` ) ( `Partner function` ) ( `Vendor` ) ).
      WHEN c_sheet_items.
        rt_title = VALUE #( ( `Tech No` ) ( `PIB item no` ) ( `PO` ) ( `PO item` ) ( `Material` )
          ( `Material description` ) ( `PIB article description` ) ( `Commodity code` ) ( `Brand` )
          ( `Vendor material no` ) ( `Specification` ) ( `FOB` ) ( `Currency` ) ( `Quantity` ) ( `Unit` )
          ( `Total package` ) ( `Package` ) ( `Country of origin` ) ( `Facility code` ) ( `BM` )
          ( `PPN BM` ) ( `BM tariff code` ) ( `BM unit code` ) ( `BM unit` ) ( `Net weight` )
          ( `BM facility code` ) ( `BM facility rate` ) ( `Custom facility code` )
          ( `Custom facility rate` ) ( `PPN facility code` ) ( `PPN facility rate` )
          ( `PPH facility code` ) ( `PPH facility rate` ) ( `PPNBM facility code` )
          ( `PPNBM facility rate` ) ( `Anti-dumping indicator` ) ( `BM Pengaman` ) ( `BM Imbalan` )
          ( `BM Pembalasan` ) ( `Kode VD` ) ( `Nilai Add. VD` ) ( `Jatuh tempo VD` )
          ( `Indikator Lartas` ) ( `Notes for tally sheet` ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD parse_workbook.
    DATA lo_excel TYPE REF TO zcl_excel.
    DATA lo_reader TYPE REF TO zif_excel_reader.
    DATA lt_hdr_rows TYPE ty_t_raw.
    DATA lt_par_rows TYPE ty_t_raw.
    DATA lt_itm_rows TYPE ty_t_raw.
    DATA ls_hdr TYPE ty_s_hdr.
    DATA ls_par TYPE ty_s_partner.
    DATA ls_item TYPE ty_s_item.
    DATA lv_tech TYPE ty_tech_no.

    CLEAR: et_tech, et_msg.
    TRY.
        lo_reader = NEW zcl_excel_reader_2007( ).
        lo_excel = lo_reader->load( iv_xlsx ).
        read_sheet( EXPORTING io_excel = lo_excel iv_sheet = c_sheet_header
                              iv_cols = lines( get_titles( c_sheet_header ) )
                    IMPORTING et_rows = lt_hdr_rows CHANGING ct_msg = et_msg ).
        read_sheet( EXPORTING io_excel = lo_excel iv_sheet = c_sheet_partners
                              iv_cols = lines( get_titles( c_sheet_partners ) )
                    IMPORTING et_rows = lt_par_rows CHANGING ct_msg = et_msg ).
        read_sheet( EXPORTING io_excel = lo_excel iv_sheet = c_sheet_items
                              iv_cols = lines( get_titles( c_sheet_items ) )
                    IMPORTING et_rows = lt_itm_rows CHANGING ct_msg = et_msg ).
      CATCH zcx_excel INTO DATA(lx_excel).
        APPEND msg055( |File cannot be read as xlsx: { lx_excel->get_text( ) }| ) TO et_msg.
        RETURN.
    ENDTRY.
    IF et_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_hdr_fields) = VALUE string_table( ( `` ) ( `LEGACY_VBELN` ) ( `LEGACY_TKNUM` ) ( `BOLNR` )
      ( `VSART` ) ( `LFDAT` ) ( `AJU_NO` ) ( `AJU_DATE` ) ( `PRICING_DATE` ) ( `ETD_LOAD_PORT` )
      ( `ETA_DST_PORT` ) ( `SHIP_DOC_DATE` ) ( `PIB_INT_IND` ) ( `HANDLING` ) ( `CURR_HANDLING` )
      ( `ADMIN_FEE` ) ( `CURR_ADMIN` ) ( `INSURANCE` ) ( `CURR_INSUR` ) ).
    DATA(lt_par_fields) = VALUE string_table( ( `` ) ( `PARVW` ) ( `LIFNR` ) ).
    DATA(lt_itm_fields) = VALUE string_table( ( `` ) ( `ITEM_NO` ) ( `PO_DOC` ) ( `PO_ITEM` )
      ( `ARTICLE_NO` ) ( `ARTICLE_DESC` ) ( `PIB_ART_DESC` ) ( `HS_CODE` ) ( `BRAND` ) ( `VNDOR_ART_NO` )
      ( `SPEC` ) ( `FOB` ) ( `CURRENCY` ) ( `QTY` ) ( `UOM` ) ( `TOTAL_PCKG` ) ( `PCKG` )
      ( `CNTRY_OF_ORIGIN` ) ( `FACILITY_CODE` ) ( `BM` ) ( `PPNBM` ) ( `BM_TARIFF_CODE` )
      ( `BM_UNIT_CODE` ) ( `BM_UNIT` ) ( `NET_WEIGHT` ) ( `BM_FACILITY_CODE` ) ( `BM_FACILITY_RATE` )
      ( `CUSTOM_FACILITY_CODE` ) ( `CUSTOM_FACILITY_RATE` ) ( `PPN_FACILITY_CODE` )
      ( `PPN_FACILITY_RATE` ) ( `PPH_FACILITY_CODE` ) ( `PPH_FACILITY_RATE` ) ( `PPNBM_FACILITY_CODE` )
      ( `PPNBM_FACILITY_RATE` ) ( `ANTI_DUMPING_IND` ) ( `BM_PENGAMAN` ) ( `BM_IMBALAN` ) ( `BM_BALAS` )
      ( `KODE_VD` ) ( `NILAI_VD` ) ( `JTH_TEMPO_VD` ) ( `INDIKATOR_LARTAS` ) ( `NOTES` ) ).

    " Rows without a Tech No cannot be joined to any delivery, so they stop the run
    LOOP AT lt_hdr_rows INTO DATA(ls_raw).
      lv_tech = ls_raw-cells[ 1 ].
      IF lv_tech IS INITIAL.
        APPEND msg( iv_no = '030' iv_v1 = |Tech No ({ c_sheet_header } row { ls_raw-row })| ) TO et_msg.
        CONTINUE.
      ENDIF.
      READ TABLE et_tech ASSIGNING FIELD-SYMBOL(<ls_tech>) WITH KEY tech_no = lv_tech.
      IF sy-subrc <> 0.
        APPEND VALUE #( tech_no = lv_tech ) TO et_tech ASSIGNING <ls_tech>.
      ENDIF.
      <ls_tech>-hdr_count = <ls_tech>-hdr_count + 1.
      CHECK <ls_tech>-hdr_count = 1.
      CLEAR ls_hdr.
      ls_hdr-tech_no = lv_tech.
      ls_hdr-row = ls_raw-row.
      fill_struct( EXPORTING is_raw = ls_raw iv_sheet = c_sheet_header it_fields = lt_hdr_fields
      " MOD003: Shipping type (column 5) is optional, as in ZVL31N where the
      " shipping type is stored blank. It is still checked against T173 when filled.
"                             it_mandatory = VALUE #( ( 1 ) ( 4 ) ( 5 ) ( 6 ) ( 7 ) ( 8 ) ( 9 ) ( 10 ) ( 11 ) ( 12 ) ) "MOD003.Delete
                             it_mandatory = VALUE #( ( 1 ) ( 4 ) ( 6 ) ( 7 ) ( 8 ) ( 9 ) ( 10 ) ( 11 ) ( 12 ) ) "MOD003.Insert
                   CHANGING  cs_struct = ls_hdr ct_msg = <ls_tech>-file_msg ).
      ls_hdr-vsart = to_upper( ls_hdr-vsart ).
      ls_hdr-pib_int_ind = to_upper( ls_hdr-pib_int_ind ).
      ls_hdr-curr_handling = to_upper( ls_hdr-curr_handling ).
      ls_hdr-curr_admin = to_upper( ls_hdr-curr_admin ).
      ls_hdr-curr_insur = to_upper( ls_hdr-curr_insur ).
      <ls_tech>-hdr = ls_hdr.
    ENDLOOP.

    LOOP AT lt_par_rows INTO ls_raw.
      lv_tech = ls_raw-cells[ 1 ].
      IF lv_tech IS INITIAL.
        APPEND msg( iv_no = '030' iv_v1 = |Tech No ({ c_sheet_partners } row { ls_raw-row })| ) TO et_msg.
        CONTINUE.
      ENDIF.
      READ TABLE et_tech ASSIGNING <ls_tech> WITH KEY tech_no = lv_tech.
      IF sy-subrc <> 0.
        APPEND VALUE #( tech_no = lv_tech ) TO et_tech ASSIGNING <ls_tech>.
      ENDIF.
      CLEAR ls_par.
      ls_par-tech_no = lv_tech.
      ls_par-row = ls_raw-row.
      fill_struct( EXPORTING is_raw = ls_raw iv_sheet = c_sheet_partners it_fields = lt_par_fields
                             it_mandatory = VALUE #( ( 1 ) ( 2 ) ( 3 ) )
                   CHANGING  cs_struct = ls_par ct_msg = <ls_tech>-file_msg ).
      ls_par-parvw = to_upper( ls_par-parvw ).
      " MOD001: file value is already the internal partner function (as in
      " ZVL31N). Input conversion turned SP into AG, so it failed validation.
"      conv_exit( EXPORTING iv_exit = `PARVW` CHANGING cv_value = ls_par-parvw ). "MOD001.Delete
      conv_exit( EXPORTING iv_exit = `ALPHA` CHANGING cv_value = ls_par-lifnr ).
      APPEND ls_par TO <ls_tech>-partners.
    ENDLOOP.

    LOOP AT lt_itm_rows INTO ls_raw.
      lv_tech = ls_raw-cells[ 1 ].
      IF lv_tech IS INITIAL.
        APPEND msg( iv_no = '030' iv_v1 = |Tech No ({ c_sheet_items } row { ls_raw-row })| ) TO et_msg.
        CONTINUE.
      ENDIF.
      READ TABLE et_tech ASSIGNING <ls_tech> WITH KEY tech_no = lv_tech.
      IF sy-subrc <> 0.
        APPEND VALUE #( tech_no = lv_tech ) TO et_tech ASSIGNING <ls_tech>.
      ENDIF.
      CLEAR ls_item.
      ls_item-tech_no = lv_tech.
      ls_item-row = ls_raw-row.
      fill_struct( EXPORTING is_raw = ls_raw iv_sheet = c_sheet_items it_fields = lt_itm_fields
                             it_mandatory = VALUE #( ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 5 ) ( 14 ) ( 15 ) ( 16 ) ( 17 ) ( 19 ) ( 21 ) )
                   CHANGING  cs_struct = ls_item-pib ct_msg = <ls_tech>-file_msg ).
      ls_item-fob_file = xsdbool( ls_raw-cells[ 12 ] IS NOT INITIAL ).
      conv_exit( EXPORTING iv_exit = `ALPHA` CHANGING cv_value = ls_item-pib-po_doc ).
      conv_exit( EXPORTING iv_exit = `MATN1` CHANGING cv_value = ls_item-pib-article_no ).
      ls_item-pib-uom = to_upper( ls_item-pib-uom ).
      ls_item-pib-pckg = to_upper( ls_item-pib-pckg ).
      conv_exit( EXPORTING iv_exit = `CUNIT` CHANGING cv_value = ls_item-pib-uom ).
      conv_exit( EXPORTING iv_exit = `CUNIT` CHANGING cv_value = ls_item-pib-pckg ).
      ls_item-pib-cntry_of_origin = to_upper( ls_item-pib-cntry_of_origin ).
      APPEND ls_item TO <ls_tech>-items.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_sheet.
    DATA lv_value TYPE zexcel_cell_value.
    DATA lv_col TYPE i.
    DATA lv_row TYPE i.
    DATA lv_last TYPE i.
    DATA lv_any TYPE abap_bool.
    DATA ls_raw TYPE ty_s_raw.

    CLEAR et_rows.
    DATA(lo_ws) = io_excel->get_worksheet_by_name( CONV #( iv_sheet ) ).
    IF lo_ws IS NOT BOUND.
      APPEND msg055( |Sheet { iv_sheet } missing or column count wrong| ) TO ct_msg.
      RETURN.
    ENDIF.
    DATA(lv_high_col) = CONV i( lo_ws->get_highest_column( ) ).
    DO lv_high_col TIMES.
      lv_col = sy-index.
      lo_ws->get_cell( EXPORTING ip_column = lv_col ip_row = 1 IMPORTING ep_value = lv_value ).
      IF lv_value IS NOT INITIAL.
        lv_last = lv_col.
      ENDIF.
    ENDDO.
    IF lv_last <> iv_cols.
      APPEND msg055( |Sheet { iv_sheet } missing or column count wrong| ) TO ct_msg.
      RETURN.
    ENDIF.
    DATA(lv_high_row) = CONV i( lo_ws->get_highest_row( ) ).
    lv_row = 2.
    WHILE lv_row <= lv_high_row.
      CLEAR: ls_raw, lv_any.
      ls_raw-row = lv_row.
      DO iv_cols TIMES.
        lv_col = sy-index.
        CLEAR lv_value.
        lo_ws->get_cell( EXPORTING ip_column = lv_col ip_row = lv_row IMPORTING ep_value = lv_value ).
        DATA(lv_str) = lv_value.
        SHIFT lv_str LEFT DELETING LEADING space.
        SHIFT lv_str RIGHT DELETING TRAILING space.
        SHIFT lv_str LEFT DELETING LEADING space.
        APPEND lv_str TO ls_raw-cells.
        IF lv_str IS NOT INITIAL.
          lv_any = abap_true.
        ENDIF.
      ENDDO.
      IF lv_any = abap_true.
        APPEND ls_raw TO et_rows.
      ENDIF.
      lv_row = lv_row + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD fill_struct.
    FIELD-SYMBOLS <lv_target> TYPE any.
    DATA(lt_titles) = get_titles( iv_sheet ).
    LOOP AT is_raw-cells INTO DATA(lv_cell).
      DATA(lv_col) = sy-tabix.
      DATA(lv_label) = |{ VALUE string( lt_titles[ lv_col ] OPTIONAL ) } ({ iv_sheet } row { is_raw-row })|.
      IF lv_cell IS INITIAL.
        IF line_exists( it_mandatory[ table_line = lv_col ] ).
          APPEND msg( iv_no = '030' iv_v1 = lv_label ) TO ct_msg.
        ENDIF.
        CONTINUE.
      ENDIF.
      DATA(lv_field) = VALUE string( it_fields[ lv_col ] OPTIONAL ).
      IF lv_field IS INITIAL.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT lv_field OF STRUCTURE cs_struct TO <lv_target>.
      IF sy-subrc = 0.
        conv_value( EXPORTING iv_value = lv_cell iv_label = lv_label
                    CHANGING cv_target = <lv_target> ct_msg = ct_msg ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD conv_value.
    DATA lv_date TYPE d.
    CLEAR cv_target.
    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_compact) = condense( iv_value ).
    CASE cl_abap_typedescr=>describe_by_data( cv_target )->type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        IF parse_date( EXPORTING iv_value = lv_compact IMPORTING ev_date = lv_date ) = abap_true.
          cv_target = lv_date.
        ELSE.
          APPEND msg055( |{ iv_label } is not a valid date (YYYYMMDD)| ) TO ct_msg.
        ENDIF.
      WHEN cl_abap_typedescr=>typekind_packed OR cl_abap_typedescr=>typekind_float
        OR cl_abap_typedescr=>typekind_int OR cl_abap_typedescr=>typekind_int1
        OR cl_abap_typedescr=>typekind_int2 OR cl_abap_typedescr=>typekind_int8
        OR cl_abap_typedescr=>typekind_decfloat16 OR cl_abap_typedescr=>typekind_decfloat34.
        TRY.
            cv_target = lv_compact.
          CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
            CLEAR cv_target.
            APPEND msg055( |{ iv_label } is not a valid number| ) TO ct_msg.
        ENDTRY.
      WHEN cl_abap_typedescr=>typekind_num.
        IF lv_compact CO '0123456789'.
          cv_target = lv_compact.
        ELSE.
          APPEND msg055( |{ iv_label } is not a valid number| ) TO ct_msg.
        ENDIF.
      WHEN OTHERS.
        cv_target = iv_value.
    ENDCASE.
  ENDMETHOD.


  METHOD conv_exit.
    DATA lv_fm TYPE rs38l_fnam.
    CHECK cv_value IS NOT INITIAL.
    lv_fm = |CONVERSION_EXIT_{ iv_exit }_INPUT|.
    DATA lr_out TYPE REF TO data.
    CREATE DATA lr_out LIKE cv_value.
    ASSIGN lr_out->* TO FIELD-SYMBOL(<lv_out>).
    IF iv_exit = `CUNIT`.
      CALL FUNCTION lv_fm
        EXPORTING  input    = cv_value
                   language = sy-langu
        IMPORTING  output   = <lv_out>
        EXCEPTIONS OTHERS   = 1.
    ELSE.
      CALL FUNCTION lv_fm
        EXPORTING  input  = cv_value
        IMPORTING  output = <lv_out>
        EXCEPTIONS OTHERS = 1.
    ENDIF.
    IF sy-subrc = 0 AND <lv_out> IS NOT INITIAL.
      cv_value = <lv_out>.
    ENDIF.
  ENDMETHOD.


  METHOD parse_date.
    DATA lv_max TYPE i.
    CLEAR ev_date.
    rv_ok = abap_false.
    DATA(lv_s) = CONV string( iv_value ).
    IF strlen( lv_s ) <> 8 OR lv_s CN '0123456789'.
      RETURN.
    ENDIF.
    DATA(lv_y) = CONV i( lv_s(4) ).
    DATA(lv_m) = CONV i( lv_s+4(2) ).
    DATA(lv_d) = CONV i( lv_s+6(2) ).
    IF lv_y < 1 OR lv_m < 1 OR lv_m > 12.
      RETURN.
    ENDIF.
    lv_max = COND #( WHEN lv_m = 4 OR lv_m = 6 OR lv_m = 9 OR lv_m = 11 THEN 30
                     WHEN lv_m = 2 AND ( ( lv_y MOD 4 = 0 AND lv_y MOD 100 <> 0 ) OR lv_y MOD 400 = 0 ) THEN 29
                     WHEN lv_m = 2 THEN 28
                     ELSE 31 ).
    IF lv_d < 1 OR lv_d > lv_max.
      RETURN.
    ENDIF.
    ev_date = lv_s.
    rv_ok = abap_true.
  ENDMETHOD.


  METHOD msg.
    MESSAGE ID iv_id TYPE iv_msgty NUMBER iv_no
      WITH iv_v1 iv_v2 iv_v3 iv_v4 INTO rs_msg-text.
    rs_msg-msgty = iv_msgty.
  ENDMETHOD.


  METHOD msg055.
    " ZM_KLG 055 is "& & & &": the text is wrapped at word boundaries into the four 50-char variables
    DATA lt_var TYPE STANDARD TABLE OF symsgv WITH EMPTY KEY.
    DATA lv_cur TYPE string.
    DATA(lv_text) = condense( CONV string( iv_text ) ).
    SPLIT lv_text AT space INTO TABLE DATA(lt_words).
    LOOP AT lt_words INTO DATA(lv_word).
      DATA(lv_try) = COND string( WHEN lv_cur IS INITIAL THEN lv_word ELSE |{ lv_cur } { lv_word }| ).
      IF strlen( lv_try ) > 50 AND lv_cur IS NOT INITIAL.
        APPEND CONV symsgv( lv_cur ) TO lt_var.
        lv_cur = lv_word.
      ELSE.
        lv_cur = lv_try.
      ENDIF.
    ENDLOOP.
    IF lv_cur IS NOT INITIAL.
      APPEND CONV symsgv( lv_cur ) TO lt_var.
    ENDIF.
    WHILE lines( lt_var ) < 4.
      APPEND INITIAL LINE TO lt_var.
    ENDWHILE.
    rs_msg = msg( iv_no = '055' iv_msgty = iv_msgty
                  iv_v1 = lt_var[ 1 ] iv_v2 = lt_var[ 2 ] iv_v3 = lt_var[ 3 ] iv_v4 = lt_var[ 4 ] ).
    rs_msg-text = condense( rs_msg-text ).
  ENDMETHOD.


  METHOD msg_text.
    LOOP AT it_msg INTO DATA(ls_msg) WHERE msgty = iv_msgty.
      rv_text = COND #( WHEN rv_text IS INITIAL THEN ls_msg-text ELSE |{ rv_text }. { ls_msg-text }| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD check_aju.
    DATA lv_part TYPE char8.
    DATA(lt_parts) = VALUE ty_t_int( ( 6 ) ( 6 ) ( 8 ) ( 6 ) ).
    DATA(lv_off) = 0.
    LOOP AT lt_parts INTO DATA(lv_len).
      DATA(lv_no) = sy-tabix.
      lv_part = iv_aju_no+lv_off(lv_len).
      IF strlen( lv_part ) <> lv_len.
        APPEND msg( iv_no = '057' iv_v1 = |AJU No. Part { lv_no }| iv_v2 = |{ lv_len } Chars| ) TO rt_msg.
      ENDIF.
      lv_off = lv_off + lv_len.
    ENDLOOP.
    IF iv_pib_int_ind IS INITIAL AND iv_aju_date IS NOT INITIAL
       AND iv_aju_no+12(8) <> CONV char8( iv_aju_date ).
      APPEND msg055( `AJU No Part 3 must equal AJU date` ) TO rt_msg.
    ENDIF.
  ENDMETHOD.


  METHOD compute_fob.
    IF iv_bpumn IS INITIAL.
      rv_fob = iv_qty * iv_netpr.
    ELSE.
      rv_fob = iv_qty * iv_netpr * iv_bpumz / iv_bpumn.
    ENDIF.
  ENDMETHOD.


  METHOD check_cumulative_qty.
    TYPES: BEGIN OF ty_cum,
             ebeln   TYPE ekpo-ebeln,
             ebelp   TYPE ekpo-ebelp,
             qty     TYPE komdlgn-lfimg,
             crossed TYPE abap_bool,
           END OF ty_cum.
    DATA lt_cum TYPE HASHED TABLE OF ty_cum WITH UNIQUE KEY ebeln ebelp.
    FIELD-SYMBOLS <ls_cum> TYPE ty_cum.

    LOOP AT ct_tech ASSIGNING FIELD-SYMBOL(<ls_tech>).
      IF line_exists( <ls_tech>-file_msg[ msgty = 'E' ] ) OR line_exists( it_skip[ table_line = <ls_tech>-tech_no ] ).
        CONTINUE.
      ENDIF.
      LOOP AT <ls_tech>-items INTO DATA(ls_item).
        READ TABLE it_open INTO DATA(ls_open)
          WITH KEY ebeln = ls_item-pib-po_doc ebelp = ls_item-pib-po_item.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        READ TABLE lt_cum ASSIGNING <ls_cum> WITH TABLE KEY ebeln = ls_item-pib-po_doc ebelp = ls_item-pib-po_item.
        IF sy-subrc <> 0.
          INSERT VALUE #( ebeln = ls_item-pib-po_doc ebelp = ls_item-pib-po_item ) INTO TABLE lt_cum ASSIGNING <ls_cum>.
        ENDIF.
        IF <ls_cum>-crossed = abap_false.
          <ls_cum>-qty = <ls_cum>-qty + ls_item-pib-qty.
          IF <ls_cum>-qty > ls_open-lfimg.
            <ls_cum>-crossed = abap_true.
          ENDIF.
        ENDIF.
        IF <ls_cum>-crossed = abap_true.
          APPEND msg055( |Quantity exceeds open quantity, PO { ls_item-pib-po_doc ALPHA = OUT } item { ls_item-pib-po_item }| )
            TO <ls_tech>-file_msg.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_file.
    TYPES: BEGIN OF ty_aju,
             aju_no TYPE zrprt_pib_uplhdr-aju_no,
             cnt    TYPE i,
           END OF ty_aju.
    TYPES: BEGIN OF ty_key,
             ebeln TYPE ekpo-ebeln,
             ebelp TYPE ekpo-ebelp,
           END OF ty_key.
    DATA lt_aju TYPE HASHED TABLE OF ty_aju WITH UNIQUE KEY aju_no.
    DATA lt_dup TYPE HASHED TABLE OF ty_key WITH UNIQUE KEY ebeln ebelp.
    DATA lt_key TYPE SORTED TABLE OF ty_key WITH UNIQUE KEY ebeln ebelp.
    DATA lt_skip TYPE ty_t_tech_no.

    LOOP AT ct_tech INTO DATA(ls_tech) WHERE hdr-aju_no IS NOT INITIAL.
      READ TABLE lt_aju ASSIGNING FIELD-SYMBOL(<ls_aju>) WITH TABLE KEY aju_no = ls_tech-hdr-aju_no.
      IF sy-subrc = 0.
        <ls_aju>-cnt = <ls_aju>-cnt + 1.
      ELSE.
        INSERT VALUE #( aju_no = ls_tech-hdr-aju_no cnt = 1 ) INTO TABLE lt_aju.
      ENDIF.
    ENDLOOP.

    LOOP AT ct_tech ASSIGNING FIELD-SYMBOL(<ls_tech>).
      IF <ls_tech>-hdr_count > 1.
        APPEND msg055( |Duplicate upload record, Tech No { <ls_tech>-tech_no }| ) TO <ls_tech>-file_msg.
      ELSEIF <ls_tech>-hdr_count = 0.
        APPEND msg055( |Tech No { <ls_tech>-tech_no } has no header| ) TO <ls_tech>-file_msg.
      ENDIF.
      IF <ls_tech>-items IS INITIAL.
        APPEND msg055( |Tech No { <ls_tech>-tech_no } has no item| ) TO <ls_tech>-file_msg.
      ENDIF.
      IF <ls_tech>-hdr-aju_no IS NOT INITIAL AND lt_aju[ aju_no = <ls_tech>-hdr-aju_no ]-cnt > 1.
        APPEND msg055( |Duplicate upload record, AJU No { <ls_tech>-hdr-aju_no }| ) TO <ls_tech>-file_msg.
      ENDIF.
      CLEAR lt_dup.
      LOOP AT <ls_tech>-items INTO DATA(ls_item).
        INSERT VALUE #( ebeln = ls_item-pib-po_doc ebelp = ls_item-pib-po_item ) INTO TABLE lt_dup.
        IF sy-subrc <> 0.
          APPEND msg055( |Duplicate upload record, PO { ls_item-pib-po_doc ALPHA = OUT } item { ls_item-pib-po_item }| )
            TO <ls_tech>-file_msg.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " A Tech No that already holds an inbound delivery has consumed its open quantity
    IF ct_tech IS NOT INITIAL.
      SELECT tech_no FROM zrprt_ibshp_log
        FOR ALL ENTRIES IN @ct_tech
        WHERE tech_no = @ct_tech-tech_no AND vbeln <> @space
        INTO TABLE @lt_skip.
    ENDIF.
    LOOP AT ct_tech INTO ls_tech.
      IF line_exists( ls_tech-file_msg[ msgty = 'E' ] ) OR line_exists( lt_skip[ table_line = ls_tech-tech_no ] ).
        CONTINUE.
      ENDIF.
      LOOP AT ls_tech-items INTO ls_item.
        INSERT VALUE #( ebeln = ls_item-pib-po_doc ebelp = ls_item-pib-po_item ) INTO TABLE lt_key.
      ENDLOOP.
    ENDLOOP.
    IF lt_key IS NOT INITIAL.
      DATA(lt_open) = lcl_check=>open_qty( CORRESPONDING #( lt_key ) ).
      check_cumulative_qty( EXPORTING it_open = lt_open it_skip = lt_skip CHANGING ct_tech = ct_tech ).
    ENDIF.

    CLEAR ct_result.
    LOOP AT ct_tech INTO ls_tech.
      APPEND VALUE #( tech_no = ls_tech-tech_no legacy_vbeln = ls_tech-hdr-legacy_vbeln
                      legacy_tknum = ls_tech-hdr-legacy_tknum ) TO ct_result ASSIGNING FIELD-SYMBOL(<ls_res>).
      IF line_exists( ls_tech-file_msg[ msgty = 'E' ] ).
        <ls_res>-status = c_status-error.
        <ls_res>-msgty = 'E'.
        <ls_res>-message = msg_text( it_msg = ls_tech-file_msg iv_msgty = 'E' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_packages.
    TYPES: BEGIN OF ty_po,
             ebeln TYPE ekpo-ebeln,
             idx   TYPE i,
           END OF ty_po,
           BEGIN OF ty_root,
             root TYPE i,
             pkg  TYPE i,
           END OF ty_root.
    DATA lt_parent TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lt_po TYPE HASHED TABLE OF ty_po WITH UNIQUE KEY ebeln.
    DATA lt_root TYPE HASHED TABLE OF ty_root WITH UNIQUE KEY root.
    DATA lv_ra TYPE i.
    DATA lv_rb TYPE i.

    DO lines( it_tech ) TIMES.
      APPEND sy-index TO lt_parent.
    ENDDO.
    LOOP AT it_tech INTO DATA(ls_tech).
      DATA(lv_idx) = sy-tabix.
      LOOP AT ls_tech-items INTO DATA(ls_item).
        READ TABLE lt_po INTO DATA(ls_po) WITH TABLE KEY ebeln = ls_item-pib-po_doc.
        IF sy-subrc <> 0.
          INSERT VALUE #( ebeln = ls_item-pib-po_doc idx = lv_idx ) INTO TABLE lt_po.
          CONTINUE.
        ENDIF.
        lv_ra = lv_idx.
        WHILE lt_parent[ lv_ra ] <> lv_ra.
          lv_ra = lt_parent[ lv_ra ].
        ENDWHILE.
        lv_rb = ls_po-idx.
        WHILE lt_parent[ lv_rb ] <> lv_rb.
          lv_rb = lt_parent[ lv_rb ].
        ENDWHILE.
        IF lv_ra < lv_rb.
          lt_parent[ lv_rb ] = lv_ra.
        ELSEIF lv_rb < lv_ra.
          lt_parent[ lv_ra ] = lv_rb.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    LOOP AT it_tech INTO ls_tech.
      lv_ra = sy-tabix.
      WHILE lt_parent[ lv_ra ] <> lv_ra.
        lv_ra = lt_parent[ lv_ra ].
      ENDWHILE.
      READ TABLE lt_root INTO DATA(ls_root) WITH TABLE KEY root = lv_ra.
      IF sy-subrc <> 0.
        APPEND VALUE #( pkg_no = lines( rt_pkg ) + 1 ) TO rt_pkg.
        ls_root = VALUE #( root = lv_ra pkg = lines( rt_pkg ) ).
        INSERT ls_root INTO TABLE lt_root.
      ENDIF.
      ASSIGN rt_pkg[ ls_root-pkg ] TO FIELD-SYMBOL(<ls_pkg>).
      APPEND ls_tech TO <ls_pkg>-tech.
    ENDLOOP.
  ENDMETHOD.


  METHOD merge_results.
    LOOP AT it_new INTO DATA(ls_new).
      READ TABLE ct_result ASSIGNING FIELD-SYMBOL(<ls_res>) WITH KEY tech_no = ls_new-tech_no.
      IF sy-subrc = 0.
        <ls_res> = ls_new.
      ELSE.
        APPEND ls_new TO ct_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD process_sequential.
    process_package( EXPORTING is_param = ms_param it_tech = it_tech IMPORTING et_result = DATA(lt_result) ).
    merge_results( EXPORTING it_new = lt_result CHANGING ct_result = ct_result ).
  ENDMETHOD.


  METHOD process_parallel.
    DATA lv_max TYPE i.
    DATA lv_free TYPE i.
    DATA lv_xstr TYPE xstring.
    DATA lv_task TYPE char32.
    DATA lv_rfcmsg TYPE char255.
    DATA lv_tries TYPE i.

    CLEAR: mt_result, mt_task, mv_sent, mv_received, mv_running.
    CALL FUNCTION 'SPBT_INITIALIZE'
      EXPORTING  group_name                     = mv_group
      IMPORTING  max_pbt_wps                    = lv_max
                 free_pbt_wps                   = lv_free
      EXCEPTIONS invalid_group_name             = 1
                 internal_error                 = 2
                 pbt_env_already_initialized    = 3
                 currently_no_resources_avail   = 4
                 no_pbt_resources_found         = 5
                 cant_init_different_pbt_groups = 6
                 OTHERS                         = 7.
    IF sy-subrc <> 0 AND sy-subrc <> 3.
      DATA(lv_init_rc) = sy-subrc.
      LOOP AT it_pkg INTO DATA(ls_pkg).
        fail_package( it_result = VALUE #( FOR t IN ls_pkg-tech ( tech_no = t-tech_no legacy_vbeln = t-hdr-legacy_vbeln
                                                                  legacy_tknum = t-hdr-legacy_tknum ) )
                      iv_msg = |RFC server group { mv_group } cannot be used (SPBT_INITIALIZE { lv_init_rc })| ).
      ENDLOOP.
      merge_results( EXPORTING it_new = mt_result CHANGING ct_result = ct_result ).
      RETURN.
    ENDIF.

    LOOP AT it_pkg INTO ls_pkg.
      DATA(lt_template) = VALUE ty_t_result( FOR t IN ls_pkg-tech ( tech_no = t-tech_no legacy_vbeln = t-hdr-legacy_vbeln
                                                                    legacy_tknum = t-hdr-legacy_tknum ) ).
      WAIT FOR ASYNCHRONOUS TASKS UNTIL mv_running < mv_max_tasks.
      EXPORT param = ms_param tech = ls_pkg-tech TO DATA BUFFER lv_xstr.
      lv_task = |IBSHP{ ms_param-run_id }{ ls_pkg-pkg_no }|.
      APPEND VALUE #( task = lv_task result = lt_template ) TO mt_task.
      lv_tries = 0.
      DO.
        CLEAR lv_rfcmsg.
        IF mv_group IS INITIAL.
          CALL FUNCTION c_task_fm
            STARTING NEW TASK lv_task
            DESTINATION IN GROUP DEFAULT
            CALLING on_task_end ON END OF TASK
            EXPORTING  iv_data               = lv_xstr
            EXCEPTIONS communication_failure = 1 MESSAGE lv_rfcmsg
                       system_failure        = 2 MESSAGE lv_rfcmsg
                       resource_failure      = 3.
        ELSE.
          CALL FUNCTION c_task_fm
            STARTING NEW TASK lv_task
            DESTINATION IN GROUP mv_group
            CALLING on_task_end ON END OF TASK
            EXPORTING  iv_data               = lv_xstr
            EXCEPTIONS communication_failure = 1 MESSAGE lv_rfcmsg
                       system_failure        = 2 MESSAGE lv_rfcmsg
                       resource_failure      = 3.
        ENDIF.
        CASE sy-subrc.
          WHEN 0.
            mv_running = mv_running + 1.
            mv_sent = mv_sent + 1.
            EXIT.
          WHEN 3.
            lv_tries = lv_tries + 1.
            IF lv_tries > 600.
              fail_package( it_result = lt_template iv_msg = `Task failed: no free work process in RFC server group` ).
              EXIT.
            ENDIF.
            DATA(lv_before) = mv_received.
            IF mv_running = 0.
              WAIT UP TO 1 SECONDS.
            ELSE.
              WAIT FOR ASYNCHRONOUS TASKS UNTIL mv_received > lv_before UP TO 1 SECONDS.
            ENDIF.
          WHEN OTHERS.
            fail_package( it_result = lt_template iv_msg = |Task failed: { lv_rfcmsg }| ).
            EXIT.
        ENDCASE.
      ENDDO.
    ENDLOOP.
    WAIT FOR ASYNCHRONOUS TASKS UNTIL mv_received >= mv_sent.

    DATA(lt_ordered) = VALUE ty_t_result( ).
    LOOP AT it_pkg INTO ls_pkg.
      LOOP AT ls_pkg-tech INTO DATA(ls_tech).
        READ TABLE mt_result INTO DATA(ls_res) WITH KEY tech_no = ls_tech-tech_no.
        IF sy-subrc = 0.
          APPEND ls_res TO lt_ordered.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    merge_results( EXPORTING it_new = lt_ordered CHANGING ct_result = ct_result ).
  ENDMETHOD.


  METHOD fail_package.
    LOOP AT it_result INTO DATA(ls_res).
      CHECK NOT line_exists( mt_result[ tech_no = ls_res-tech_no ] ).
      ls_res-status = c_status-error.
      ls_res-msgty = 'E'.
      ls_res-message = iv_msg.
      APPEND ls_res TO mt_result.
    ENDLOOP.
  ENDMETHOD.


  METHOD on_task_end.
    DATA lv_xstr TYPE xstring.
    DATA lv_rfcmsg TYPE char255.
    DATA lt_result TYPE ty_t_result.

    RECEIVE RESULTS FROM FUNCTION c_task_fm
      IMPORTING  ev_result             = lv_xstr
      EXCEPTIONS communication_failure = 1 MESSAGE lv_rfcmsg
                 system_failure        = 2 MESSAGE lv_rfcmsg
                 OTHERS                = 3.
    DATA(lv_subrc) = sy-subrc.
    mv_received = mv_received + 1.
    mv_running = mv_running - 1.
    IF lv_subrc = 0 AND lv_xstr IS NOT INITIAL.
      TRY.
          IMPORT result = lt_result FROM DATA BUFFER lv_xstr.
          APPEND LINES OF lt_result TO mt_result.
        CATCH cx_sy_import_mismatch_error.
          lv_subrc = 4.
      ENDTRY.
    ENDIF.
    READ TABLE mt_task INTO DATA(ls_task) WITH KEY task = p_task.
    IF sy-subrc = 0.
      fail_package( it_result = ls_task-result iv_msg = |Task failed: { lv_rfcmsg }| ).
    ENDIF.
  ENDMETHOD.


  METHOD process_package.
    CLEAR et_result.
    LOOP AT it_tech INTO DATA(ls_tech).
      DATA(ls_result) = VALUE ty_s_result( tech_no = ls_tech-tech_no legacy_vbeln = ls_tech-hdr-legacy_vbeln
                                           legacy_tknum = ls_tech-hdr-legacy_tknum ).
      process_tech_no( EXPORTING is_param = is_param is_tech = ls_tech CHANGING cs_result = ls_result ).
      APPEND ls_result TO et_result.
    ENDLOOP.
  ENDMETHOD.


  METHOD process_tech_no.
    DATA ls_tech TYPE ty_s_tech.
    DATA lv_msg TYPE string.
    DATA lv_warn TYPE string.
    DATA lv_docnr TYPE zde_vbeln_vl.
    DATA lv_vbeln TYPE vbeln_vl.
    DATA lv_tknum TYPE tknum.
    DATA lv_fknum TYPE fknum.
    DATA lv_split TYPE abap_bool.
    DATA ls_ship_no TYPE zrprs_shipment_no.
    DATA lv_ship_found TYPE abap_bool.
    DATA lv_cost_found TYPE abap_bool.

    ls_tech = is_tech.
    IF lock_log( is_tech-tech_no ) = abap_false.
      cs_result-status = c_status-error.
      cs_result-msgty = 'E'.
      cs_result-message = msg055( |Tech No { is_tech-tech_no } locked| )-text.
      RETURN.
    ENDIF.

    DATA(ls_log) = read_log( is_tech-tech_no ).
    cs_result-docnr = ls_log-docnr.
    cs_result-vbeln = ls_log-vbeln.
    cs_result-tknum = ls_log-tknum.
    cs_result-fknum = ls_log-fknum.
    cs_result-status = ls_log-status.
    IF ls_log-status = c_status-complete.
      cs_result-msgty = 'S'.
      cs_result-message = msg055( `Already complete` )-text.
      unlock_log( is_tech-tech_no ).
      RETURN.
    ENDIF.
    IF line_exists( is_tech-file_msg[ msgty = 'E' ] ).
      finish_error( EXPORTING is_param = is_param iv_msg = msg_text( it_msg = is_tech-file_msg iv_msgty = 'E' )
                    CHANGING cs_result = cs_result ).
      RETURN.
    ENDIF.

    IF ls_log-vbeln IS INITIAL.
      DATA(lt_msg) = derive_data( CHANGING cs_tech = ls_tech ).
      APPEND LINES OF validate_tech( ls_tech ) TO lt_msg.
      lv_warn = msg_text( it_msg = lt_msg iv_msgty = 'W' ).
      IF line_exists( lt_msg[ msgty = 'E' ] ).
        finish_error( EXPORTING is_param = is_param iv_msg = msg_text( it_msg = lt_msg iv_msgty = 'E' )
                      CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.
      IF is_param-test = abap_true.
        cs_result-status = c_status-validated.
        cs_result-msgty = COND #( WHEN lv_warn IS INITIAL THEN 'S' ELSE 'W' ).
        cs_result-message = COND #( WHEN lv_warn IS INITIAL THEN `Validation successful (test run)`
                                    ELSE |Validation successful (test run). { lv_warn }| ).
        unlock_log( is_tech-tech_no ).
        RETURN.
      ENDIF.

      lv_docnr = ls_log-docnr.
      lv_msg = create_hold_document( EXPORTING is_tech = ls_tech CHANGING cv_docnr = lv_docnr ).
      IF lv_msg IS NOT INITIAL.
        ROLLBACK WORK.
        finish_error( EXPORTING is_param = is_param iv_msg = lv_msg CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.
      cs_result-docnr = lv_docnr.
      cs_result-status = c_status-validated.
      cs_result-msgty = 'S'.
      cs_result-message = |Hold document { lv_docnr ALPHA = OUT } saved|.
      write_log( is_param = is_param is_result = cs_result ).
      COMMIT WORK.

      lv_msg = create_inbound_delivery( IMPORTING ev_vbeln = lv_vbeln ev_split = lv_split CHANGING cs_tech = ls_tech ).
      IF lv_msg IS NOT INITIAL.
        ROLLBACK WORK.
        finish_error( EXPORTING is_param = is_param iv_msg = lv_msg CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.

      lv_msg = save_pib_data( is_tech = ls_tech iv_docnr = lv_docnr iv_vbeln = lv_vbeln ).
      IF lv_msg IS NOT INITIAL.
        ROLLBACK WORK.
        finish_error( EXPORTING is_param = is_param iv_msg = lv_msg CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.
      cs_result-vbeln = lv_vbeln.
      cs_result-status = c_status-inbound.
      cs_result-message = |Inbound delivery { lv_vbeln ALPHA = OUT } created|.
      write_log( is_param = is_param is_result = cs_result ).
      COMMIT WORK AND WAIT.
      IF sy-subrc <> 0.
        " The delivery update task failed after the PIB rows were committed: remove them again
        DELETE FROM zrprt_pib_header WHERE inbound_no = @lv_vbeln.
        DELETE FROM zrprt_pib_item WHERE inbound_no = @lv_vbeln.
        DELETE FROM zrprt_pib_link WHERE inbound_no = @lv_vbeln.
        UPDATE zrprt_pib_uplhdr SET ib_link_no = @space WHERE inbound_no = @lv_docnr.
        CLEAR cs_result-vbeln.
        finish_error( EXPORTING is_param = is_param
                                iv_msg = |Update of inbound delivery { lv_vbeln ALPHA = OUT } failed, see SM13|
                      CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.

      IF is_param-i007 = abap_true.
        lv_msg = send_i007( lv_vbeln ).
        IF lv_msg IS NOT INITIAL.
          lv_warn = COND #( WHEN lv_warn IS INITIAL THEN lv_msg ELSE |{ lv_warn }. { lv_msg }| ).
        ENDIF.
      ENDIF.
    ELSEIF is_param-test = abap_true.
      cs_result-msgty = 'S'.
      cs_result-message = |Inbound delivery { ls_log-vbeln ALPHA = OUT } exists, a real run resumes at the shipment step|.
      unlock_log( is_tech-tech_no ).
      RETURN.
    ENDIF.

    lv_vbeln = cs_result-vbeln.
    IF wait_delivery_unlocked( lv_vbeln ) = abap_false.
      finish_error( EXPORTING is_param = is_param
                              iv_msg = |Inbound delivery { lv_vbeln ALPHA = OUT } is still locked, rerun later|
                    CHANGING cs_result = cs_result ).
      RETURN.
    ENDIF.
    SELECT SINGLE vbeln FROM likp WHERE vbeln = @lv_vbeln INTO @DATA(lv_likp).
    IF sy-subrc <> 0.
      finish_error( EXPORTING is_param = is_param iv_msg = msg( iv_no = '045' )-text CHANGING cs_result = cs_result ).
      RETURN.
    ENDIF.
    DATA(ls_cost) = read_cost_input( lv_vbeln ).

    IF cs_result-tknum IS INITIAL.
      CALL FUNCTION 'Z_RPR_GET_SHIPMENT_FOUND'
        EXPORTING im_vbeln          = lv_vbeln
        IMPORTING ex_ship_no        = ls_ship_no
                  ex_shipment_found = lv_ship_found
                  ex_shipcost_found = lv_cost_found.
      IF lv_ship_found = abap_true.
        cs_result-tknum = ls_ship_no-shipment_no.
      ENDIF.
    ENDIF.
    IF cs_result-tknum IS INITIAL.
      lv_msg = create_shipment( EXPORTING iv_vbeln = lv_vbeln is_cost_input = ls_cost IMPORTING ev_tknum = lv_tknum ).
      IF lv_tknum IS NOT INITIAL.
        cs_result-tknum = lv_tknum.
        write_log( is_param = is_param is_result = cs_result ).
        COMMIT WORK.
      ENDIF.
      IF lv_msg IS NOT INITIAL.
        finish_error( EXPORTING is_param = is_param iv_msg = |{ msg( iv_no = '044' iv_v1 = 'Shipment' )-text }. { lv_msg }|
                                iv_pib_log = abap_true iv_aju_no = ls_cost-aju_no
                      CHANGING cs_result = cs_result ).
        RETURN.
      ENDIF.
    ENDIF.
    lv_msg = add_shipment_partners( iv_tknum = cs_result-tknum is_cost_input = ls_cost ).
    IF lv_msg IS NOT INITIAL.
      finish_error( EXPORTING is_param = is_param iv_msg = |{ msg( iv_no = '044' iv_v1 = 'Shipment' )-text }. { lv_msg }|
                              iv_pib_log = abap_true iv_aju_no = ls_cost-aju_no
                    CHANGING cs_result = cs_result ).
      RETURN.
    ENDIF.
    cs_result-status = c_status-shipment.
    cs_result-msgty = 'S'.
    cs_result-message = |Shipment { cs_result-tknum ALPHA = OUT } created|.
    write_log( is_param = is_param is_result = cs_result ).
    COMMIT WORK.

    IF cs_result-fknum IS INITIAL.
      CALL FUNCTION 'Z_RPR_GET_SHIPMENT_FOUND'
        EXPORTING im_vbeln          = lv_vbeln
        IMPORTING ex_ship_no        = ls_ship_no
                  ex_shipment_found = lv_ship_found
                  ex_shipcost_found = lv_cost_found.
      IF lv_cost_found = abap_true.
        cs_result-fknum = ls_ship_no-shipment_cost_no.
      ENDIF.
    ENDIF.
    " Fresh: VI01 + VI02. Restart with an existing shipment cost document (status is not C, so the
    " VI02 cost distribution did not finish): VI02 only. VI02 sets the values, so repeating it is safe.
    lv_msg = create_shipment_cost( EXPORTING iv_vbeln = lv_vbeln iv_tknum = cs_result-tknum is_cost_input = ls_cost
                                             iv_fknum = cs_result-fknum
                                   IMPORTING ev_fknum = lv_fknum ).
    IF lv_fknum IS NOT INITIAL AND cs_result-fknum IS INITIAL.
      cs_result-fknum = lv_fknum.
      write_log( is_param = is_param is_result = cs_result ).
      COMMIT WORK.
    ENDIF.
    IF lv_msg IS NOT INITIAL.
      finish_error( EXPORTING is_param = is_param
                              iv_msg = |{ msg( iv_no = '044' iv_v1 = 'Shipment Cost' )-text }. { lv_msg }. | &&
                                       |Rerun repeats the cost distribution (VI02)|
                              iv_pib_log = abap_true iv_aju_no = ls_cost-aju_no
                    CHANGING cs_result = cs_result ).
      RETURN.
    ENDIF.

    cs_result-status = c_status-complete.
    cs_result-msgty = COND #( WHEN lv_warn IS INITIAL THEN 'S' ELSE 'W' ).
    cs_result-message = |Complete: delivery { cs_result-vbeln ALPHA = OUT }, shipment { cs_result-tknum ALPHA = OUT }, | &&
                        |shipment cost { cs_result-fknum ALPHA = OUT }|.
    IF lv_warn IS NOT INITIAL.
      cs_result-message = |{ cs_result-message }. { lv_warn }|.
    ENDIF.
    write_log( is_param = is_param is_result = cs_result ).
    COMMIT WORK.
    unlock_log( is_tech-tech_no ).
  ENDMETHOD.


  METHOD finish_error.
    DATA ls_pib_log TYPE zrprt_pib_log.
    IF cs_result-vbeln IS INITIAL.
      cs_result-status = c_status-error.
    ENDIF.
    cs_result-msgty = 'E'.
    cs_result-message = iv_msg.
    IF is_param-test = abap_false.
      IF iv_pib_log = abap_true.
        ls_pib_log-aju_no = iv_aju_no.
        ls_pib_log-inbound_no = cs_result-vbeln.
        ls_pib_log-log = iv_msg.
        ls_pib_log-shipment_no = cs_result-tknum.
        ls_pib_log-shipment_cost_no = cs_result-fknum.
        ls_pib_log-last_upd_by = sy-uname.
        ls_pib_log-last_upd = sy-datum.
        ls_pib_log-last_upd_time = sy-uzeit.
        MODIFY zrprt_pib_log FROM @ls_pib_log.
      ENDIF.
      write_log( is_param = is_param is_result = cs_result ).
      COMMIT WORK.
    ENDIF.
    unlock_log( cs_result-tech_no ).
  ENDMETHOD.


  METHOD lock_log.
    DATA lv_varkey TYPE rstable-varkey.
    lv_varkey = |{ sy-mandt }{ iv_tech_no }|.
    " Scope 1 keeps the lock across the intermediate COMMIT WORKs of one Tech No
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING  mode_rstable   = 'E'
                 tabname        = 'ZRPRT_IBSHP_LOG'
                 varkey         = lv_varkey
                 _scope         = '1'
      EXCEPTIONS foreign_lock   = 1
                 system_failure = 2
                 OTHERS         = 3.
    rv_ok = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD unlock_log.
    DATA lv_varkey TYPE rstable-varkey.
    lv_varkey = |{ sy-mandt }{ iv_tech_no }|.
    CALL FUNCTION 'DEQUEUE_E_TABLE'
      EXPORTING mode_rstable = 'E'
                tabname      = 'ZRPRT_IBSHP_LOG'
                varkey       = lv_varkey
                _scope       = '1'.
  ENDMETHOD.


  METHOD read_log.
    SELECT SINGLE * FROM zrprt_ibshp_log WHERE tech_no = @iv_tech_no INTO @rs_log.
  ENDMETHOD.


  METHOD write_log.
    DATA(ls_log) = read_log( is_result-tech_no ).
    IF ls_log IS INITIAL.
      ls_log-tech_no = is_result-tech_no.
      ls_log-ernam = sy-uname.
      ls_log-erdat = sy-datum.
      ls_log-erzet = sy-uzeit.
    ENDIF.
    ls_log-run_id = is_param-run_id.
    ls_log-file_name = is_param-file_name.
    IF is_result-legacy_vbeln IS NOT INITIAL.
      ls_log-legacy_vbeln = is_result-legacy_vbeln.
    ENDIF.
    IF is_result-legacy_tknum IS NOT INITIAL.
      ls_log-legacy_tknum = is_result-legacy_tknum.
    ENDIF.
    ls_log-docnr = is_result-docnr.
    ls_log-vbeln = is_result-vbeln.
    ls_log-tknum = is_result-tknum.
    ls_log-fknum = is_result-fknum.
    ls_log-status = is_result-status.
    ls_log-msgty = is_result-msgty.
    ls_log-message = is_result-message.
    ls_log-aenam = sy-uname.
    ls_log-aedat = sy-datum.
    ls_log-aezet = sy-uzeit.
    MODIFY zrprt_ibshp_log FROM @ls_log.
  ENDMETHOD.


  METHOD derive_data.
    rt_msg = lcl_check=>derive( CHANGING cs_tech = cs_tech ).
  ENDMETHOD.


  METHOD validate_tech.
    rt_msg = lcl_check=>validate( is_tech ).
  ENDMETHOD.


  METHOD create_hold_document.
    rv_msg = lcl_post=>hold_document( EXPORTING is_tech = is_tech CHANGING cv_docnr = cv_docnr ).
  ENDMETHOD.


  METHOD create_inbound_delivery.
    rv_msg = lcl_post=>inbound_delivery( IMPORTING ev_vbeln = ev_vbeln ev_split = ev_split CHANGING cs_tech = cs_tech ).
  ENDMETHOD.


  METHOD save_pib_data.
    rv_msg = lcl_post=>pib_data( is_tech = is_tech iv_docnr = iv_docnr iv_vbeln = iv_vbeln ).
  ENDMETHOD.


  METHOD send_i007.
    rv_msg = lcl_post=>i007( iv_vbeln ).
  ENDMETHOD.


  METHOD wait_delivery_unlocked.
    rv_ok = abap_false.
    DO 10 TIMES.
      CALL FUNCTION 'ENQUEUE_EVVBLKE'
        EXPORTING  vbeln          = iv_vbeln
        EXCEPTIONS foreign_lock   = 1
                   system_failure = 2
                   OTHERS         = 3.
      IF sy-subrc = 0.
        CALL FUNCTION 'DEQUEUE_EVVBLKE'
          EXPORTING vbeln = iv_vbeln.
        rv_ok = abap_true.
        EXIT.
      ENDIF.
      WAIT UP TO 1 SECONDS.
    ENDDO.
  ENDMETHOD.


  METHOD create_shipment.
    rv_msg = lcl_post=>shipment( EXPORTING iv_vbeln = iv_vbeln is_cost_input = is_cost_input IMPORTING ev_tknum = ev_tknum ).
  ENDMETHOD.


  METHOD add_shipment_partners.
    rv_msg = lcl_post=>shipment_partners( iv_tknum = iv_tknum is_cost_input = is_cost_input ).
  ENDMETHOD.


  METHOD create_shipment_cost.
    rv_msg = lcl_post=>shipment_cost( EXPORTING iv_vbeln = iv_vbeln iv_tknum = iv_tknum is_cost_input = is_cost_input
                                                iv_fknum = iv_fknum
                                      IMPORTING ev_fknum = ev_fknum ).
  ENDMETHOD.


  METHOD read_cost_input.
    rs_cost_input = lcl_post=>cost_input( iv_vbeln ).
  ENDMETHOD.


  METHOD split_cost.
    " mirrors ZVL31N form F_UPDATE_ICAT_COST_VALUE (amount part): pro rata by FOB, last item takes the remainder
    DATA lv_aggr TYPE scprcurr.
    DATA lv_fob TYPE scprcurr.
    DATA(lv_lines) = lines( it_lips ).
    LOOP AT it_lips INTO DATA(ls_lips).
      DATA(lv_tabix) = sy-tabix.
      IF ls_lips-mtart = c_asm_article.
        CONTINUE.
      ENDIF.
      READ TABLE it_items INTO DATA(ls_item) WITH KEY inbound_item_no = ls_lips-posnr.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF lv_tabix = lv_lines.
        lv_fob = iv_value - lv_aggr.
        IF lv_fob < 0.
          lv_fob = 0.
        ENDIF.
      ELSE.
        IF iv_total <> 0.
          lv_fob = ( ls_item-fob / iv_total ) * iv_value.
        ENDIF.
        lv_aggr = lv_aggr + lv_fob.
      ENDIF.
      APPEND VALUE #( tabix = lv_tabix posnr = ls_lips-posnr value = lv_fob ) TO rt_split.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_scost_index.
    " mirrors ZVL31N form F_GET_SCOST_INDEX
    DATA lv_idx_tmp TYPE i.
    DATA lv_floor TYPE p DECIMALS 2.
    DATA lv_last_offset TYPE i.

    lv_idx_tmp = iv_tabix.
    lv_floor = floor( iv_tbl_idx / c_shcost_max_rows ).
    lv_last_offset = lv_floor * c_shcost_max_rows.
    IF lv_idx_tmp <= c_shcost_max_rows.
      ev_push = 0.
      ev_idx = lv_idx_tmp.
    ELSEIF lv_idx_tmp > c_shcost_max_rows AND lv_idx_tmp <= lv_last_offset.
      lv_floor = floor( lv_idx_tmp / c_shcost_max_rows ).
      ev_push = lv_floor.
      ev_idx = lv_idx_tmp MOD c_shcost_max_rows.
      IF ev_idx = 0.
        ev_idx = c_shcost_max_rows.
        ev_push = ev_push - 1.
      ENDIF.
    ELSE.
      lv_floor = floor( lv_idx_tmp / c_shcost_max_rows ).
      ev_push = lv_floor.
      ev_idx = c_shcost_max_rows - ( iv_tbl_idx - lv_idx_tmp ).
    ENDIF.
  ENDMETHOD.


  METHOD build_template.
    DATA lo_writer TYPE REF TO zif_excel_writer.
    DATA lo_ws TYPE REF TO zcl_excel_worksheet.
    DATA lv_col TYPE i.

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lo_text) = lo_excel->add_new_style( ).
    lo_text->number_format->format_code = zcl_excel_style_number_format=>c_format_text.
    DATA(lv_text_guid) = lo_text->get_guid( ).
    DATA(lo_title) = lo_excel->add_new_style( ).
    lo_title->font->bold = abap_true.
    lo_title->number_format->format_code = zcl_excel_style_number_format=>c_format_text.
    DATA(lv_title_guid) = lo_title->get_guid( ).

    DATA(lt_sheets) = VALUE string_table( ( c_sheet_header ) ( c_sheet_partners ) ( c_sheet_items ) ).
    LOOP AT lt_sheets INTO DATA(lv_sheet).
      IF sy-tabix = 1.
        lo_ws = lo_excel->get_active_worksheet( ).
      ELSE.
        lo_ws = lo_excel->add_new_worksheet( ).
      ENDIF.
      lo_ws->set_title( CONV #( lv_sheet ) ).
      LOOP AT get_titles( lv_sheet ) INTO DATA(lv_title).
        lv_col = sy-tabix.
        lo_ws->set_cell( ip_column = lv_col ip_row = 1 ip_value = lv_title ip_style = lv_title_guid ).
        DATA(lo_column) = lo_ws->get_column( lv_col ).
        lo_column->set_column_style_by_guid( lv_text_guid ).
        lo_column->set_width( 20 ).
      ENDLOOP.
    ENDLOOP.
    lo_excel->set_active_sheet_index( 1 ).
    lo_writer = NEW zcl_excel_writer_2007( ).
    rv_xlsx = lo_writer->write_file( lo_excel ).
  ENDMETHOD.


  METHOD download_template.
    DATA lv_file TYPE string.
    DATA lv_path TYPE string.
    DATA lv_full TYPE string.
    DATA lv_action TYPE i.

    TRY.
        DATA(lv_xlsx) = build_template( ).
      CATCH zcx_excel INTO DATA(lx_excel).
        MESSAGE lx_excel->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING  default_extension = 'xlsx'
                 default_file_name = 'ZLE_UPLOAD_template.xlsx'
                 file_filter       = 'Excel (*.xlsx)|*.xlsx'
      CHANGING   filename          = lv_file
                 path              = lv_path
                 fullpath          = lv_full
                 user_action       = lv_action
      EXCEPTIONS OTHERS            = 1 ).
    IF sy-subrc <> 0 OR lv_action <> cl_gui_frontend_services=>action_ok OR lv_full IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lt_solix) = cl_bcs_convert=>xstring_to_solix( lv_xlsx ).
    cl_gui_frontend_services=>gui_download(
      EXPORTING  bin_filesize = xstrlen( lv_xlsx )
                 filename     = lv_full
                 filetype     = 'BIN'
      CHANGING   data_tab     = lt_solix
      EXCEPTIONS OTHERS       = 1 ).
    IF sy-subrc = 0.
      MESSAGE s055(zm_klg) WITH 'Template saved to' lv_full.
    ELSE.
      MESSAGE s055(zm_klg) WITH 'Template could not be saved to' lv_full DISPLAY LIKE 'E'.
    ENDIF.
  ENDMETHOD.


  METHOD display_result.
    DATA lt_alv TYPE STANDARD TABLE OF ty_s_alv WITH EMPTY KEY.
    DATA lo_alv TYPE REF TO cl_salv_table.

    LOOP AT it_result INTO DATA(ls_res).
      APPEND CORRESPONDING ty_s_alv( ls_res ) TO lt_alv ASSIGNING FIELD-SYMBOL(<ls_alv>).
      IF ls_res-status = c_status-error OR ls_res-msgty = 'E'.
        <ls_alv>-icon = icon_red_light.
        <ls_alv>-sortkey = 1.
      ELSEIF ls_res-status = c_status-complete.
        <ls_alv>-icon = icon_green_light.
        <ls_alv>-sortkey = 2.
      ELSE.
        <ls_alv>-icon = icon_yellow_light.
        <ls_alv>-sortkey = 2.
      ENDIF.
    ENDLOOP.
    SORT lt_alv STABLE BY sortkey.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv CHANGING t_table = lt_alv ).
        lo_alv->get_functions( )->set_all( abap_true ).
        DATA(lo_cols) = lo_alv->get_columns( ).
        lo_cols->set_optimize( abap_true ).
        lo_cols->get_column( 'SORTKEY' )->set_technical( abap_true ).
        CAST cl_salv_column_table( lo_cols->get_column( 'ICON' ) )->set_icon( if_salv_c_bool_sap=>true ).
        DATA(lt_text) = VALUE string_table( ( `ICON` ) ( `TECH_NO` ) ( `LEGACY_VBELN` ) ( `LEGACY_TKNUM` )
                                            ( `STATUS` ) ( `MESSAGE` ) ).
        DATA(lt_label) = VALUE string_table( ( `Status icon` ) ( `Tech No` ) ( `Legacy delivery` )
                                             ( `Legacy shipment` ) ( `Status` ) ( `Message` ) ).
        LOOP AT lt_text INTO DATA(lv_col).
          DATA(lv_label) = lt_label[ sy-tabix ].
          DATA(lo_col) = lo_cols->get_column( CONV #( lv_col ) ).
          lo_col->set_long_text( CONV #( lv_label ) ).
          lo_col->set_medium_text( CONV #( lv_label ) ).
          lo_col->set_short_text( CONV #( lv_label ) ).
        ENDLOOP.
        lo_alv->display( ).
      CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error.
        MESSAGE s055(zm_klg) WITH 'Result list cannot be displayed' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD display_log.
    SELECT * FROM zrprt_ibshp_log
      WHERE run_id IN @it_run_id AND tech_no IN @it_tech_no
      ORDER BY tech_no
      INTO TABLE @DATA(lt_log).
    IF lt_log IS INITIAL.
      MESSAGE s055(zm_klg) WITH 'No log entries found' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    display_result( VALUE #( FOR l IN lt_log ( tech_no = l-tech_no legacy_vbeln = l-legacy_vbeln
                                               legacy_tknum = l-legacy_tknum docnr = l-docnr vbeln = l-vbeln
                                               tknum = l-tknum fknum = l-fknum status = l-status msgty = l-msgty
                                               message = l-message ) ) ).
  ENDMETHOD.

ENDCLASS.