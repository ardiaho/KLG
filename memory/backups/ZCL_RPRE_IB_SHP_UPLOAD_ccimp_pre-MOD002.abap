*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_check DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES ty_t_msg TYPE zcl_rpre_ib_shp_upload=>ty_t_msg.
    TYPES:
      BEGIN OF ty_key,
        ebeln TYPE ekpo-ebeln,
        ebelp TYPE ekpo-ebelp,
      END OF ty_key,
      ty_t_key TYPE STANDARD TABLE OF ty_key WITH EMPTY KEY,
      BEGIN OF ty_s_lfa_acct,
        acct_parvw TYPE tpart-parvw,
        acct_grp   TYPE lfa1-ktokk,
      END OF ty_s_lfa_acct,
      BEGIN OF ty_s_bukrs2tplst,
        bukrs TYPE t001-bukrs,
        tplst TYPE vttk-tplst,
        shtyp TYPE vttk-shtyp,
      END OF ty_s_bukrs2tplst,
      BEGIN OF ty_s_fld,
        field_name TYPE zzcat_custobj-field_name,
      END OF ty_s_fld,
      ty_t_fld TYPE STANDARD TABLE OF ty_s_fld WITH EMPTY KEY.
    CLASS-DATA gt_parvw TYPE SORTED TABLE OF parvw WITH UNIQUE KEY table_line.
    CLASS-DATA gt_lfa_acct TYPE STANDARD TABLE OF ty_s_lfa_acct WITH EMPTY KEY.
    CLASS-DATA gt_bukrs2tplst TYPE HASHED TABLE OF ty_s_bukrs2tplst WITH UNIQUE KEY bukrs.
    CLASS-DATA gr_ekorg TYPE efg_tab_ranges.
    CLASS-DATA gr_bstae TYPE efg_tab_ranges.
    CLASS-DATA gr_bsart TYPE efg_tab_ranges.
    CLASS-DATA gv_loaded TYPE abap_bool.
    CLASS-METHODS load_e014.
    CLASS-METHODS parvw_in
      IMPORTING iv_ext          TYPE csequence
      RETURNING VALUE(rv_parvw) TYPE parvw.
    CLASS-METHODS parvw_out
      IMPORTING iv_parvw      TYPE parvw
      RETURNING VALUE(rv_ext) TYPE tpart-parvw.
    CLASS-METHODS open_qty
      IMPORTING it_key         TYPE ty_t_key
      RETURNING VALUE(rt_open) TYPE zcl_rpre_ib_shp_upload=>ty_t_open.
    CLASS-METHODS derive
      CHANGING  cs_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
      RETURNING VALUE(rt_msg) TYPE ty_t_msg.
    CLASS-METHODS validate
      IMPORTING is_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
      RETURNING VALUE(rt_msg) TYPE ty_t_msg.
    CLASS-METHODS to_internal
      IMPORTING iv_curr   TYPE waers
      CHANGING  cv_amount TYPE p.
ENDCLASS.


CLASS lcl_check IMPLEMENTATION.

  METHOD load_e014.
    " mirrors ZVL31N forms F_GET_PARTNER_FUNC, F_GET_VENDOR_ACC_GROUP, F_GET_MAPPING_COMP_TO_TPLST, F_GET_PO_DATA
    DATA lo_ref TYPE REF TO data.
    DATA lv_parvw TYPE parvw.
    CHECK gv_loaded = abap_false.
    SELECT field_value FROM zzcat_custobj
      WHERE objid = 'E014' AND field_name = 'PARVW'
      INTO TABLE @DATA(lt_val).
    LOOP AT lt_val INTO DATA(ls_val).
      CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
        EXPORTING input  = ls_val-field_value
        IMPORTING output = lv_parvw.
      INSERT lv_parvw INTO TABLE gt_parvw.
    ENDLOOP.

    DATA(lt_hdr) = VALUE ty_t_fld( ( field_name = 'ACCT_GRP' ) ( field_name = 'ACCT_PARVW' ) ).
    GET REFERENCE OF gt_lfa_acct INTO lo_ref.
    CALL FUNCTION 'Z_ZCA_GET_CUST_OBJ'
      EXPORTING  im_objid          = 'E014'
                 im_active         = abap_true
      IMPORTING  ex_tbl_data       = lo_ref
      TABLES     it_tbl_hdr        = lt_hdr
      EXCEPTIONS get_custobj_error = 1
                 OTHERS            = 2.
    IF sy-subrc <> 0.
      CLEAR gt_lfa_acct.
    ENDIF.

    lt_hdr = VALUE #( ( field_name = 'BUKRS' ) ( field_name = 'TPLST' ) ( field_name = 'SHTYP' ) ).
    GET REFERENCE OF gt_bukrs2tplst INTO lo_ref.
    CALL FUNCTION 'Z_ZCA_GET_CUST_OBJ'
      EXPORTING  im_objid          = 'E014'
                 im_active         = abap_true
      IMPORTING  ex_tbl_data       = lo_ref
      TABLES     it_tbl_hdr        = lt_hdr
      EXCEPTIONS get_custobj_error = 1
                 OTHERS            = 2.
    IF sy-subrc <> 0.
      CLEAR gt_bukrs2tplst.
    ENDIF.

    gr_ekorg = zcl_utilities=>get_range_of_custobj( im_objid = 'E014' im_field_name = 'EKORG' im_ref_field = 'P1' ).
    gr_bstae = zcl_utilities=>get_range_of_custobj( im_objid = 'E014' im_field_name = 'BSTAE' im_ref_field = 'P2' ).
    gr_bsart = zcl_utilities=>get_range_of_custobj( im_objid = 'E014' im_field_name = 'BSART' im_ref_field = 'P3' ).
    gv_loaded = abap_true.
  ENDMETHOD.


  METHOD parvw_in.
    CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
      EXPORTING input  = iv_ext
      IMPORTING output = rv_parvw.
  ENDMETHOD.


  METHOD parvw_out.
    CALL FUNCTION 'CONVERSION_EXIT_PARVW_OUTPUT'
      EXPORTING input  = iv_parvw
      IMPORTING output = rv_ext.
  ENDMETHOD.


  METHOD open_qty.
    " mirrors ZVL31N form F_GET_UNDELIVERED_QTY
    DATA lt_kom TYPE STANDARD TABLE OF komdlgn.
    DATA lt_wueb TYPE STANDARD TABLE OF wueb.
    CHECK it_key IS NOT INITIAL.
    lt_wueb = VALUE #( FOR k IN it_key ( ebeln = k-ebeln ebelp = k-ebelp ) ).
    CALL FUNCTION 'ME_CONFIRMATION_READ_AVIS'
      EXPORTING ldate  = sy-datum
      TABLES    t_kom  = lt_kom
                t_wueb = lt_wueb.
    LOOP AT lt_kom INTO DATA(ls_kom).
      DATA(lv_ebelp) = CONV ebelp( ls_kom-vgpos ).
      IF NOT line_exists( rt_open[ ebeln = ls_kom-vgbel ebelp = lv_ebelp ] ).
        INSERT VALUE #( ebeln = ls_kom-vgbel ebelp = lv_ebelp lfimg = ls_kom-lfimg vrkme = ls_kom-vrkme )
          INTO TABLE rt_open.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD to_internal.
    DATA lv_disp TYPE wmto_s-amount.
    DATA lv_int TYPE wmto_s-amount.
    CHECK iv_curr IS NOT INITIAL AND cv_amount IS NOT INITIAL.
    lv_disp = cv_amount.
    CALL FUNCTION 'CURRENCY_AMOUNT_DISPLAY_TO_SAP'
      EXPORTING  currency        = iv_curr
                 amount_display  = lv_disp
      IMPORTING  amount_internal = lv_int
      EXCEPTIONS internal_error  = 1
                 OTHERS          = 2.
    IF sy-subrc = 0.
      cv_amount = lv_int.
    ENDIF.
  ENDMETHOD.


  METHOD derive.
    " mirrors ZVL31N forms F_GET_PO_VALUES, F_GET_DEFAULT_VALUES, F_ASSIGN_VALUES, F_GET_COMP_CODE,
    " F_UPDATE_PARTNER_DATA and F_GET_PARENT_DATA
    TYPES: BEGIN OF ty_set,
             ebeln  TYPE ekpo-ebeln,
             zuebpo TYPE ekpo-zuebpo,
           END OF ty_set.
    DATA lt_set TYPE SORTED TABLE OF ty_set WITH UNIQUE KEY ebeln zuebpo.
    DATA lt_key TYPE ty_t_key.
    DATA lt_lines TYPE STANDARD TABLE OF tline.
    DATA lv_name TYPE thead-tdname.
    DATA lt_wueb TYPE STANDARD TABLE OF wueb.
    DATA lt_kom TYPE STANDARD TABLE OF komdlgn.
    DATA lv_posnr TYPE lips-posnr.
    DATA lv_brand_id TYPE mara-brand_id.
    DATA ls_parent TYPE zcl_rpre_ib_shp_upload=>ty_s_item.

    load_e014( ).
    CHECK cs_tech-items IS NOT INITIAL.
    lt_key = VALUE #( FOR i IN cs_tech-items ( ebeln = i-pib-po_doc ebelp = i-pib-po_item ) ).
    SELECT ebeln, bukrs, ekorg, bsart, waers, frgke, frgrl FROM ekko
      FOR ALL ENTRIES IN @lt_key WHERE ebeln = @lt_key-ebeln
      INTO TABLE @DATA(lt_ekko).
    SELECT ebeln, ebelp, matnr, werks, menge, meins, bpumz, bpumn, infnr, netpr, ntgew, mtart, zuebpo,
           loekz, elikz, bstae
      FROM ekpo FOR ALL ENTRIES IN @lt_key WHERE ebeln = @lt_key-ebeln AND ebelp = @lt_key-ebelp
      INTO TABLE @DATA(lt_ekpo).
    DATA(lt_open) = open_qty( lt_key ).

    READ TABLE lt_ekko INTO DATA(ls_ekko) WITH KEY ebeln = cs_tech-items[ 1 ]-pib-po_doc.
    IF sy-subrc = 0.
      cs_tech-bukrs = ls_ekko-bukrs.
      cs_tech-ekorg = ls_ekko-ekorg.
      cs_tech-waers = ls_ekko-waers.
    ENDIF.
    READ TABLE gt_bukrs2tplst INTO DATA(ls_map) WITH TABLE KEY bukrs = cs_tech-bukrs.
    IF sy-subrc = 0.
      cs_tech-tplst = ls_map-tplst.
      cs_tech-shtyp = ls_map-shtyp.
    ENDIF.

    IF lt_ekpo IS NOT INITIAL.
      SELECT matnr, mtart, brand_id FROM mara FOR ALL ENTRIES IN @lt_ekpo WHERE matnr = @lt_ekpo-matnr
        INTO TABLE @DATA(lt_mara).
      SELECT matnr, maktx FROM makt FOR ALL ENTRIES IN @lt_ekpo
        WHERE matnr = @lt_ekpo-matnr AND spras = @sy-langu
        INTO TABLE @DATA(lt_makt).
      SELECT infnr, matnr, idnlf, urzla FROM eina FOR ALL ENTRIES IN @lt_ekpo
        WHERE infnr = @lt_ekpo-infnr AND matnr = @lt_ekpo-matnr
        INTO TABLE @DATA(lt_eina).
      DATA(lv_stcts) = zcl_utilities=>get_default_commcode_numscheme( ).
      SELECT matnr, ccngn FROM /sapsll/maritc FOR ALL ENTRIES IN @lt_ekpo
        WHERE matnr = @lt_ekpo-matnr AND stcts = @lv_stcts AND datab <= @sy-datum AND datbi >= @sy-datum
        INTO TABLE @DATA(lt_maritc).
      IF lt_mara IS NOT INITIAL.
        SELECT brand_id, brand_descr FROM wrf_brands_t FOR ALL ENTRIES IN @lt_mara
          WHERE brand_id = @lt_mara-brand_id AND language = 'E'
          INTO TABLE @DATA(lt_brand).
      ENDIF.
    ENDIF.

    LOOP AT cs_tech-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      READ TABLE lt_ekko INTO ls_ekko WITH KEY ebeln = <ls_item>-pib-po_doc.
      IF sy-subrc = 0.
        <ls_item>-po-found_po = abap_true.
        <ls_item>-po-bukrs = ls_ekko-bukrs.
        <ls_item>-po-ekorg = ls_ekko-ekorg.
        <ls_item>-po-bsart = ls_ekko-bsart.
        <ls_item>-po-waers = ls_ekko-waers.
        <ls_item>-po-frgke = ls_ekko-frgke.
        <ls_item>-po-frgrl = ls_ekko-frgrl.
      ENDIF.
      READ TABLE lt_ekpo INTO DATA(ls_ekpo) WITH KEY ebeln = <ls_item>-pib-po_doc ebelp = <ls_item>-pib-po_item.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      <ls_item>-po = CORRESPONDING #( BASE ( <ls_item>-po ) ls_ekpo ).
      <ls_item>-po-found_item = abap_true.
      READ TABLE lt_open INTO DATA(ls_open) WITH KEY ebeln = <ls_item>-pib-po_doc ebelp = <ls_item>-pib-po_item.
      IF sy-subrc = 0.
        <ls_item>-po-open_found = abap_true.
        <ls_item>-po-open_qty = ls_open-lfimg.
        <ls_item>-po-vrkme = ls_open-vrkme.
      ENDIF.

      <ls_item>-pib-article_desc = VALUE #( lt_makt[ matnr = ls_ekpo-matnr ]-maktx OPTIONAL ).
      lv_brand_id = VALUE #( lt_mara[ matnr = ls_ekpo-matnr ]-brand_id OPTIONAL ).
      <ls_item>-pib-brand = VALUE #( lt_brand[ brand_id = lv_brand_id ]-brand_descr OPTIONAL ).
      READ TABLE lt_eina INTO DATA(ls_eina) WITH KEY infnr = ls_ekpo-infnr matnr = ls_ekpo-matnr.
      IF sy-subrc = 0.
        <ls_item>-pib-vndor_art_no = ls_eina-idnlf.
        <ls_item>-pib-cntry_of_origin = ls_eina-urzla.
      ELSE.
        CLEAR: <ls_item>-pib-vndor_art_no, <ls_item>-pib-cntry_of_origin.
      ENDIF.
      <ls_item>-pib-currency = <ls_item>-po-waers.
      IF <ls_item>-pib-net_weight IS INITIAL.
        <ls_item>-pib-net_weight = ls_ekpo-ntgew.
      ENDIF.
      " The commodity code from the GTS classification wins; the file value is only the fallback
      READ TABLE lt_maritc INTO DATA(ls_maritc) WITH KEY matnr = ls_ekpo-matnr.
      IF sy-subrc = 0.
        <ls_item>-pib-hs_code = ls_maritc-ccngn.
      ENDIF.
      IF <ls_item>-fob_file = abap_true.
        to_internal( EXPORTING iv_curr = <ls_item>-po-waers CHANGING cv_amount = <ls_item>-pib-fob ).
      ELSE.
        <ls_item>-pib-fob = zcl_rpre_ib_shp_upload=>compute_fob( iv_qty = <ls_item>-pib-qty iv_netpr = ls_ekpo-netpr
                                                                 iv_bpumz = ls_ekpo-bpumz iv_bpumn = ls_ekpo-bpumn ).
      ENDIF.
    ENDLOOP.

    LOOP AT cs_tech-items ASSIGNING <ls_item>.
      IF <ls_item>-pib-bm_tariff_code IS INITIAL.
        <ls_item>-pib-bm_tariff_code = '1'.
      ENDIF.
      IF <ls_item>-pib-pib_art_desc IS INITIAL AND <ls_item>-pib-article_no IS NOT INITIAL.
        CLEAR lt_lines.
        lv_name = <ls_item>-pib-article_no.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING  id       = 'PRUE'
                     language = sy-langu
                     name     = lv_name
                     object   = 'MATERIAL'
          TABLES     lines    = lt_lines
          EXCEPTIONS OTHERS   = 8.
        IF sy-subrc = 0.
          LOOP AT lt_lines INTO DATA(ls_line).
            CONCATENATE <ls_item>-pib-pib_art_desc ls_line-tdline INTO <ls_item>-pib-pib_art_desc SEPARATED BY space.
          ENDLOOP.
          CONDENSE <ls_item>-pib-pib_art_desc.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF cs_tech-partners IS NOT INITIAL.
      SELECT lifnr, name1, ort01, pstlz, stras, ktokk FROM lfa1
        FOR ALL ENTRIES IN @cs_tech-partners WHERE lifnr = @cs_tech-partners-lifnr
        INTO TABLE @DATA(lt_lfa1).
      LOOP AT cs_tech-partners ASSIGNING FIELD-SYMBOL(<ls_par>).
        READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = <ls_par>-lifnr.
        IF sy-subrc = 0.
          <ls_par>-found = abap_true.
          <ls_par>-name1 = ls_lfa1-name1.
          <ls_par>-stras = ls_lfa1-stras.
          <ls_par>-pstlz = ls_lfa1-pstlz.
          <ls_par>-ort01 = ls_lfa1-ort01.
          <ls_par>-ktokk = ls_lfa1-ktokk.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF cs_tech-hdr-curr_insur IS INITIAL.
      cs_tech-hdr-curr_insur = cs_tech-waers.
    ENDIF.
    to_internal( EXPORTING iv_curr = cs_tech-hdr-curr_handling CHANGING cv_amount = cs_tech-hdr-handling ).
    to_internal( EXPORTING iv_curr = cs_tech-hdr-curr_admin CHANGING cv_amount = cs_tech-hdr-admin_fee ).
    to_internal( EXPORTING iv_curr = cs_tech-hdr-curr_insur CHANGING cv_amount = cs_tech-hdr-insurance ).

    " Parent items of set articles
    LOOP AT cs_tech-items INTO DATA(ls_it).
      INSERT VALUE #( ebeln = ls_it-pib-po_doc zuebpo = ls_it-po-zuebpo ) INTO TABLE lt_set.
    ENDLOOP.
    " Same filter as ZVL31N F_GET_PARENT_DATA: set-article lines are skipped here, so the parent
    " quantity falls back to EKPO-MENGE / MEINS
    LOOP AT lt_set INTO DATA(ls_set).
      IF ls_set-ebeln IS NOT INITIAL AND ls_set-zuebpo IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( ebeln = ls_set-ebeln ebelp = ls_set-zuebpo ) TO lt_wueb.
    ENDLOOP.
    IF lt_wueb IS NOT INITIAL.
      CALL FUNCTION 'ME_CONFIRMATION_READ_AVIS'
        EXPORTING ldate  = sy-datum
        TABLES    t_kom  = lt_kom
                  t_wueb = lt_wueb.
    ENDIF.
    CLEAR cs_tech-parents.
    IF lt_set IS NOT INITIAL.
      SELECT ebeln, ebelp, matnr, menge, meins, infnr FROM ekpo
        FOR ALL ENTRIES IN @lt_set WHERE ebeln = @lt_set-ebeln AND ebelp = @lt_set-zuebpo
        INTO TABLE @DATA(lt_par_po).
    ENDIF.
    IF lt_par_po IS NOT INITIAL.
      SELECT matnr, maktx FROM makt FOR ALL ENTRIES IN @lt_par_po
        WHERE matnr = @lt_par_po-matnr AND spras = @sy-langu
        INTO TABLE @DATA(lt_par_makt).
      SELECT infnr, matnr, idnlf FROM eina FOR ALL ENTRIES IN @lt_par_po
        WHERE infnr = @lt_par_po-infnr AND matnr = @lt_par_po-matnr
        INTO TABLE @DATA(lt_par_eina).
    ENDIF.
    SORT lt_par_po BY ebeln ebelp.
    LOOP AT lt_par_po INTO DATA(ls_par_po).
      CLEAR ls_parent.
      ls_parent-tech_no = cs_tech-tech_no.
      ls_parent-pib-article_no = ls_par_po-matnr.
      ls_parent-pib-qty = ls_par_po-menge.
      ls_parent-pib-uom = ls_par_po-meins.
      ls_parent-pib-po_doc = ls_par_po-ebeln.
      ls_parent-pib-po_item = ls_par_po-ebelp.
      READ TABLE lt_kom INTO DATA(ls_kom) WITH KEY vgbel = ls_par_po-ebeln vgpos = ls_par_po-ebelp.
      IF sy-subrc = 0.
        ls_parent-pib-qty = ls_kom-lfimg.
        ls_parent-pib-uom = ls_kom-vrkme.
      ENDIF.
      ls_parent-pib-article_desc = VALUE #( lt_par_makt[ matnr = ls_par_po-matnr ]-maktx OPTIONAL ).
      ls_parent-pib-vndor_art_no = VALUE #( lt_par_eina[ infnr = ls_par_po-infnr matnr = ls_par_po-matnr ]-idnlf OPTIONAL ).
      APPEND ls_parent TO cs_tech-parents.
    ENDLOOP.

    " Delivery item numbers: parents first, then the file items in file order
    LOOP AT cs_tech-parents ASSIGNING FIELD-SYMBOL(<ls_parent>).
      lv_posnr = lv_posnr + 10.
      <ls_parent>-pib-inbound_item_no = lv_posnr.
    ENDLOOP.
    LOOP AT cs_tech-items ASSIGNING <ls_item>.
      lv_posnr = lv_posnr + 10.
      <ls_item>-pib-inbound_item_no = lv_posnr.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate.
    " mirrors ZVL31N forms F_VALIDATE_HEADER_DATA, F_VALIDATE_ITEM_DATA, F_UPDATE_PARTNER_DATA,
    " F_CHECK_VENDOR_ACT_GROUP, F_VALIDATE_PARTNER_EKORG and F_GET_FILTERED_QTY
    TYPES: BEGIN OF ty_set,
             ebeln  TYPE ekpo-ebeln,
             zuebpo TYPE ekpo-zuebpo,
           END OF ty_set.
    DATA lt_set TYPE SORTED TABLE OF ty_set WITH UNIQUE KEY ebeln zuebpo.
    DATA lt_seen TYPE SORTED TABLE OF parvw WITH UNIQUE KEY table_line.
    DATA lt_werks TYPE SORTED TABLE OF werks_d WITH UNIQUE KEY table_line.
    DATA lv_diff_org TYPE abap_bool.
    FIELD-SYMBOLS <lv_a> TYPE any.
    FIELD-SYMBOLS <lv_b> TYPE any.

    load_e014( ).
    DATA(ls_h) = is_tech-hdr.
    rt_msg = zcl_rpre_ib_shp_upload=>check_aju( iv_aju_no = ls_h-aju_no iv_pib_int_ind = ls_h-pib_int_ind
                                               iv_aju_date = ls_h-aju_date ).
    IF ls_h-aju_date IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'AJU Date' ) TO rt_msg.
    ENDIF.
    IF ls_h-pricing_date IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Pricing Date' ) TO rt_msg.
    ENDIF.
    IF ls_h-bolnr IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Bill of Ladding' ) TO rt_msg.
    ENDIF.
    IF ls_h-lfdat IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Delivery Date' ) TO rt_msg.
    ENDIF.
    IF ls_h-etd_load_port IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'ETD Loading Port' ) TO rt_msg.
    ENDIF.
    IF ls_h-eta_dst_port IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'ETA Destination Port' ) TO rt_msg.
    ENDIF.
    IF ls_h-ship_doc_date IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Shipment Doc Date' ) TO rt_msg.
    ENDIF.

    IF is_tech-partners IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Partner' ) TO rt_msg.
    ENDIF.
    DATA(lv_cr) = parvw_in( 'CR' ).
    DATA(lv_zd) = parvw_in( 'ZD' ).
    DATA(lv_zi) = parvw_in( 'ZI' ).
    LOOP AT is_tech-partners INTO DATA(ls_par).
      DATA(lv_ext) = parvw_out( ls_par-parvw ).
      IF NOT line_exists( gt_parvw[ table_line = ls_par-parvw ] ).
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Partner function { lv_ext } not allowed| ) TO rt_msg.
      ENDIF.
      INSERT ls_par-parvw INTO TABLE lt_seen.
      IF sy-subrc <> 0.
        APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '026' iv_v1 = lv_ext ) TO rt_msg.
      ENDIF.
      IF ls_par-found = abap_false.
        APPEND zcl_rpre_ib_shp_upload=>msg( iv_id = '/SPE/INBVAL' iv_no = '056' iv_v1 = |{ ls_par-lifnr ALPHA = OUT }| )
          TO rt_msg.
        CONTINUE.
      ENDIF.
      READ TABLE gt_lfa_acct INTO DATA(ls_acct) WITH KEY acct_parvw = lv_ext.
      IF sy-subrc <> 0 OR ls_acct-acct_grp <> ls_par-ktokk.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Vendor account group does not match, vendor { ls_par-lifnr ALPHA = OUT }| )
          TO rt_msg.
      ENDIF.
      SELECT SINGLE ekorg FROM lfm1 WHERE lifnr = @ls_par-lifnr AND ekorg = @is_tech-ekorg INTO @DATA(lv_ekorg).
      IF sy-subrc <> 0.
        APPEND zcl_rpre_ib_shp_upload=>msg( iv_id = 'MH' iv_no = '003' iv_v1 = |{ ls_par-lifnr ALPHA = OUT }|
                                            iv_v2 = is_tech-ekorg ) TO rt_msg.
      ENDIF.
    ENDLOOP.
    DATA(lv_has_cr) = xsdbool( line_exists( is_tech-partners[ parvw = lv_cr ] ) ).
    DATA(lv_has_zd) = xsdbool( line_exists( is_tech-partners[ parvw = lv_zd ] ) ).
    DATA(lv_has_zi) = xsdbool( line_exists( is_tech-partners[ parvw = lv_zi ] ) ).
    IF lv_has_cr = abap_true AND ls_h-handling IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Handling 1 Fee' ) TO rt_msg.
    ELSEIF lv_has_cr = abap_false AND ls_h-handling IS NOT INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg055( `Handling 1 fee requires partner function CR` ) TO rt_msg.
    ENDIF.
    IF ls_h-admin_fee IS NOT INITIAL AND lv_has_zd = abap_false.
      APPEND zcl_rpre_ib_shp_upload=>msg055( `Admin fee requires partner function ZD` ) TO rt_msg.
    ENDIF.
    IF ls_h-insurance IS NOT INITIAL AND lv_has_zi = abap_false.
      APPEND zcl_rpre_ib_shp_upload=>msg055( `Insurance requires partner function ZI` ) TO rt_msg.
    ENDIF.
    IF ls_h-handling IS NOT INITIAL AND ls_h-curr_handling IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Handling Currency' ) TO rt_msg.
    ENDIF.
    IF ls_h-admin_fee IS NOT INITIAL AND ls_h-curr_admin IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '030' iv_v1 = 'Admin Fee Currency' ) TO rt_msg.
    ENDIF.
    LOOP AT VALUE string_table( ( CONV #( ls_h-curr_handling ) ) ( CONV #( ls_h-curr_admin ) )
                                ( CONV #( ls_h-curr_insur ) ) ) INTO DATA(lv_curr) WHERE table_line IS NOT INITIAL.
      SELECT SINGLE waers FROM tcurc WHERE waers = @lv_curr INTO @DATA(lv_waers).
      IF sy-subrc <> 0.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Currency { lv_curr } does not exist| ) TO rt_msg.
      ENDIF.
    ENDLOOP.
    IF ls_h-vsart IS NOT INITIAL.
      SELECT SINGLE vsart FROM t173 WHERE vsart = @ls_h-vsart INTO @DATA(lv_vsart).
      IF sy-subrc <> 0.
        APPEND zcl_rpre_ib_shp_upload=>msg055( `Invalid Shipment Type` ) TO rt_msg.
      ENDIF.
    ENDIF.
    IF is_tech-tplst IS INITIAL.
      APPEND zcl_rpre_ib_shp_upload=>msg055( |Mapping Company Code to Shipment Type for { is_tech-bukrs }| ) TO rt_msg.
    ENDIF.
    LOOP AT is_tech-items INTO DATA(ls_i) WHERE po-found_po = abap_true.
      IF ls_i-po-bukrs <> is_tech-bukrs OR ls_i-po-ekorg <> is_tech-ekorg.
        lv_diff_org = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_diff_org = abap_true.
      APPEND zcl_rpre_ib_shp_upload=>msg055( |POs of Tech No { is_tech-tech_no } belong to different company codes| )
        TO rt_msg.
    ENDIF.
    IF ls_h-pib_int_ind IS INITIAL AND ls_h-aju_no IS NOT INITIAL.
      SELECT SINGLE inbound_no FROM zrprt_pib_link
        WHERE aju_no = @ls_h-aju_no AND del_flag = @space
        INTO @DATA(lv_link_ib).
      IF sy-subrc = 0.
        APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '035' iv_v1 = |{ lv_link_ib ALPHA = OUT }| ) TO rt_msg.
      ENDIF.
    ENDIF.
    IF ls_h-lfdat IS NOT INITIAL AND ls_h-lfdat < sy-datum.
      APPEND zcl_rpre_ib_shp_upload=>msg055( iv_text = `Delivery date is in the past` iv_msgty = 'W' ) TO rt_msg.
    ENDIF.

    LOOP AT is_tech-items INTO ls_i.
      DATA(lv_ref) = |PO { ls_i-pib-po_doc ALPHA = OUT } item { ls_i-pib-po_item }|.
      IF ls_i-po-found_po = abap_false.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Purchase Order does not exist: { lv_ref }| ) TO rt_msg.
        CONTINUE.
      ENDIF.
      IF ls_i-po-found_item = abap_false.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |PO item does not exist: { lv_ref }| ) TO rt_msg.
        CONTINUE.
      ENDIF.
      IF ls_i-po-loekz IS NOT INITIAL.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |PO item is deleted: { lv_ref }| ) TO rt_msg.
      ENDIF.
      IF ls_i-po-elikz IS NOT INITIAL.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Delivery already completed: { lv_ref }| ) TO rt_msg.
      ENDIF.
      IF NOT ( ls_i-po-frgke = 'D' OR ls_i-po-frgrl IS INITIAL ).
        APPEND zcl_rpre_ib_shp_upload=>msg055( |PO Not Released: { lv_ref }| ) TO rt_msg.
      ENDIF.
      IF NOT ( ls_i-po-ekorg IN gr_ekorg AND ls_i-po-bstae IN gr_bstae AND ls_i-po-bsart IN gr_bsart ).
        APPEND zcl_rpre_ib_shp_upload=>msg055( |PO type or purchasing organisation not allowed: { lv_ref }| ) TO rt_msg.
      ENDIF.
      AUTHORITY-CHECK OBJECT 'ZP_INBDELV'
        ID 'BUKRS' FIELD ls_i-po-bukrs
        ID 'EKORG' FIELD ls_i-po-ekorg
        ID 'BSART' FIELD ls_i-po-bsart
        ID 'WERKS' FIELD ls_i-po-werks.
      IF sy-subrc <> 0.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |No authorisation for plant { ls_i-po-werks }| ) TO rt_msg.
      ENDIF.
      INSERT ls_i-po-werks INTO TABLE lt_werks.
      IF ls_i-pib-article_no <> ls_i-po-matnr.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Material does not match PO item: { lv_ref }| ) TO rt_msg.
      ENDIF.
      IF ls_i-po-mtart = zcl_rpre_ib_shp_upload=>c_asm_article.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Assembly item: { lv_ref }| ) TO rt_msg.
      ENDIF.
      IF ls_i-po-open_found = abap_false OR ls_i-po-open_qty IS INITIAL.
        APPEND zcl_rpre_ib_shp_upload=>msg055( |Has been posted in other inbound delivery: { lv_ref }| ) TO rt_msg.
      ELSE.
        IF ls_i-pib-uom <> ls_i-po-vrkme.
          APPEND zcl_rpre_ib_shp_upload=>msg055( |Unit does not match open quantity unit { ls_i-po-vrkme }: { lv_ref }| )
            TO rt_msg.
        ENDIF.
        IF ls_i-pib-qty > ls_i-po-open_qty.
          APPEND zcl_rpre_ib_shp_upload=>msg055( |Quantity exceeds open quantity: { lv_ref } open { ls_i-po-open_qty }| )
            TO rt_msg.
        ENDIF.
      ENDIF.
      IF ls_i-po-zuebpo IS NOT INITIAL.
        INSERT VALUE #( ebeln = ls_i-pib-po_doc zuebpo = ls_i-po-zuebpo ) INTO TABLE lt_set.
      ENDIF.

      DATA(lv_missing) = COND string(
        WHEN ls_i-pib-item_no IS INITIAL THEN `PIB Item`
        WHEN ls_i-pib-pib_art_desc IS INITIAL THEN `PIB Article Description`
        WHEN ls_i-pib-hs_code IS INITIAL THEN `HS Code`
        WHEN ls_i-pib-fob IS INITIAL THEN `FOB`
        WHEN ls_i-pib-uom IS INITIAL THEN `UoM`
        WHEN ls_i-pib-pckg IS INITIAL THEN `Package`
        WHEN ls_i-pib-cntry_of_origin IS INITIAL THEN `Country of Origin`
        WHEN ls_i-pib-bm_tariff_code IS INITIAL THEN `BM Tariff Code` ).
      IF lv_missing IS NOT INITIAL.
        APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '028' iv_v1 = lv_missing iv_v2 = ls_i-pib-inbound_item_no ) TO rt_msg.
      ENDIF.
      IF ls_i-pib-pckg IS NOT INITIAL.
        SELECT SINGLE msehi FROM t006a WHERE msehi = @ls_i-pib-pckg INTO @DATA(lv_msehi).
        IF sy-subrc <> 0.
          APPEND zcl_rpre_ib_shp_upload=>msg055( |Package unit { ls_i-pib-pckg } does not exist| ) TO rt_msg.
        ENDIF.
      ENDIF.
      IF ls_i-pib-cntry_of_origin IS NOT INITIAL.
        SELECT SINGLE land1 FROM t005t WHERE land1 = @ls_i-pib-cntry_of_origin INTO @DATA(lv_land1).
        IF sy-subrc <> 0.
          APPEND zcl_rpre_ib_shp_upload=>msg055( |Country { ls_i-pib-cntry_of_origin } does not exist| ) TO rt_msg.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF lines( lt_werks ) > 1.
      APPEND zcl_rpre_ib_shp_upload=>msg055( |Tech No { is_tech-tech_no } has several plants| ) TO rt_msg.
    ENDIF.

    IF lt_set IS NOT INITIAL.
      SELECT ebeln, ebelp, zuebpo FROM ekpo FOR ALL ENTRIES IN @lt_set
        WHERE ebeln = @lt_set-ebeln AND zuebpo = @lt_set-zuebpo
        INTO TABLE @DATA(lt_set_items).
      LOOP AT lt_set INTO DATA(ls_set).
        LOOP AT lt_set_items INTO DATA(ls_set_item) WHERE ebeln = ls_set-ebeln AND zuebpo = ls_set-zuebpo.
          IF NOT line_exists( is_tech-items[ pib-po_doc = ls_set_item-ebeln pib-po_item = ls_set_item-ebelp ] ).
            APPEND zcl_rpre_ib_shp_upload=>msg055(
              |Unit Article for PO { ls_set-ebeln ALPHA = OUT } item number { ls_set-zuebpo } should all be included| )
              TO rt_msg.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.

    DATA(lt_same) = VALUE string_table( ( `BM` ) ( `PPNBM` ) ( `TOTAL_PCKG` ) ( `BM_FACILITY_CODE` ) ( `BM_FACILITY_RATE` )
      ( `CUSTOM_FACILITY_CODE` ) ( `CUSTOM_FACILITY_RATE` ) ( `PPN_FACILITY_CODE` ) ( `PPN_FACILITY_RATE` )
      ( `PPH_FACILITY_CODE` ) ( `PPH_FACILITY_RATE` ) ( `PPNBM_FACILITY_CODE` ) ( `PPNBM_FACILITY_RATE` ) ).
    DATA(lt_label) = VALUE string_table( ( `BM Percentage` ) ( `PPNBM Percentage` ) ( `Total Package` )
      ( `BM Facility Code` ) ( `BM Facility Rate` ) ( `Custom Facility Code` ) ( `Custom Facility Rate` )
      ( `PPN Facility Code` ) ( `PPN Facility Rate` ) ( `PPH Facility Code` ) ( `PPH Facility Rate` )
      ( `PPNBM Facility Code` ) ( `PPNBM Facility Rate` ) ).
    DATA(lv_count) = lines( is_tech-items ).
    DO lv_count TIMES.
      DATA(lv_a) = sy-index.
      DATA(ls_ia) = is_tech-items[ lv_a ].
      DATA(lv_b) = lv_a + 1.
      WHILE lv_b <= lv_count.
        DATA(ls_ib) = is_tech-items[ lv_b ].
        IF ls_ia-pib-item_no = ls_ib-pib-item_no AND ls_ia-pib-item_no IS NOT INITIAL.
          IF ls_ia-pib-article_no <> ls_ib-pib-article_no.
            APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '029' iv_v1 = ls_ib-pib-item_no ) TO rt_msg.
          ELSE.
            LOOP AT lt_same INTO DATA(lv_fld).
              DATA(lv_fidx) = sy-tabix.
              ASSIGN COMPONENT lv_fld OF STRUCTURE ls_ia-pib TO <lv_a>.
              ASSIGN COMPONENT lv_fld OF STRUCTURE ls_ib-pib TO <lv_b>.
              IF <lv_a> <> <lv_b>.
                APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '061' iv_v1 = lt_label[ lv_fidx ]
                                                    iv_v2 = ls_ia-pib-inbound_item_no
                                                    iv_v3 = ls_ib-pib-inbound_item_no ) TO rt_msg.
                EXIT.
              ENDIF.
            ENDLOOP.
            IF ls_ia-pib-po_doc <> ls_ib-pib-po_doc.
              APPEND zcl_rpre_ib_shp_upload=>msg055( iv_text = |Same PIB item { ls_ib-pib-item_no } with different PO|
                                                     iv_msgty = 'W' ) TO rt_msg.
            ENDIF.
          ENDIF.
        ENDIF.
        IF ls_ia-pib-article_no = ls_ib-pib-article_no AND ls_ia-pib-pib_art_desc <> ls_ib-pib-pib_art_desc.
          APPEND zcl_rpre_ib_shp_upload=>msg( iv_no = '058' iv_v1 = |{ ls_ia-pib-article_no ALPHA = OUT }|
                                              iv_v2 = ls_ia-pib-inbound_item_no
                                              iv_v3 = ls_ib-pib-inbound_item_no ) TO rt_msg.
        ENDIF.
        lv_b = lv_b + 1.
      ENDWHILE.
    ENDDO.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_post DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES ty_t_bdc TYPE STANDARD TABLE OF bdcdata WITH EMPTY KEY.
    TYPES ty_t_mess TYPE STANDARD TABLE OF bdcmsgcoll WITH EMPTY KEY.
    TYPES ty_t_uplhdr TYPE STANDARD TABLE OF zrprt_pib_uplhdr WITH EMPTY KEY.
    CLASS-METHODS hold_document
      IMPORTING is_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
      CHANGING  cv_docnr      TYPE zde_vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS upl_header
      IMPORTING is_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
                iv_docnr      TYPE zde_vbeln_vl
      RETURNING VALUE(rt_hdr) TYPE ty_t_uplhdr.
    CLASS-METHODS inbound_delivery
      EXPORTING ev_vbeln      TYPE vbeln_vl
                ev_split      TYPE abap_bool
      CHANGING  cs_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS pib_data
      IMPORTING is_tech       TYPE zcl_rpre_ib_shp_upload=>ty_s_tech
                iv_docnr      TYPE zde_vbeln_vl
                iv_vbeln      TYPE vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS i007
      IMPORTING iv_vbeln      TYPE vbeln_vl
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS shipment
      IMPORTING iv_vbeln      TYPE vbeln_vl
                is_cost_input TYPE zcl_rpre_ib_shp_upload=>ty_s_cost_input
      EXPORTING ev_tknum      TYPE tknum
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS shipment_partners
      IMPORTING iv_tknum      TYPE tknum
                is_cost_input TYPE zcl_rpre_ib_shp_upload=>ty_s_cost_input
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS shipment_cost
      IMPORTING iv_vbeln      TYPE vbeln_vl
                iv_tknum      TYPE tknum
                is_cost_input TYPE zcl_rpre_ib_shp_upload=>ty_s_cost_input
                iv_fknum      TYPE fknum OPTIONAL
      EXPORTING ev_fknum      TYPE fknum
      RETURNING VALUE(rv_msg) TYPE string.
    CLASS-METHODS cost_input
      IMPORTING iv_vbeln       TYPE vbeln_vl
      RETURNING VALUE(rs_cost) TYPE zcl_rpre_ib_shp_upload=>ty_s_cost_input.
  PRIVATE SECTION.
    CLASS-METHODS dynpro
      IMPORTING iv_prog   TYPE csequence
                iv_dynpro TYPE csequence
      CHANGING  ct_bdc    TYPE ty_t_bdc.
    CLASS-METHODS field
      IMPORTING iv_fnam TYPE csequence
                iv_fval TYPE simple
      CHANGING  ct_bdc  TYPE ty_t_bdc.
    CLASS-METHODS run_bdc
      IMPORTING iv_tcode       TYPE sytcode
                it_bdc         TYPE ty_t_bdc
                iv_defsize     TYPE abap_bool
      RETURNING VALUE(rt_mess) TYPE ty_t_mess.
    CLASS-METHODS bdc_text
      IMPORTING it_mess        TYPE ty_t_mess
                iv_tcode       TYPE sytcode
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS cost_value_bdc
      IMPORTING iv_idx   TYPE i
                it_split TYPE zcl_rpre_ib_shp_upload=>ty_t_split
                iv_lines TYPE i
                iv_curr  TYPE waers
      CHANGING  ct_bdc   TYPE ty_t_bdc.
    CLASS-METHODS curr_value_bdc
      IMPORTING iv_idx  TYPE i
                iv_curr TYPE waers
      CHANGING  ct_bdc  TYPE ty_t_bdc.
ENDCLASS.


CLASS lcl_post IMPLEMENTATION.

  METHOD upl_header.
    " mirrors ZVL31N forms F_SAVE_TO_DB (header part) and F_ASSIGN_HEADER_DATA
    DATA(ls_h) = is_tech-hdr.
    DATA(ls_base) = VALUE zrprt_pib_uplhdr(
      inbound_no = iv_docnr aju_no = ls_h-aju_no aju_date = ls_h-aju_date pricing_date = ls_h-pricing_date
      handling = ls_h-handling admin_fee = ls_h-admin_fee curr_handling = ls_h-curr_handling
      curr_admin = ls_h-curr_admin bill_of_ladding = ls_h-bolnr ship_type = ls_h-vsart
      pib_int_ind = ls_h-pib_int_ind no_shcost_ind = space create_by = sy-uname create_on = sy-datum
      insurance = ls_h-insurance curr_insur = ls_h-curr_insur etd_load_port = ls_h-etd_load_port
      eta_dst_port = ls_h-eta_dst_port eta_wh = ls_h-lfdat ship_doc_date = ls_h-ship_doc_date ).
    LOOP AT is_tech-partners INTO DATA(ls_par) WHERE lifnr IS NOT INITIAL AND parvw IS NOT INITIAL.
      DATA(ls_row) = ls_base.
      ls_row-line_no = sy-tabix.
      ls_row-partner = ls_par-lifnr.
      ls_row-partner_func = ls_par-parvw.
      ls_row-partner_name = ls_par-name1.
      ls_row-partner_street = ls_par-stras.
      ls_row-partner_post_code1 = ls_par-pstlz.
      ls_row-partner_city = ls_par-ort01.
      APPEND ls_row TO rt_hdr.
    ENDLOOP.
    IF rt_hdr IS INITIAL.
      ls_base-line_no = 1.
      APPEND ls_base TO rt_hdr.
    ENDIF.
  ENDMETHOD.


  METHOD hold_document.
    " mirrors ZVL31N forms F_HOLD_DOCUMENT and F_SAVE_TO_DB
    DATA lt_itm TYPE STANDARD TABLE OF zrprt_pib_uplitm WITH EMPTY KEY.
    CLEAR rv_msg.
    IF cv_docnr IS INITIAL.
      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING  nr_range_nr   = '01'
                   object        = 'Z_CUST_IB'
                   ignore_buffer = abap_true
        IMPORTING  number        = cv_docnr
        EXCEPTIONS OTHERS        = 8.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO rv_msg.
        RETURN.
      ENDIF.
      IF cv_docnr IS INITIAL.
        rv_msg = `Number range has not been maintained`.
        RETURN.
      ENDIF.
    ELSE.
      DELETE FROM zrprt_pib_uplhdr WHERE inbound_no = @cv_docnr.
      DELETE FROM zrprt_pib_uplitm WHERE inbound_no = @cv_docnr.
    ENDIF.
    DATA(lt_hdr) = upl_header( is_tech = is_tech iv_docnr = cv_docnr ).
    LOOP AT is_tech-items INTO DATA(ls_item).
      APPEND CORRESPONDING zrprt_pib_uplitm( ls_item-pib ) TO lt_itm ASSIGNING FIELD-SYMBOL(<ls_itm>).
      <ls_itm>-inbound_no = cv_docnr.
      <ls_itm>-po_parent = ls_item-po-zuebpo.
    ENDLOOP.
    TRY.
        INSERT zrprt_pib_uplhdr FROM TABLE @lt_hdr.
        IF sy-subrc <> 0.
          MESSAGE e322(/osp/msg) WITH 'PIB Custom Upload Header.' INTO rv_msg.
          RETURN.
        ENDIF.
        INSERT zrprt_pib_uplitm FROM TABLE @lt_itm.
        IF sy-subrc <> 0.
          MESSAGE e322(/osp/msg) WITH 'PIB Custom Upload Item.' INTO rv_msg.
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        rv_msg = lx_sql->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD inbound_delivery.
    " mirrors ZVL31N form F_CREATE_IB_VIA_BAPI and form INB_DELIVERY_CREATE of ZBBP_INB_DELIVERY_CREATE
    " (LZBBP_SIC_40F02); a split is returned as an error instead of a popup
    DATA lt_kom TYPE STANDARD TABLE OF komdlgn.
    DATA ls_kom TYPE komdlgn.
    DATA lt_prop TYPE STANDARD TABLE OF wuebs.
    DATA ls_vbsk TYPE vbsk.
    DATA ls_tvsa TYPE tvsa.
    DATA lt_vbfs TYPE STANDARD TABLE OF vbfs.
    DATA lt_vbls TYPE STANDARD TABLE OF vbls.
    DATA lt_lips TYPE STANDARD TABLE OF lips.
    DATA lt_po TYPE SORTED TABLE OF ebeln WITH UNIQUE KEY table_line.
    DATA lv_text TYPE string.

    CLEAR: ev_vbeln, ev_split, rv_msg.
    ls_kom-lfdat = cs_tech-hdr-lfdat.
    ls_kom-lfuhr = sy-uzeit.
    ls_kom-bolnr = cs_tech-hdr-bolnr.
    DATA(lt_all) = cs_tech-parents.
    APPEND LINES OF cs_tech-items TO lt_all.
    LOOP AT lt_all INTO DATA(ls_item).
      ls_kom-matnr = ls_item-pib-article_no.
      ls_kom-ematn = ls_item-pib-article_no.
      ls_kom-lfimg = ls_item-pib-qty.
      ls_kom-vrkme = ls_item-pib-uom.
      ls_kom-meins = ls_item-pib-uom.
      ls_kom-vgbel = ls_item-pib-po_doc.
      ls_kom-vgpos = ls_item-pib-po_item.
      APPEND ls_kom TO lt_kom.
      INSERT ls_item-pib-po_doc INTO TABLE lt_po.
    ENDLOOP.

    CALL FUNCTION 'ME_CONFIRMATION_VIA_EDI'
      TABLES     t_kom  = lt_kom
                 errors = lt_prop
      EXCEPTIONS OTHERS = 1.
    LOOP AT lt_kom ASSIGNING FIELD-SYMBOL(<ls_kom>).
      <ls_kom>-vgtyp = 'V'.
      <ls_kom>-kzazu = abap_true.
      IF <ls_kom>-lfart IS INITIAL.
        <ls_kom>-lfart = 'EL'.
      ENDIF.
    ENDLOOP.

    ls_vbsk-mandt = sy-mandt.
    ls_vbsk-ernam = sy-uname.
    ls_vbsk-erdat = sy-datum.
    ls_vbsk-uzeit = sy-uzeit.
    ls_vbsk-smart = 'L'.
    SELECT SINGLE * FROM tvsa WHERE smart = @ls_vbsk-smart INTO @ls_tvsa.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING  nr_range_nr = ls_tvsa-numki
                 object      = 'RV_SAMMG'
      IMPORTING  number      = ls_vbsk-sammg
      EXCEPTIONS OTHERS      = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO rv_msg.
      RETURN.
    ENDIF.

    " Simulation without commit to detect a split or errors
    CALL FUNCTION 'GN_DELIVERY_CREATE'
      EXPORTING  vbsk_i    = ls_vbsk
                 no_commit = abap_true
      IMPORTING  vbsk_e    = ls_vbsk
      TABLES     xkomdlgn  = lt_kom
                 xvbfs     = lt_vbfs
                 xvbls     = lt_vbls
      EXCEPTIONS OTHERS    = 1.
    IF sy-subrc = 0.
      ROLLBACK WORK.
      LOOP AT lt_po INTO DATA(lv_po).
        IF NOT line_exists( lt_vbls[ vbeln = lv_po ] ).
          lv_text = |{ lv_text } { lv_po ALPHA = OUT }|.
        ENDIF.
      ENDLOOP.
      IF lv_text IS NOT INITIAL.
        rv_msg = |{ condense( lv_text ) } is currently being processed|.
        RETURN.
      ENDIF.
      DATA(lt_dlv) = lt_vbls.
      SORT lt_dlv BY vbeln_lif.
      DELETE ADJACENT DUPLICATES FROM lt_dlv COMPARING vbeln_lif.
      IF lines( lt_dlv ) > 1.
        ev_split = abap_true.
        DATA(lt_split) = lt_vbls.
        SORT lt_split BY vbeln_lif vbeln.
        DELETE ADJACENT DUPLICATES FROM lt_split COMPARING vbeln_lif vbeln.
        CLEAR lv_text.
        LOOP AT lt_dlv INTO DATA(ls_dlv).
          DATA(lv_count) = sy-tabix.
          lv_text = |{ lv_text } Delivery { lv_count }:|.
          LOOP AT lt_split INTO DATA(ls_split) WHERE vbeln_lif = ls_dlv-vbeln_lif.
            lv_text = |{ lv_text } { ls_split-vbeln ALPHA = OUT }|.
          ENDLOOP.
        ENDLOOP.
        rv_msg = |Inbound delivery would be split.{ lv_text }|.
        RETURN.
      ENDIF.
      LOOP AT lt_vbfs INTO DATA(ls_vbfs) WHERE msgty = 'E'.
        MESSAGE ID ls_vbfs-msgid TYPE 'E' NUMBER ls_vbfs-msgno
          WITH ls_vbfs-msgv1 ls_vbfs-msgv2 ls_vbfs-msgv3 ls_vbfs-msgv4 INTO DATA(lv_vbfs_text).
        rv_msg = COND #( WHEN rv_msg IS INITIAL THEN lv_vbfs_text ELSE |{ rv_msg }. { lv_vbfs_text }| ).
      ENDLOOP.
      IF rv_msg IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    " Real create; no_commit so the caller commits delivery, PIB data and log in one LUW
    CLEAR: lt_vbfs, lt_vbls, lt_lips.
    CALL FUNCTION 'GN_DELIVERY_CREATE'
      EXPORTING  vbsk_i    = ls_vbsk
                 no_commit = abap_true
      IMPORTING  vbsk_e    = ls_vbsk
      TABLES     xkomdlgn  = lt_kom
                 xvbfs     = lt_vbfs
                 xvbls     = lt_vbls
                 xxlips    = lt_lips
      EXCEPTIONS OTHERS    = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO rv_msg.
      RETURN.
    ENDIF.
    IF ls_vbsk-ernum = 0 AND ls_vbsk-vbnum > 0 AND lt_vbls IS NOT INITIAL.
      ev_vbeln = lt_vbls[ 1 ]-vbeln_lif.
    ELSE.
      LOOP AT lt_vbfs INTO ls_vbfs WHERE msgty = 'E' OR msgty = 'A'.
        MESSAGE ID ls_vbfs-msgid TYPE 'E' NUMBER ls_vbfs-msgno
          WITH ls_vbfs-msgv1 ls_vbfs-msgv2 ls_vbfs-msgv3 ls_vbfs-msgv4 INTO lv_vbfs_text.
        rv_msg = COND #( WHEN rv_msg IS INITIAL THEN lv_vbfs_text ELSE |{ rv_msg }. { lv_vbfs_text }| ).
      ENDLOOP.
      IF rv_msg IS INITIAL.
        rv_msg = `Inbound delivery was not created`.
      ENDIF.
      RETURN.
    ENDIF.
    " Take the item numbers the delivery really got
    LOOP AT cs_tech-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      READ TABLE lt_lips INTO DATA(ls_lips) WITH KEY vgbel = <ls_item>-pib-po_doc vgpos = <ls_item>-pib-po_item.
      IF sy-subrc = 0.
        <ls_item>-pib-inbound_item_no = ls_lips-posnr.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD pib_data.
    " mirrors ZVL31N forms F_SAVE_PIB_HDR_DATA, F_SAVE_PIB_ITM_DATA, F_SAVE_PIB_LINK_DATA, F_SAVE_CUSTOM_IB_LINK
    DATA lt_hdr TYPE STANDARD TABLE OF zrprt_pib_header WITH EMPTY KEY.
    DATA lt_itm TYPE STANDARD TABLE OF zrprt_pib_item WITH EMPTY KEY.
    DATA ls_link TYPE zrprt_pib_link.
    CLEAR rv_msg.
    LOOP AT upl_header( is_tech = is_tech iv_docnr = iv_docnr ) INTO DATA(ls_upl).
      APPEND CORRESPONDING zrprt_pib_header( ls_upl ) TO lt_hdr ASSIGNING FIELD-SYMBOL(<ls_hdr>).
      <ls_hdr>-inbound_no = iv_vbeln.
      <ls_hdr>-changed_on = sy-datum.
    ENDLOOP.
    LOOP AT is_tech-items INTO DATA(ls_item).
      DATA(ls_itm) = ls_item-pib.
      ls_itm-inbound_no = iv_vbeln.
      ls_itm-changed_on = sy-datum.
      APPEND ls_itm TO lt_itm.
    ENDLOOP.
    ls_link-inbound_no = iv_vbeln.
    ls_link-aju_no = is_tech-hdr-aju_no.
    ls_link-status = '0'.
    TRY.
        INSERT zrprt_pib_header FROM TABLE @lt_hdr.
        IF sy-subrc <> 0.
          MESSAGE e322(/osp/msg) WITH 'PIB Custom Header.' INTO rv_msg.
          RETURN.
        ENDIF.
        INSERT zrprt_pib_item FROM TABLE @lt_itm.
        IF sy-subrc <> 0.
          MESSAGE e322(/osp/msg) WITH 'PIB Custom Item.' INTO rv_msg.
          RETURN.
        ENDIF.
        INSERT zrprt_pib_link FROM @ls_link.
        IF sy-subrc <> 0.
          MESSAGE e322(/osp/msg) WITH 'PIB Custom Link.' INTO rv_msg.
          RETURN.
        ENDIF.
        UPDATE zrprt_pib_uplhdr SET ib_link_no = @iv_vbeln WHERE inbound_no = @iv_docnr.
        IF sy-subrc <> 0.
          MESSAGE e003(/ipro/dbmc) WITH 'PIB Custom Upload Header.' INTO rv_msg.
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        rv_msg = lx_sql->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD i007.
    " mirrors ZVL31N form F_GENERATE_SEND_REDPANDA
    DATA lo_interface TYPE REF TO zcl_intf_base.
    DATA lt_param TYPE STANDARD TABLE OF zintf_param.
    DATA lv_objid TYPE zde_ifobjid.
    DATA lv_sloc_inc TYPE char200.
    DATA lv_sloc_exc TYPE char200.
    DATA lv_pcat_inc TYPE char200.
    DATA lv_pcat_exc TYPE char200.
    DATA lv_flag TYPE abap_bool.

    CLEAR rv_msg.
    lv_objid = iv_vbeln.
    SELECT SINGLE vbeln, werks, vbtyp FROM likp WHERE vbeln = @iv_vbeln INTO @DATA(ls_likp).
    IF sy-subrc = 0.
      SELECT vbeln, posnr, werks, lgort FROM lips WHERE vbeln = @iv_vbeln INTO TABLE @DATA(lt_lips).
      IF lt_lips IS NOT INITIAL.
        SELECT bwkey, bukrs FROM t001k FOR ALL ENTRIES IN @lt_lips WHERE bwkey = @lt_lips-werks
          INTO TABLE @DATA(lt_t001k).
        IF sy-subrc = 0.
          SELECT * FROM zintf_param FOR ALL ENTRIES IN @lt_t001k
            WHERE if_id = 'I007' AND bukrs = @lt_t001k-bukrs AND start_date <= @sy-datum
            INTO TABLE @lt_param.
          LOOP AT lt_param INTO DATA(ls_param).
            lv_sloc_inc = ls_param-field_inc1.
            lv_sloc_exc = ls_param-field_exc1.
            lv_pcat_inc = ls_param-field_inc2.
            lv_pcat_exc = ls_param-field_exc2.
            IF lv_pcat_inc CS ls_likp-vbtyp OR lv_pcat_exc NS ls_likp-vbtyp.
              LOOP AT lt_lips INTO DATA(ls_lips).
                IF ls_lips-werks CP ls_param-werks.
                  IF lv_sloc_inc CS ls_lips-lgort OR lv_sloc_exc NS ls_lips-lgort.
                    lv_flag = abap_true.
                    EXIT.
                  ENDIF.
                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
    IF lv_flag = abap_false.
      rv_msg = `I007 not sent: delivery not in scope of ZINTF_PARAM`.
      RETURN.
    ENDIF.
    CALL METHOD zcl_intf_factory=>factory
      EXPORTING  if_id                   = 'I007'
                 if_guid                 = space
                 if_objid                = lv_objid
      RECEIVING  o_interface             = lo_interface
      EXCEPTIONS inactive_interface      = 1
                 interface_not_found     = 2
                 handler_class_not_found = 3
                 OTHERS                  = 4.
    IF sy-subrc <> 0.
      rv_msg = |I007 not sent: interface factory error { sy-subrc }|.
      RETURN.
    ENDIF.
    TRY.
        lo_interface->zif_interface~execute( ).
        COMMIT WORK AND WAIT.
      CATCH cx_root INTO DATA(lx_root).
        rv_msg = |I007 not sent: { lx_root->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD cost_input.
    SELECT * FROM zrprt_pib_header WHERE inbound_no = @iv_vbeln ORDER BY line_no INTO TABLE @DATA(lt_hdr).
    IF lt_hdr IS NOT INITIAL.
      DATA(ls_hdr) = lt_hdr[ 1 ].
      rs_cost-aju_no = ls_hdr-aju_no.
      rs_cost-pricing_date = ls_hdr-pricing_date.
      rs_cost-handling = ls_hdr-handling.
      rs_cost-curr_handling = ls_hdr-curr_handling.
      rs_cost-admin_fee = ls_hdr-admin_fee.
      rs_cost-curr_admin = ls_hdr-curr_admin.
      rs_cost-insurance = ls_hdr-insurance.
      rs_cost-curr_insur = ls_hdr-curr_insur.
      LOOP AT lt_hdr INTO ls_hdr WHERE partner IS NOT INITIAL AND partner_func IS NOT INITIAL.
        APPEND VALUE #( parvw = ls_hdr-partner_func lifnr = ls_hdr-partner ) TO rs_cost-partners.
      ENDLOOP.
    ENDIF.
    SELECT inbound_item_no, fob, po_doc FROM zrprt_pib_item WHERE inbound_no = @iv_vbeln
      ORDER BY inbound_item_no INTO TABLE @DATA(lt_itm).
    rs_cost-items = CORRESPONDING #( lt_itm ).
    IF lt_itm IS NOT INITIAL.
      SELECT SINGLE bukrs, waers FROM ekko WHERE ebeln = @( lt_itm[ 1 ]-po_doc ) INTO @DATA(ls_ekko).
      rs_cost-bukrs = ls_ekko-bukrs.
      rs_cost-waers = ls_ekko-waers.
      lcl_check=>load_e014( ).
      READ TABLE lcl_check=>gt_bukrs2tplst INTO DATA(ls_map) WITH TABLE KEY bukrs = rs_cost-bukrs.
      IF sy-subrc = 0.
        rs_cost-tplst = ls_map-tplst.
        rs_cost-shtyp = ls_map-shtyp.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD shipment.
    " mirrors ZVL31N form F_CREATE_SHIPMENT_DOC (BAPI part)
    DATA ls_hdr TYPE bapishipmentheader.
    DATA lt_itm TYPE STANDARD TABLE OF bapishipmentitem.
    DATA lt_ret TYPE STANDARD TABLE OF bapiret2.
    DATA lv_tknum TYPE bapishipmentids-shipmentnum.

    CLEAR: ev_tknum, rv_msg.
    ls_hdr-shipment_type = is_cost_input-shtyp.
    ls_hdr-trans_plan_pt = is_cost_input-tplst.
    ls_hdr-external_id_1 = is_cost_input-aju_no+20(6).
    ls_hdr-status_plan = abap_true.
    DATA(lv_cr) = lcl_check=>parvw_in( 'CR' ).
    READ TABLE is_cost_input-partners INTO DATA(ls_par) WITH KEY parvw = lv_cr.
    IF sy-subrc = 0.
      ls_hdr-service_agent_id = ls_par-lifnr.
    ENDIF.
    APPEND VALUE #( delivery = iv_vbeln ) TO lt_itm.
    CALL FUNCTION 'BAPI_SHIPMENT_CREATE'
      EXPORTING headerdata = ls_hdr
      IMPORTING transport  = lv_tknum
      TABLES    itemdata   = lt_itm
                return     = lt_ret.
    IF line_exists( lt_ret[ type = 'E' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      LOOP AT lt_ret INTO DATA(ls_ret) WHERE type = 'E'.
        rv_msg = COND #( WHEN rv_msg IS INITIAL THEN ls_ret-message ELSE |{ rv_msg }. { ls_ret-message }| ).
      ENDLOOP.
      RETURN.
    ENDIF.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = abap_true.
    ev_tknum = lv_tknum.
  ENDMETHOD.


  METHOD shipment_partners.
    " mirrors ZVL31N form F_CREATE_SHIPMENT_DOC (VT02 partner BDC); only partners missing in VTPA are added
    DATA lt_bdc TYPE ty_t_bdc.
    DATA lv_idx TYPE numc2.

    CLEAR rv_msg.
    SELECT parvw FROM vtpa WHERE vbeln = @iv_tknum AND posnr = '000000' INTO TABLE @DATA(lt_vtpa).
    DATA(lv_cr) = lcl_check=>parvw_in( 'CR' ).
    DATA(lt_add) = is_cost_input-partners.
    DELETE lt_add WHERE parvw = lv_cr.
    LOOP AT lt_vtpa INTO DATA(ls_vtpa).
      DELETE lt_add WHERE parvw = ls_vtpa-parvw.
    ENDLOOP.
    IF lt_add IS INITIAL.
      RETURN.
    ENDIF.

    dynpro( EXPORTING iv_prog = 'SAPMV56A' iv_dynpro = '0011' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=UETP' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'VTTK-TKNUM' iv_fval = iv_tknum CHANGING ct_bdc = lt_bdc ).
    dynpro( EXPORTING iv_prog = 'SAPMSSY0' iv_dynpro = '0120' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=TKPA' CHANGING ct_bdc = lt_bdc ).
    lv_idx = lines( lt_vtpa ) + 1.
    LOOP AT lt_add INTO DATA(ls_add).
      dynpro( EXPORTING iv_prog = 'SAPDV02P' iv_dynpro = '0624' CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '/00' CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = |VBPA-PARVW({ lv_idx })| iv_fval = ls_add-parvw CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = |RV02P-KUNDE({ lv_idx })| iv_fval = ls_add-lifnr CHANGING ct_bdc = lt_bdc ).
      lv_idx = lv_idx + 1.
    ENDLOOP.
    dynpro( EXPORTING iv_prog = 'SAPDV02P' iv_dynpro = '0624' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '/EBACK' CHANGING ct_bdc = lt_bdc ).
    dynpro( EXPORTING iv_prog = 'SAPMSSY0' iv_dynpro = '0120' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=SICH' CHANGING ct_bdc = lt_bdc ).

    DATA(lt_mess) = run_bdc( iv_tcode = 'VT02' it_bdc = lt_bdc iv_defsize = abap_false ).
    IF NOT line_exists( lt_mess[ msgtyp = 'S' msgid = 'VW' msgnr = '006' ] ).
      rv_msg = bdc_text( it_mess = lt_mess iv_tcode = 'VT02' ).
    ENDIF.
  ENDMETHOD.


  METHOD shipment_cost.
    " mirrors ZVL31N forms F_CREATE_SHIPCOST_DOC and F_BDC_TRANSACTION_DEFSIZE (include _SHCOS)
    DATA lt_bdc TYPE ty_t_bdc.
    DATA lv_date TYPE char10.
    DATA lv_fknum TYPE fknum.

    DATA lt_mess TYPE ty_t_mess.

    CLEAR: ev_fknum, rv_msg.
    IF iv_fknum IS NOT INITIAL.
      " Restart: the shipment cost document exists (VI01 done earlier), redo only the VI02 cost
      " distribution. VI02 sets the condition values, so repeating it gives the same result.
      ev_fknum = iv_fknum.
    ELSE.
      WRITE is_cost_input-pricing_date TO lv_date DD/MM/YYYY.
      dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0010' CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'VTTK-TKNUM' iv_fval = iv_tknum CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'RV54A-FKART' iv_fval = is_cost_input-tplst CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'VFKK-PRSDT' iv_fval = lv_date CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=UEBP' CHANGING ct_bdc = lt_bdc ).
      dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0030' CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=HREF' CHANGING ct_bdc = lt_bdc ).
      dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0030' CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'VFKK-EXTI1' iv_fval = is_cost_input-aju_no+20(6) CHANGING ct_bdc = lt_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=SICH' CHANGING ct_bdc = lt_bdc ).
      lt_mess = run_bdc( iv_tcode = 'VI01' it_bdc = lt_bdc iv_defsize = abap_false ).
      READ TABLE lt_mess INTO DATA(ls_mess) WITH KEY msgtyp = 'S' msgid = 'VY' msgnr = '007'.
      IF sy-subrc <> 0.
        rv_msg = bdc_text( it_mess = lt_mess iv_tcode = 'VI01' ).
        RETURN.
      ENDIF.
      lv_fknum = condense( ls_mess-msgv1 ).
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = lv_fknum
        IMPORTING output = ev_fknum.
    ENDIF.

    SELECT posnr, mtart FROM lips WHERE vbeln = @iv_vbeln ORDER BY posnr INTO TABLE @DATA(lt_lips_db).
    DATA(lt_lips) = CORRESPONDING zcl_rpre_ib_shp_upload=>ty_t_lips( lt_lips_db ).
    DATA(lv_total) = REDUCE scprcurr( INIT t = CONV scprcurr( 0 ) FOR i IN is_cost_input-items NEXT t = t + i-fob ).
    SELECT fknum, fkpos, fkpty FROM vfkp WHERE fknum = @ev_fknum ORDER BY fkpos INTO TABLE @DATA(lt_vfkp).
    DATA(lv_idx1) = line_index( lt_vfkp[ fkpty = '0001' ] ).
    DATA(lv_idx2) = line_index( lt_vfkp[ fkpty = '0002' ] ).
    DATA(lv_idx5) = line_index( lt_vfkp[ fkpty = '0005' ] ).
    DATA(lv_idx6) = line_index( lt_vfkp[ fkpty = '0006' ] ).
    IF lv_idx1 <= 0 AND lv_idx2 <= 0 AND lv_idx5 <= 0 AND lv_idx6 <= 0.
      RETURN.
    ENDIF.

    CLEAR lt_bdc.
    DATA(lv_lines) = lines( lt_lips ).
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0020' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'VFKK-FKNUM' iv_fval = ev_fknum CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=UEBP' CHANGING ct_bdc = lt_bdc ).
    IF lv_idx1 > 0.
      curr_value_bdc( EXPORTING iv_idx = lv_idx1 iv_curr = is_cost_input-waers CHANGING ct_bdc = lt_bdc ).
    ENDIF.
    IF lv_idx2 > 0.
      IF is_cost_input-insurance IS INITIAL.
        curr_value_bdc( EXPORTING iv_idx = lv_idx2 iv_curr = is_cost_input-waers CHANGING ct_bdc = lt_bdc ).
      ELSE.
        cost_value_bdc( EXPORTING iv_idx = lv_idx2 iv_lines = lv_lines iv_curr = is_cost_input-curr_insur
                                  it_split = zcl_rpre_ib_shp_upload=>split_cost( it_lips = lt_lips
                                    it_items = is_cost_input-items iv_total = lv_total
                                    iv_value = CONV #( is_cost_input-insurance ) )
                        CHANGING ct_bdc = lt_bdc ).
      ENDIF.
    ENDIF.
    IF lv_idx5 > 0.
      cost_value_bdc( EXPORTING iv_idx = lv_idx5 iv_lines = lv_lines iv_curr = is_cost_input-curr_handling
                                it_split = zcl_rpre_ib_shp_upload=>split_cost( it_lips = lt_lips
                                  it_items = is_cost_input-items iv_total = lv_total
                                  iv_value = CONV #( is_cost_input-handling ) )
                      CHANGING ct_bdc = lt_bdc ).
    ENDIF.
    IF lv_idx6 > 0.
      cost_value_bdc( EXPORTING iv_idx = lv_idx6 iv_lines = lv_lines iv_curr = is_cost_input-curr_admin
                                it_split = zcl_rpre_ib_shp_upload=>split_cost( it_lips = lt_lips
                                  it_items = is_cost_input-items iv_total = lv_total
                                  iv_value = CONV #( is_cost_input-admin_fee ) )
                      CHANGING ct_bdc = lt_bdc ).
    ENDIF.
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0030' CHANGING ct_bdc = lt_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=SICH' CHANGING ct_bdc = lt_bdc ).
    lt_mess = run_bdc( iv_tcode = 'VI02' it_bdc = lt_bdc iv_defsize = abap_true ).
    IF NOT line_exists( lt_mess[ msgtyp = 'S' msgid = 'VY' msgnr = '007' ] ).
      rv_msg = bdc_text( it_mess = lt_mess iv_tcode = 'VI02' ).
    ENDIF.
  ENDMETHOD.


  METHOD cost_value_bdc.
    " mirrors ZVL31N form F_UPDATE_ICAT_COST_VALUE (BDC part)
    DATA lv_idx TYPE numc2.
    DATA lv_sidx TYPE numc2.
    DATA lv_push TYPE sytabix.
    DATA lv_value TYPE char15.

    lv_idx = iv_idx.
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0030' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = |VIM_MARKED({ lv_idx })| iv_fval = abap_true CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=PDET' CHANGING ct_bdc = ct_bdc ).
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'VFKP-WAERS' iv_fval = iv_curr CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '/00' CHANGING ct_bdc = ct_bdc ).
    LOOP AT it_split INTO DATA(ls_split).
      WRITE ls_split-value TO lv_value CURRENCY iv_curr.
      zcl_rpre_ib_shp_upload=>get_scost_index( EXPORTING iv_tabix = ls_split-tabix iv_tbl_idx = iv_lines
                                               IMPORTING ev_idx = lv_sidx ev_push = lv_push ).
      dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=P--' CHANGING ct_bdc = ct_bdc ).
      DO lv_push TIMES.
        dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
        field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=P+' CHANGING ct_bdc = ct_bdc ).
      ENDDO.
      dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = |VIM_MARKED({ lv_sidx })| iv_fval = abap_true CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=PKON' CHANGING ct_bdc = ct_bdc ).
      dynpro( EXPORTING iv_prog = 'SAPLV69A' iv_dynpro = '9000' CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = 'KOMV-KWERT(01)' iv_fval = lv_value CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '/00' CHANGING ct_bdc = ct_bdc ).
      dynpro( EXPORTING iv_prog = 'SAPLV69A' iv_dynpro = '9000' CHANGING ct_bdc = ct_bdc ).
      field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=BACK' CHANGING ct_bdc = ct_bdc ).
    ENDLOOP.
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=BACK' CHANGING ct_bdc = ct_bdc ).
  ENDMETHOD.


  METHOD curr_value_bdc.
    " mirrors ZVL31N form F_UPDATE_ICAT_CURR_VALUE
    DATA lv_idx TYPE numc2.
    lv_idx = iv_idx.
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0030' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = |VIM_MARKED({ lv_idx })| iv_fval = abap_true CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=PDET' CHANGING ct_bdc = ct_bdc ).
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '/00' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'VFKP-WAERS' iv_fval = iv_curr CHANGING ct_bdc = ct_bdc ).
    dynpro( EXPORTING iv_prog = 'SAPMV54A' iv_dynpro = '0040' CHANGING ct_bdc = ct_bdc ).
    field( EXPORTING iv_fnam = 'BDC_OKCODE' iv_fval = '=BACK' CHANGING ct_bdc = ct_bdc ).
  ENDMETHOD.


  METHOD dynpro.
    APPEND VALUE #( program = iv_prog dynpro = iv_dynpro dynbegin = abap_true ) TO ct_bdc.
  ENDMETHOD.


  METHOD field.
    APPEND VALUE #( fnam = iv_fnam fval = iv_fval ) TO ct_bdc.
  ENDMETHOD.


  METHOD run_bdc.
    " mirrors BDC_TRANSACTION of BDCRECXY and ZVL31N F_BDC_TRANSACTION_DEFSIZE: mode N, update S
    DATA ls_opt TYPE ctu_params.
    ls_opt-dismode = 'N'.
    ls_opt-updmode = 'S'.
    ls_opt-defsize = iv_defsize.
    TRY.
        CALL TRANSACTION iv_tcode WITH AUTHORITY-CHECK USING it_bdc OPTIONS FROM ls_opt MESSAGES INTO rt_mess.
      CATCH cx_sy_authorization_error INTO DATA(lx_auth).
        APPEND VALUE #( msgtyp = 'E' msgid = '00' msgnr = '001' msgv1 = lx_auth->get_text( ) ) TO rt_mess.
    ENDTRY.
  ENDMETHOD.


  METHOD bdc_text.
    LOOP AT it_mess INTO DATA(ls_mess) WHERE msgtyp = 'E' OR msgtyp = 'I' OR msgtyp = 'A'.
      MESSAGE ID ls_mess-msgid TYPE 'I' NUMBER ls_mess-msgnr
        WITH ls_mess-msgv1 ls_mess-msgv2 ls_mess-msgv3 ls_mess-msgv4 INTO DATA(lv_text).
      rv_text = COND #( WHEN rv_text IS INITIAL THEN lv_text ELSE |{ rv_text }. { lv_text }| ).
    ENDLOOP.
    IF rv_text IS INITIAL.
      rv_text = |{ iv_tcode } ended without success message|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.