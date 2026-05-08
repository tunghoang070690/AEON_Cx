*&---------------------------------------------------------------------*
*& Report ZHR_BANK_ACCOUNT_APP
*&---------------------------------------------------------------------*
*& HR Bank Account — SAP GUI / WebGUI (Executable, full OOP).
*& Screens 0100 / 0200 / 0300 must be created in SE51 as documented in
*& the header comment block "Screen painter checklist" below.
*& Text element TEXT-001 (Selection texts): 'Search Condition'.
*& GUI statuses: '0100' (BACK,EXIT,CANCEL), '0200' (SAVE,CLOSE),
*&               '0300' (CONFIRM,CANCEL). Create in SE41 or copy from
*&               standard list status and adjust.
*&---------------------------------------------------------------------*
REPORT zhr_bank_account_app.

*----------------------------------------------------------------------*
* Screen painter checklist (SE51)
*----------------------------------------------------------------------*
* 0100 Normal dynpro, next = 0. Custom Control CC_MAIN (container).
*      Optional caption text: 계좌 내역. Module flow:
*      PBO: STATUS_0100, DISPLAY_ALV.
*      PAI: USER_COMMAND_0100.
*      Screen field OK_CODE (char 20) recommended for toolbar FCs.
* 0200 Modal dialog, next = 0, size ~70x15. Fields: GV_ACCOUNT_TYPE
*      (output only), GV_BANK_CODE (I/O, dropdown listbox), GV_BANKN.
*      Pushbuttons SAVE / CLOSE (FC SAVE / CLOSE). OK_CODE.
*      PBO: STATUS_0200, FILL_BANK_LISTBOX. PAI: USER_COMMAND_0200.
* 0300 Modal dialog, next = 0. Static text for delete question.
*      Pushbuttons CONFIRM / CANCEL. OK_CODE.
*      PBO: STATUS_0300. PAI: USER_COMMAND_0300.
*----------------------------------------------------------------------*

TABLES: sscrfields.

TYPES: BEGIN OF ty_bank_display,
         pernr      TYPE pa0009-pernr,
         subty      TYPE pa0009-subty,
         begda      TYPE pa0009-begda,
         endda      TYPE pa0009-endda,
         bankl      TYPE pa0009-bankl,
         bankn      TYPE pa0009-bankn,
         bank_text  TYPE zthr0021-zcode_text1,
         change_txt TYPE char10,
         delete_txt TYPE char10,
       END OF ty_bank_display.
TYPES ty_t_bank_display TYPE STANDARD TABLE OF ty_bank_display WITH EMPTY KEY.

TYPES: BEGIN OF ty_zthr_dd,
         zcode       TYPE zthr0021-zcode,
         zcode_text1 TYPE zthr0021-zcode_text1,
       END OF ty_zthr_dd,
       ty_t_zthr_dd TYPE STANDARD TABLE OF ty_zthr_dd WITH EMPTY KEY.

CLASS lcl_application DEFINITION DEFERRED.

CONSTANTS:
  gc_infty_0009    TYPE infty VALUE '0009',
  gc_subty_main    TYPE pa0009-subty VALUE '0',
  gc_banks_kr      TYPE pa0009-banks VALUE 'KR',
  gc_endda_high    TYPE pa0009-endda VALUE '99991231',
  gc_bukrs_fix     TYPE bukrs VALUE '1000',
  gc_zcode_grup    TYPE zthr0021-zcode_grup VALUE 'A004',
  gc_change_label  TYPE char10 VALUE '변경',
  gc_delete_label  TYPE char10 VALUE '삭제',
  gc_account_type  TYPE text40 VALUE '급여'.

DATA gt_bank          TYPE ty_t_bank_display.
DATA gs_selected_row  TYPE ty_bank_display.
DATA gv_okcode        TYPE sy-ucomm.
DATA gv_refresh_flag  TYPE abap_bool.

* Popup 0200 / shared
DATA gv_account_type TYPE text40.
DATA gv_bank_code    TYPE pa0009-bankl.
DATA gv_bankn        TYPE pa0009-bankn.

* ALV / controls
DATA go_app          TYPE REF TO lcl_application.
DATA go_container    TYPE REF TO cl_gui_custom_container.
DATA go_grid         TYPE REF TO cl_gui_alv_grid.
DATA go_event_handler TYPE REF TO lcl_alv_handler.
DATA gv_grid_ready   TYPE abap_bool.

* Selection screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS:
  p_bank  TYPE pa0009-bankl,
  p_bankn TYPE pa0009-bankn.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Local exception
*----------------------------------------------------------------------*
CLASS lcx_bank_app DEFINITION INHERITING FROM cx_static_check FINAL.
  PUBLIC SECTION.
    DATA text TYPE string READ-ONLY.
    METHODS constructor IMPORTING iv_text TYPE string.
ENDCLASS.

CLASS lcx_bank_app IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    text = iv_text.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_UTIL — BAPI return helpers (minimal)
*----------------------------------------------------------------------*
CLASS lcl_util DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS is_error_return
      IMPORTING is_return       TYPE bapireturn1
      RETURNING VALUE(rv_error) TYPE abap_bool.
    CLASS-METHODS return_message
      IMPORTING is_return      TYPE bapireturn1
      RETURNING VALUE(rv_msg) TYPE string.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD is_error_return.
    rv_error = abap_false.
    IF is_return-type CA 'EA'.
      rv_error = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD return_message.
    rv_msg = is_return-message.
    IF rv_msg IS INITIAL.
      MESSAGE ID is_return-id TYPE 'S' NUMBER is_return-number
              WITH is_return-message_v1 is_return-message_v2
                   is_return-message_v3 is_return-message_v4
              INTO rv_msg.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_HR_OPERATION
*----------------------------------------------------------------------*
CLASS lcl_hr_operation DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS modify_bank_record
      IMPORTING
        iv_pernr   TYPE pa0009-pernr
        iv_bankl   TYPE pa0009-bankl
        iv_bankn   TYPE pa0009-bankn
      RETURNING VALUE(rv_ok) TYPE abap_bool
      RAISING   lcx_bank_app.
    METHODS delete_bank_record
      IMPORTING
        is_key     TYPE ty_bank_display
      RETURNING VALUE(rv_ok) TYPE abap_bool
      RAISING   lcx_bank_app.
ENDCLASS.

CLASS lcl_hr_operation IMPLEMENTATION.
  METHOD modify_bank_record.
    DATA ls_p0009 TYPE p0009.
    DATA lr       TYPE bapireturn1.

    CLEAR ls_p0009.
    ls_p0009-pernr = iv_pernr.
    ls_p0009-infty = gc_infty_0009.
    ls_p0009-subty = gc_subty_main.
    ls_p0009-banks = gc_banks_kr.
    ls_p0009-bankl = iv_bankl.
    ls_p0009-bankn = iv_bankn.
    ls_p0009-begda = sy-datum.
    ls_p0009-endda = gc_endda_high.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = gc_infty_0009
        number        = iv_pernr
        validitybegin = ls_p0009-begda
        validityend   = ls_p0009-endda
        record        = ls_p0009
        operation     = 'MOD'
        tclas         = 'A'
      IMPORTING
        return        = lr.

    IF lcl_util=>is_error_return( lr ) = abap_true.
      RAISE EXCEPTION TYPE lcx_bank_app
        EXPORTING
          iv_text = lcl_util=>return_message( lr ).
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD delete_bank_record.
    DATA ls_p0009 TYPE p0009.
    DATA lr       TYPE bapireturn1.

    CLEAR ls_p0009.
    ls_p0009-pernr = is_key-pernr.
    ls_p0009-infty = gc_infty_0009.
    ls_p0009-subty = gc_subty_main.
    ls_p0009-banks = gc_banks_kr.
    ls_p0009-bankl = is_key-bankl.
    ls_p0009-bankn = is_key-bankn.
    ls_p0009-begda = is_key-begda.
    ls_p0009-endda = is_key-endda.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = gc_infty_0009
        number        = is_key-pernr
        validitybegin = ls_p0009-begda
        validityend   = ls_p0009-endda
        record        = ls_p0009
        operation     = 'DEL'
        tclas         = 'A'
      IMPORTING
        return        = lr.

    IF lcl_util=>is_error_return( lr ) = abap_true.
      RAISE EXCEPTION TYPE lcx_bank_app
        EXPORTING
          iv_text = lcl_util=>return_message( lr ).
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_BANK_REPOSITORY
*----------------------------------------------------------------------*
CLASS lcl_bank_repository DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS get_logon_pernr RETURNING VALUE(rv_pernr) TYPE pa0009-pernr
                            RAISING   lcx_bank_app.
    METHODS read_bank_accounts
      IMPORTING
        iv_bankl_filter TYPE pa0009-bankl
        iv_bankn_filter TYPE pa0009-bankn
      RETURNING VALUE(rt_rows) TYPE ty_t_bank_display
      RAISING   lcx_bank_app.
    METHODS read_bank_names_for_dropdown
      RETURNING VALUE(rt_values) TYPE vrm_values.
    METHODS read_bank_text
      IMPORTING iv_bankl      TYPE pa0009-bankl
      RETURNING VALUE(rv_txt) TYPE zthr0021-zcode_text1.
  PRIVATE SECTION.
    METHODS lookup_bank_text
      IMPORTING iv_bankl      TYPE pa0009-bankl
      RETURNING VALUE(rv_txt) TYPE zthr0021-zcode_text1.
ENDCLASS.

CLASS lcl_bank_repository IMPLEMENTATION.
  METHOD get_logon_pernr.
    DATA lv_uname TYPE syuname.
    lv_uname = sy-uname.

    SELECT SINGLE pernr
      FROM pa0105
      INTO rv_pernr
      WHERE subty    = '0001'
        AND usrty    = 'B'
        AND ( usrid = lv_uname OR usrid_long = lv_uname )
        AND begda    <= sy-datum
        AND endda    >= sy-datum.
    IF sy-subrc = 0 AND rv_pernr IS NOT INITIAL.
      RETURN.
    ENDIF.

    GET PARAMETER ID 'PERNR' FIELD rv_pernr.
    IF rv_pernr IS INITIAL.
      RAISE EXCEPTION TYPE lcx_bank_app
        EXPORTING
          iv_text = |Personnel number not found for user { lv_uname }.|.
    ENDIF.
  ENDMETHOD.

  METHOD read_bank_text.
    rv_txt = lookup_bank_text( iv_bankl ).
  ENDMETHOD.

  METHOD lookup_bank_text.
    SELECT SINGLE zcode_text1
      FROM zthr0021
      INTO rv_txt
      WHERE bukrs       = gc_bukrs_fix
        AND zcode_grup  = gc_zcode_grup
        AND zcode       = iv_bankl
        AND begda       <= sy-datum
        AND endda       >= sy-datum.
  ENDMETHOD.

  METHOD read_bank_names_for_dropdown.
    DATA ls_val TYPE vrm_value.

    DATA lt_dd TYPE ty_t_zthr_dd.

    CLEAR rt_values.
    SELECT zcode zcode_text1
      FROM zthr0021
      INTO TABLE lt_dd
      WHERE bukrs      = gc_bukrs_fix
        AND zcode_grup = gc_zcode_grup
        AND begda      <= sy-datum
        AND endda      >= sy-datum
      ORDER BY zcode.
    LOOP AT lt_dd ASSIGNING FIELD-SYMBOL(<dd>).
      CLEAR ls_val.
      ls_val-key  = <dd>-zcode.
      ls_val-text = <dd>-zcode_text1.
      APPEND ls_val TO rt_values.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_bank_accounts.
    DATA lv_pernr TYPE pa0009-pernr.
    DATA lt_pa    TYPE STANDARD TABLE OF pa0009 WITH EMPTY KEY.
    DATA lv_like_bankl TYPE pa0009-bankl.
    DATA lv_like_bankn TYPE pa0009-bankn.
    FIELD-SYMBOLS <pa> TYPE pa0009.

    lv_pernr = get_logon_pernr( ).

    lv_like_bankl = iv_bankl_filter.
    lv_like_bankn = iv_bankn_filter.
    IF lv_like_bankl IS INITIAL.
      lv_like_bankl = '%'.
    ENDIF.
    IF lv_like_bankn IS INITIAL.
      lv_like_bankn = '%'.
    ENDIF.

    SELECT pernr subty begda endda bankl bankn
      FROM pa0009
      INTO CORRESPONDING FIELDS OF TABLE lt_pa
      WHERE pernr = lv_pernr
        AND subty = gc_subty_main
        AND begda <= sy-datum
        AND endda >= sy-datum
        AND bankl LIKE lv_like_bankl
        AND bankn LIKE lv_like_bankn.

    LOOP AT lt_pa ASSIGNING <pa>.
      APPEND VALUE #(
        pernr      = <pa>-pernr
        subty      = <pa>-subty
        begda      = <pa>-begda
        endda      = <pa>-endda
        bankl      = <pa>-bankl
        bankn      = <pa>-bankn
        bank_text  = lookup_bank_text( <pa>-bankl )
        change_txt = gc_change_label
        delete_txt = gc_delete_label
      ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_BANK_SERVICE
*----------------------------------------------------------------------*
CLASS lcl_bank_service DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_repo TYPE REF TO lcl_bank_repository
        io_hr   TYPE REF TO lcl_hr_operation.
    METHODS save_change
      IMPORTING
        is_key TYPE ty_bank_display
      RAISING  lcx_bank_app.
    METHODS delete_row
      IMPORTING
        is_key TYPE ty_bank_display
      RAISING  lcx_bank_app.
  PRIVATE SECTION.
    DATA mo_repo TYPE REF TO lcl_bank_repository.
    DATA mo_hr   TYPE REF TO lcl_hr_operation.
ENDCLASS.

CLASS lcl_bank_service IMPLEMENTATION.
  METHOD constructor.
    mo_repo = io_repo.
    mo_hr   = io_hr.
  ENDMETHOD.

  METHOD save_change.
    IF gv_bank_code IS INITIAL OR gv_bankn IS INITIAL.
      RAISE EXCEPTION TYPE lcx_bank_app
        EXPORTING
          iv_text = 'Bank and account number are required.'.
    ENDIF.
    mo_hr->modify_bank_record(
      iv_pernr = is_key-pernr
      iv_bankl = gv_bank_code
      iv_bankn = gv_bankn ).
  ENDMETHOD.

  METHOD delete_row.
    mo_hr->delete_bank_record( is_key ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_ALV_HANDLER
*----------------------------------------------------------------------*
CLASS lcl_alv_handler DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_app TYPE REF TO lcl_application.
    METHODS on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
  PRIVATE SECTION.
    DATA mo_app TYPE REF TO lcl_application.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_POPUP_HANDLER
*----------------------------------------------------------------------*
CLASS lcl_popup_handler DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_app TYPE REF TO lcl_application.
    METHODS open_change_popup.
    METHODS open_delete_popup.
  PRIVATE SECTION.
    DATA mo_app TYPE REF TO lcl_application.
ENDCLASS.

*----------------------------------------------------------------------*
* LCL_APPLICATION
*----------------------------------------------------------------------*
CLASS lcl_application DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(ro_inst) TYPE REF TO lcl_application.
    METHODS run.
    METHODS reload_and_refresh.
    METHODS handle_hotspot
      IMPORTING
        iv_column TYPE lvc_fname
        iv_row    TYPE i.
    METHODS grid_ready RETURNING VALUE(rv_ready) TYPE abap_bool.
    METHODS get_repository RETURNING VALUE(ro_repo) TYPE REF TO lcl_bank_repository.
    METHODS get_service RETURNING VALUE(ro_srv) TYPE REF TO lcl_bank_service.
  PRIVATE SECTION.
    CLASS-DATA go_me TYPE REF TO lcl_application.
    DATA mo_repo    TYPE REF TO lcl_bank_repository.
    DATA mo_service TYPE REF TO lcl_bank_service.
    DATA mo_popup   TYPE REF TO lcl_popup_handler.
    METHODS load_list.
ENDCLASS.

CLASS lcl_alv_handler IMPLEMENTATION.
  METHOD constructor.
    mo_app = io_app.
  ENDMETHOD.

  METHOD on_hotspot_click.
    DATA lv_row TYPE i.
    lv_row = e_row_id-index.
    CHECK lv_row > 0.
    mo_app->handle_hotspot(
      iv_column = e_column_id-fieldname
      iv_row    = lv_row ).
  ENDMETHOD.
ENDCLASS.

CLASS lcl_popup_handler IMPLEMENTATION.
  METHOD constructor.
    mo_app = io_app.
  ENDMETHOD.

  METHOD open_change_popup.
    gv_account_type = gc_account_type.
    gv_bank_code    = gs_selected_row-bankl.
    gv_bankn        = gs_selected_row-bankn.
    gv_refresh_flag = abap_false.
    CALL SCREEN 0200 STARTING AT 20 5 ENDING AT 90 20.
    IF gv_refresh_flag = abap_true.
      mo_app->reload_and_refresh( ).
    ENDIF.
  ENDMETHOD.

  METHOD open_delete_popup.
    gv_refresh_flag = abap_false.
    CALL SCREEN 0300 STARTING AT 30 10 ENDING AT 70 18.
    IF gv_refresh_flag = abap_true.
      mo_app->reload_and_refresh( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_application IMPLEMENTATION.
  METHOD get_instance.
    IF go_me IS INITIAL.
      CREATE OBJECT go_me.
    ENDIF.
    ro_inst = go_me.
  ENDMETHOD.

  METHOD grid_ready.
    rv_ready = gv_grid_ready.
  ENDMETHOD.

  METHOD get_repository.
    ro_repo = mo_repo.
  ENDMETHOD.

  METHOD get_service.
    ro_srv = mo_service.
  ENDMETHOD.

  METHOD load_list.
    CREATE OBJECT mo_repo.
    CREATE OBJECT mo_service
      EXPORTING
        io_repo = mo_repo
        io_hr   = NEW lcl_hr_operation( ).
    CREATE OBJECT mo_popup
      EXPORTING
        io_app = me.

    gt_bank = mo_repo->read_bank_accounts(
      iv_bankl_filter = p_bank
      iv_bankn_filter = p_bankn ).
  ENDMETHOD.

  METHOD run.
    TRY.
        load_list( ).
      CATCH lcx_bank_app INTO DATA(lx_run).
        MESSAGE lx_run->text TYPE 'E'.
        RETURN.
    ENDTRY.
    CALL SCREEN 0100.
  ENDMETHOD.

  METHOD reload_and_refresh.
    TRY.
        gt_bank = mo_repo->read_bank_accounts(
          iv_bankl_filter = p_bank
          iv_bankn_filter = p_bankn ).
      CATCH lcx_bank_app INTO DATA(lx).
        MESSAGE lx->text TYPE 'E'.
        RETURN.
    ENDTRY.
    IF go_grid IS BOUND.
      go_grid->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_hotspot.
    FIELD-SYMBOLS <fs> TYPE ty_bank_display.
    READ TABLE gt_bank ASSIGNING <fs> INDEX iv_row.
    CHECK sy-subrc = 0.
    gs_selected_row = <fs>.

    CASE iv_column.
      WHEN 'CHANGE_TXT'.
        mo_popup->open_change_popup( ).
      WHEN 'DELETE_TXT'.
        mo_popup->open_delete_popup( ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* INITIALIZATION / AT SELECTION-SCREEN / START-OF-SELECTION
*----------------------------------------------------------------------*
INITIALIZATION.
  go_app = lcl_application=>get_instance( ).

START-OF-SELECTION.
  gv_grid_ready = abap_false.
  go_app->run( ).

*----------------------------------------------------------------------*
* PBO / PAI modules
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.
  SET TITLEBAR 'T010'.
ENDMODULE.

MODULE display_alv OUTPUT.
  DATA lt_fcat TYPE lvc_t_fcat.
  DATA ls_fcat TYPE lvc_s_fcat.
  DATA ls_layo TYPE lvc_s_layo.

  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_container.

    CREATE OBJECT go_event_handler
      EXPORTING
        io_app = go_app.

    SET HANDLER go_event_handler->on_hotspot_click FOR go_grid.

    CLEAR ls_layo.
    ls_layo-zebra      = abap_true.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-grid_title = '계좌 내역'.

    CLEAR lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BANK_TEXT'.
    ls_fcat-ref_table = 'TY_BANK_DISPLAY'.
    ls_fcat-ref_field = 'BANK_TEXT'.
    ls_fcat-coltext = ls_fcat-scrtext_l = '은행'.
    ls_fcat-outputlen = 30.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BANKN'.
    ls_fcat-ref_table = 'TY_BANK_DISPLAY'.
    ls_fcat-ref_field = 'BANKN'.
    ls_fcat-coltext = ls_fcat-scrtext_l = '계좌 번호'.
    ls_fcat-outputlen = 24.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'CHANGE_TXT'.
    ls_fcat-ref_table = 'TY_BANK_DISPLAY'.
    ls_fcat-ref_field = 'CHANGE_TXT'.
    ls_fcat-coltext = ls_fcat-scrtext_l = '변경'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'DELETE_TXT'.
    ls_fcat-ref_table = 'TY_BANK_DISPLAY'.
    ls_fcat-ref_field = 'DELETE_TXT'.
    ls_fcat-coltext = ls_fcat-scrtext_l = '삭제'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'PERNR'.
    ls_fcat-tech = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'SUBTY'.
    ls_fcat-tech = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BEGDA'.
    ls_fcat-tech = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'ENDDA'.
    ls_fcat-tech = abap_true.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BANKL'.
    ls_fcat-tech = abap_true.
    APPEND ls_fcat TO lt_fcat.

    go_grid->set_table_for_first_display(
      EXPORTING
        is_layout                     = ls_layo
      CHANGING
        it_outtab                     = gt_bank
        it_fieldcatalog               = lt_fcat ).

    gv_grid_ready = abap_true.
  ELSE.
    go_grid->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_okcode = sy-ucomm.
  CLEAR sy-ucomm.
  CASE gv_okcode.
    WHEN 'BACK' OR 'EXIT' OR 'ECAN' OR 'E'.
      PERFORM leave_program.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS '0200'.
  SET TITLEBAR 'T020'.
ENDMODULE.

MODULE fill_bank_listbox OUTPUT.
  DATA lt_values TYPE vrm_values.
  lt_values = go_app->get_repository( )->read_bank_names_for_dropdown( ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_BANK_CODE'
    TABLES
      values = lt_values.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_okcode = sy-ucomm.
  CLEAR sy-ucomm.
  CASE gv_okcode.
    WHEN 'SAVE'.
      TRY.
          go_app->get_service( )->save_change( gs_selected_row ).
          COMMIT WORK AND WAIT.
          MESSAGE |Saved.| TYPE 'S'.
          gv_refresh_flag = abap_true.
          LEAVE TO SCREEN 0.
        CATCH lcx_bank_app INTO DATA(lx_s).
          ROLLBACK WORK.
          MESSAGE lx_s->text TYPE 'E'.
      ENDTRY.
    WHEN 'CLOSE' OR 'ECAN' OR 'E'.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

MODULE status_0300 OUTPUT.
  SET PF-STATUS '0300'.
  SET TITLEBAR 'T030'.
ENDMODULE.

MODULE user_command_0300 INPUT.
  gv_okcode = sy-ucomm.
  CLEAR sy-ucomm.
  CASE gv_okcode.
    WHEN 'CONFIRM'.
      TRY.
          go_app->get_service( )->delete_row( gs_selected_row ).
          COMMIT WORK AND WAIT.
          MESSAGE |Deleted.| TYPE 'S'.
          gv_refresh_flag = abap_true.
          LEAVE TO SCREEN 0.
        CATCH lcx_bank_app INTO DATA(lx_d).
          ROLLBACK WORK.
          MESSAGE lx_d->text TYPE 'E'.
      ENDTRY.
    WHEN 'CANCEL' OR 'ECAN' OR 'E'.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

*----------------------------------------------------------------------*
* Helpers
*----------------------------------------------------------------------*
FORM leave_program.
  IF go_grid IS BOUND.
    go_grid->free( ).
    CLEAR go_grid.
  ENDIF.
  IF go_container IS BOUND.
    go_container->free( ).
    CLEAR go_container.
  ENDIF.
  CLEAR go_event_handler.
  gv_grid_ready = abap_false.
  LEAVE PROGRAM.
ENDFORM.

*----------------------------------------------------------------------*
* Text symbols (maintain in SE38): TEXT-001 = Search Condition
*----------------------------------------------------------------------*
