REPORT zhr_bank_account_app.

*----------------------------------------------------------------------*
* Bank account maintenance (PA0009) — SAP GUI / WebGUI
* Dynpro + table control (no ALV). Full local OOP. See
* zhr_bank_account_app.screenflow.txt for SE51 layout and flow logic.
*----------------------------------------------------------------------*

TYPE-POOLS: vrm.

*----------------------------------------------------------------------*
* Selection screen (optional filters; personnel number from memory)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETERS:
  p_bankl TYPE pa0009-bankl,
  p_bankn TYPE pa0009-bankn,
  p_pernr TYPE pernr_d MEMORY ID per.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Global data for dynpros and table control
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_account,
         pernr     TYPE pa0009-pernr,
         subty     TYPE pa0009-subty,
         objps     TYPE pa0009-objps,
         sprps     TYPE pa0009-sprps,
         begda     TYPE pa0009-begda,
         endda     TYPE pa0009-endda,
         seqnr     TYPE pa0009-seqnr,
         bankl     TYPE pa0009-bankl,
         bank_text TYPE text50,
         bankn     TYPE pa0009-bankn,
       END OF ty_account.
TYPES ty_t_account TYPE STANDARD TABLE OF ty_account WITH KEY pernr subty objps sprps begda endda seqnr.

DATA gt_account  TYPE ty_t_account.
DATA gs_account  TYPE ty_account.
DATA gs_selected TYPE ty_account.

CONTROLS tc_account TYPE TABLEVIEW USING SCREEN '0100'.

DATA gv_bank_text TYPE text50.
DATA gv_bankn     TYPE pa0009-bankn.

DATA gv_account_type TYPE c LENGTH 20.
DATA gv_bank_code    TYPE zthr0021-zcode.
DATA gv_ok          TYPE sy-ucomm.

DATA gv_confirm_text TYPE c LENGTH 60.

*----------------------------------------------------------------------*
* Exceptions
*----------------------------------------------------------------------*
CLASS lcx_app DEFINITION FINAL INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    DATA text TYPE string READ-ONLY.
    METHODS constructor IMPORTING iv_text TYPE string.
ENDCLASS.

CLASS lcx_app IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    text = iv_text.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Forward declarations
*----------------------------------------------------------------------*
CLASS lcl_repository DEFINITION DEFERRED.
CLASS lcl_hr_service   DEFINITION DEFERRED.
CLASS lcl_validator    DEFINITION DEFERRED.
CLASS lcl_screen_mgr   DEFINITION DEFERRED.

*----------------------------------------------------------------------*
* Repository — only PA0009 / ZTHR0021 SELECTs
*----------------------------------------------------------------------*
CLASS lcl_repository DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING iv_bukrs TYPE bukrs iv_zcode_grup TYPE zthr0021-zcode_grup.
    METHODS select_accounts
      IMPORTING
        iv_pernr TYPE pernr_d
        iv_bankl TYPE pa0009-bankl
        iv_bankn TYPE pa0009-bankn
      RETURNING
        VALUE(rt_account) TYPE ty_t_account
      RAISING
        lcx_app.
    METHODS select_bank_dropdown
      RETURNING
        VALUE(rt_pairs) TYPE vrm_values
      RAISING
        lcx_app.
    METHODS select_p0009_record
      IMPORTING
        is_key TYPE ty_account
      RETURNING
        VALUE(rs_p0009) TYPE p0009
      RAISING
        lcx_app.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_zthr_line,
             zcode       TYPE zthr0021-zcode,
             zcode_text1 TYPE zthr0021-zcode_text1,
           END OF ty_zthr_line.
    TYPES: BEGIN OF ty_bank_map_line,
             bankl TYPE pa0009-bankl,
             text  TYPE text50,
           END OF ty_bank_map_line.
    TYPES ty_t_zthr_line TYPE STANDARD TABLE OF ty_zthr_line WITH EMPTY KEY.
    TYPES ty_th_bank_map TYPE HASHED TABLE OF ty_bank_map_line WITH UNIQUE KEY bankl.
    DATA mv_bukrs      TYPE bukrs.
    DATA mv_zcode_grup TYPE zthr0021-zcode_grup.
    METHODS fetch_zthr_lines
      RETURNING
        VALUE(rt_lines) TYPE ty_t_zthr_line.
    METHODS build_bank_text_map
      IMPORTING
        it_lines TYPE ty_t_zthr_line
      RETURNING
        VALUE(rt_map) TYPE ty_th_bank_map.
ENDCLASS.

CLASS lcl_repository IMPLEMENTATION.
  METHOD constructor.
    mv_bukrs = iv_bukrs.
    mv_zcode_grup = iv_zcode_grup.
  ENDMETHOD.

  METHOD fetch_zthr_lines.
    SELECT zcode zcode_text1
      FROM zthr0021
      INTO TABLE rt_lines
      WHERE bukrs      = mv_bukrs
        AND zcode_grup = mv_zcode_grup
        AND begda     <= sy-datum
        AND endda     >= sy-datum.
    IF sy-subrc <> 0.
      CLEAR rt_lines.
    ENDIF.
  ENDMETHOD.

  METHOD build_bank_text_map.
    FIELD-SYMBOLS <l> LIKE LINE OF it_lines.
    CLEAR rt_map.
    LOOP AT it_lines ASSIGNING <l>.
      INSERT VALUE #( bankl = <l>-zcode text = <l>-zcode_text1 ) INTO TABLE rt_map.
    ENDLOOP.
  ENDMETHOD.

  METHOD select_bank_dropdown.
    DATA lt_lines TYPE ty_t_zthr_line.
    FIELD-SYMBOLS <l> LIKE LINE OF lt_lines.

    lt_lines = fetch_zthr_lines( ).
    LOOP AT lt_lines ASSIGNING <l>.
      APPEND VALUE #( key = <l>-zcode text = <l>-zcode_text1 ) TO rt_pairs.
    ENDLOOP.
  ENDMETHOD.

  METHOD select_accounts.
    DATA lt_pa   TYPE STANDARD TABLE OF pa0009 WITH EMPTY KEY.
    DATA ls_out  TYPE ty_account.
    DATA lt_lines TYPE ty_t_zthr_line.
    DATA lt_bank  TYPE ty_th_bank_map.
    FIELD-SYMBOLS <p> LIKE LINE OF lt_pa.

    IF iv_pernr IS INITIAL.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |Personnel number is required.|.
    ENDIF.

    SELECT *
      FROM pa0009
      INTO TABLE lt_pa
      WHERE pernr = iv_pernr
        AND endda >= sy-datum
        AND begda <= sy-datum
        AND ( bankl = iv_bankl OR iv_bankl IS INITIAL )
        AND ( bankn = iv_bankn OR iv_bankn IS INITIAL )
      ORDER BY PRIMARY KEY.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lt_lines = fetch_zthr_lines( ).
    lt_bank = build_bank_text_map( lt_lines ).

    DATA ls_bank TYPE ty_bank_map_line.
    LOOP AT lt_pa ASSIGNING <p>.
      CLEAR ls_out.
      MOVE-CORRESPONDING <p> TO ls_out.
      READ TABLE lt_bank INTO ls_bank WITH TABLE KEY bankl = <p>-bankl.
      IF sy-subrc = 0.
        ls_out-bank_text = ls_bank-text.
      ENDIF.
      APPEND ls_out TO rt_account.
    ENDLOOP.
  ENDMETHOD.

  METHOD select_p0009_record.
    SELECT SINGLE *
      FROM pa0009
      INTO rs_p0009
      WHERE pernr = is_key-pernr
        AND subty = is_key-subty
        AND objps = is_key-objps
        AND sprps = is_key-sprps
        AND begda = is_key-begda
        AND endda = is_key-endda
        AND seqnr = is_key-seqnr.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |PA0009 record not found.|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* HR service — only HR_INFOTYPE_OPERATION
*----------------------------------------------------------------------*
CLASS lcl_hr_service DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_repo TYPE REF TO lcl_repository.
    METHODS modify_bank_record
      IMPORTING
        is_key       TYPE ty_account
        iv_new_bankl TYPE pa0009-bankl
        iv_new_bankn TYPE pa0009-bankn
      RAISING
        lcx_app.
    METHODS delete_bank_record
      IMPORTING
        is_key TYPE ty_account
      RAISING
        lcx_app.
  PRIVATE SECTION.
    DATA mo_repo TYPE REF TO lcl_repository.
    METHODS call_infotype_operation
      IMPORTING
        iv_operation TYPE char3
        is_p0009     TYPE p0009
      RAISING
        lcx_app.
ENDCLASS.

CLASS lcl_hr_service IMPLEMENTATION.
  METHOD constructor.
    mo_repo = io_repo.
  ENDMETHOD.

  METHOD call_infotype_operation.
    DATA ls_return TYPE bapireturn1.
    DATA ls_rec    TYPE p0009.
    ls_rec = is_p0009.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        operation     = iv_operation
        infty         = '0009'
        number        = ls_rec-pernr
        subtype       = ls_rec-subty
        lockuser      = sy-uname
        nocommit      = space
        authorized    = 'X'
        dialog_mode   = '0'
        record        = ls_rec
        validitybegin = ls_rec-begda
        validityend   = ls_rec-endda
        tclas           = 'A'
      IMPORTING
        return          = ls_return
      EXCEPTIONS
        OTHERS          = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |HR_INFOTYPE_OPERATION failed: { sy-msgid }{ sy-msgno } { sy-msgv1 }|.
    ENDIF.
    IF ls_return-type CA 'AE'.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |HR_INFOTYPE_OPERATION failed: { ls_return-message }|.
    ENDIF.

    COMMIT WORK AND WAIT.
  ENDMETHOD.

  METHOD modify_bank_record.
    DATA ls_p0009 TYPE p0009.
    ls_p0009 = mo_repo->select_p0009_record( is_key ).
    ls_p0009-bankl = iv_new_bankl.
    ls_p0009-bankn = iv_new_bankn.
    call_infotype_operation( iv_operation = 'MOD' is_p0009 = ls_p0009 ).
  ENDMETHOD.

  METHOD delete_bank_record.
    DATA ls_p0009 TYPE p0009.
    ls_p0009 = mo_repo->select_p0009_record( is_key ).
    call_infotype_operation( iv_operation = 'DEL' is_p0009 = ls_p0009 ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Validator
*----------------------------------------------------------------------*
CLASS lcl_validator DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS validate_change_popup
      IMPORTING
        iv_bankl TYPE pa0009-bankl
        iv_bankn TYPE pa0009-bankn
      RAISING
        lcx_app.
ENDCLASS.

CLASS lcl_validator IMPLEMENTATION.
  METHOD validate_change_popup.
    IF iv_bankl IS INITIAL.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |Select a bank.|.
    ENDIF.
    IF iv_bankn IS INITIAL.
      RAISE EXCEPTION TYPE lcx_app EXPORTING iv_text = |Enter account number.|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Screen manager — popups and refresh
*----------------------------------------------------------------------*
CLASS lcl_screen_mgr DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS open_change_popup.
    CLASS-METHODS open_delete_popup.
    CLASS-METHODS refresh_main_list.
  PRIVATE SECTION.
    CLASS-METHODS current_row_index RETURNING VALUE(rv_idx) TYPE i.
ENDCLASS.

CLASS lcl_screen_mgr IMPLEMENTATION.
  METHOD current_row_index.
    IF sy-stepl > 0.
      rv_idx = tc_account-top_line + sy-stepl - 1.
    ELSE.
      rv_idx = tc_account-current_line.
    ENDIF.
  ENDMETHOD.

  METHOD open_change_popup.
    DATA lv_idx TYPE i.
    lv_idx = current_row_index( ).
    IF lv_idx < 1.
      MESSAGE |Select a row first.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    READ TABLE gt_account INTO gs_selected INDEX lv_idx.
    IF sy-subrc <> 0.
      MESSAGE |Select a row first.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    gv_bank_code = gs_selected-bankl.
    gv_bankn     = gs_selected-bankn.
    gv_account_type = '급여'.
    CALL SCREEN 0200 STARTING AT 5 5 ENDING AT 75 20.
  ENDMETHOD.

  METHOD open_delete_popup.
    DATA lv_idx TYPE i.
    lv_idx = current_row_index( ).
    IF lv_idx < 1.
      MESSAGE |Select a row first.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    READ TABLE gt_account INTO gs_selected INDEX lv_idx.
    IF sy-subrc <> 0.
      MESSAGE |Select a row first.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    gv_confirm_text = '계좌를 삭제하시겠습니까?'.
    CALL SCREEN 0300 STARTING AT 10 10 ENDING AT 70 12.
  ENDMETHOD.

  METHOD refresh_main_list.
    TRY.
        gt_account = lcl_application=>repo( )->select_accounts(
          iv_pernr = p_pernr
          iv_bankl = p_bankl
          iv_bankn = p_bankn ).
      CATCH lcx_app INTO DATA(lx).
        MESSAGE lx->text TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
    DESCRIBE TABLE gt_account LINES tc_account-lines.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Application controller
*----------------------------------------------------------------------*
CLASS lcl_application DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS class_constructor.
    CLASS-METHODS start.
    CLASS-METHODS repo RETURNING VALUE(ro) TYPE REF TO lcl_repository.
    CLASS-METHODS hr RETURNING VALUE(ro) TYPE REF TO lcl_hr_service.
  PRIVATE SECTION.
    CLASS-DATA go_repo TYPE REF TO lcl_repository.
    CLASS-DATA go_hr   TYPE REF TO lcl_hr_service.
ENDCLASS.

CLASS lcl_application IMPLEMENTATION.
  METHOD class_constructor.
    go_repo = NEW #( iv_bukrs = '1000' iv_zcode_grup = 'A004' ).
    go_hr   = NEW #( go_repo ).
  ENDMETHOD.

  METHOD repo.
    ro = go_repo.
  ENDMETHOD.

  METHOD hr.
    ro = go_hr.
  ENDMETHOD.

  METHOD start.
    IF p_pernr IS INITIAL.
      MESSAGE |Personnel number (PERNR) is required.| TYPE 'E'.
      RETURN.
    ENDIF.

    TRY.
        gt_account = go_repo->select_accounts(
          iv_pernr = p_pernr
          iv_bankl = p_bankl
          iv_bankn = p_bankn ).
      CATCH lcx_app INTO DATA(lx).
        MESSAGE lx->text TYPE 'E'.
        RETURN.
    ENDTRY.

    CALL SCREEN 0100.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Selection screen events
*----------------------------------------------------------------------*
INITIALIZATION.
  GET PARAMETER ID 'PER' FIELD p_pernr.

START-OF-SELECTION.
  lcl_application=>start( ).

*----------------------------------------------------------------------*
* PBO / PAI modules — screen 0100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZHR_BNK_MAIN'.
  SET TITLEBAR 'ZHR_BNK_T0100'.
ENDMODULE.

MODULE load_account_list OUTPUT.
  DESCRIBE TABLE gt_account LINES tc_account-lines.
  IF tc_account-lines > 0 AND tc_account-current_line < 1.
    tc_account-current_line = 1.
  ENDIF.
ENDMODULE.

MODULE fill_account_row OUTPUT.
  gv_bank_text = gs_account-bank_text.
  gv_bankn     = gs_account-bankn.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE gv_ok.
    WHEN 'BACK' OR 'EXIT' OR 'ECAN'.
      LEAVE TO SCREEN 0.
    WHEN 'ZCHG'.
      lcl_screen_mgr=>open_change_popup( ).
    WHEN 'ZDEL'.
      lcl_screen_mgr=>open_delete_popup( ).
    WHEN OTHERS.
  ENDCASE.

  CLEAR gv_ok.
ENDMODULE.

*----------------------------------------------------------------------*
* PBO / PAI modules — screen 0200
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'ZHR_BNK_0200'.
  SET TITLEBAR 'ZHR_BNK_T0200'.
ENDMODULE.

MODULE fill_bank_listbox OUTPUT.
  DATA lt_values TYPE vrm_values.
  TRY.
      lt_values = lcl_application=>repo( )->select_bank_dropdown( ).
    CATCH lcx_app.
      CLEAR lt_values.
  ENDTRY.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_BANK_CODE'
    CHANGING
      values = lt_values.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE gv_ok.
    WHEN 'CLOSE' OR 'ECAN' OR 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      TRY.
          lcl_validator=>validate_change_popup(
            iv_bankl = gv_bank_code
            iv_bankn = gv_bankn ).
          lcl_application=>hr( )->modify_bank_record(
            is_key       = gs_selected
            iv_new_bankl = gv_bank_code
            iv_new_bankn = gv_bankn ).
        CATCH lcx_app INTO DATA(lx).
          MESSAGE lx->text TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
      ENDTRY.
      lcl_screen_mgr=>refresh_main_list( ).
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.

  CLEAR gv_ok.
ENDMODULE.

*----------------------------------------------------------------------*
* PBO / PAI modules — screen 0300
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'ZHR_BNK_0300'.
  SET TITLEBAR 'ZHR_BNK_T0300'.
ENDMODULE.

MODULE user_command_0300 INPUT.
  gv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE gv_ok.
    WHEN 'CANC' OR 'ECAN' OR 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'CONF'.
      TRY.
          lcl_application=>hr( )->delete_bank_record( gs_selected ).
        CATCH lcx_app INTO DATA(lx).
          MESSAGE lx->text TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
      ENDTRY.
      lcl_screen_mgr=>refresh_main_list( ).
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.

  CLEAR gv_ok.
ENDMODULE.
