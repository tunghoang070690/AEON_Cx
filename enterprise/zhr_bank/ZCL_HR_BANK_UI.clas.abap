*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_UI
*&---------------------------------------------------------------------*
*& Presentation controller: dynpro state, ALV, modal CALL SCREEN flows.
*& Reads/writes report globals OK_CODE partners via parameters + TOP globals.
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS screen_0100_pbo .
    CLASS-METHODS screen_0100_pai
      IMPORTING
        !iv_ucomm TYPE sy-ucomm
      CHANGING
        !cv_bankl TYPE zthr0021-zcode
        !cv_bankn TYPE bankn .

    CLASS-METHODS screen_0200_pbo .
    CLASS-METHODS on_before_change_popup
      CHANGING
        !cv_bankl TYPE zthr0021-zcode
        !cv_bankn TYPE bankn .

    CLASS-METHODS screen_0200_pai
      IMPORTING
        !iv_ucomm     TYPE sy-ucomm
        !iv_bank_code TYPE zthr0021-zcode
        !iv_bankn     TYPE bankn .

    CLASS-METHODS screen_0300_pbo .
    CLASS-METHODS screen_0300_pai
      IMPORTING
        !iv_ucomm TYPE sy-ucomm .

  PRIVATE SECTION.

    CLASS-DATA ms_snapshot       TYPE zcl_hr_bank_types=>ty_bank_snapshot .
    CLASS-DATA mt_alv            TYPE zcl_hr_bank_types=>tt_alv_grid .
    CLASS-DATA mv_must_refresh   TYPE abap_bool VALUE abap_true .
    CLASS-DATA mv_pernr          TYPE zcl_hr_bank_types=>ty_pernr .

    CLASS-DATA mo_container      TYPE REF TO cl_gui_custom_container .
    CLASS-DATA mo_grid           TYPE REF TO cl_gui_alv_grid .

    CLASS-METHODS resolve_personnel RAISING zcx_hr_bank .
    CLASS-METHODS reload_snapshot_from_db .
    CLASS-METHODS rebuild_alv_buffer .
    CLASS-METHODS ensure_alv_created .
    CLASS-METHODS refresh_alv_display .
    CLASS-METHODS build_fieldcatalog
      CHANGING
        !ct_fcat TYPE lvc_t_fcat .
    CLASS-METHODS fill_bank_listbox_vrm .
    CLASS-METHODS display_exception
      IMPORTING
        !ix TYPE REF TO zcx_hr_bank .

ENDCLASS.


CLASS zcl_hr_bank_ui IMPLEMENTATION.

  METHOD screen_0100_pbo.

    SET PF-STATUS 'ZHRF_MAIN'.
    SET TITLEBAR 'ZHRF_MAIN'.

    TRY.
        resolve_personnel( ).
      CATCH zcx_hr_bank INTO DATA(lx_ctx).
        display_exception( lx_ctx ).
        RETURN.
    ENDTRY.

    IF mv_must_refresh = abap_true.
      reload_snapshot_from_db( ).
      mv_must_refresh = abap_false.
    ENDIF.

    ensure_alv_created( ).
    refresh_alv_display( ).

  ENDMETHOD.


  METHOD screen_0100_pai.

    CASE iv_ucomm.
      WHEN 'CHNG'.
        on_before_change_popup(
          CHANGING
            cv_bankl = cv_bankl
            cv_bankn = cv_bankn ).
        CALL SCREEN 0200 STARTING AT 10 10 ENDING AT 70 22.

      WHEN 'DEL'.
        IF ms_snapshot-has_record = abap_false.
          MESSAGE |There is no salary bank row to delete.| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
        CALL SCREEN 0300 STARTING AT 15 12 ENDING AT 65 18.

      WHEN 'BACK' OR 'EXIT'.
        LEAVE PROGRAM.

      WHEN OTHERS.

    ENDCASE.

  ENDMETHOD.


  METHOD screen_0200_pbo.

    SET PF-STATUS 'ZHRF_POP_CH'.
    SET TITLEBAR 'ZHRF_POP_CH'.

    fill_bank_listbox_vrm( ).

  ENDMETHOD.


  METHOD screen_0200_pai.

    CASE iv_ucomm.
      WHEN 'SAVE'.

        TRY.
            zcl_hr_bank_service=>change_salary_bank(
              iv_pernr     = mv_pernr
              iv_bank_code = iv_bank_code
              iv_bankn     = iv_bankn ).

            mv_must_refresh = abap_true.
            LEAVE TO SCREEN 0.

          CATCH zcx_hr_bank INTO DATA(lx_save).
            display_exception( lx_save ).
        ENDTRY.

      WHEN 'CANC'.
        LEAVE TO SCREEN 0.

      WHEN OTHERS.

    ENDCASE.

  ENDMETHOD.


  METHOD screen_0300_pbo.

    SET PF-STATUS 'ZHRF_POP_DL'.
    SET TITLEBAR 'ZHRF_POP_DL'.

  ENDMETHOD.


  METHOD screen_0300_pai.

    CASE iv_ucomm.
      WHEN 'YES'.

        TRY.
            zcl_hr_bank_service=>delete_salary_bank(
              iv_pernr     = mv_pernr
              is_snapshot = ms_snapshot ).

            mv_must_refresh = abap_true.
            LEAVE TO SCREEN 0.

          CATCH zcx_hr_bank INTO DATA(lx_del).
            display_exception( lx_del ).
        ENDTRY.

      WHEN 'CANC'.
        LEAVE TO SCREEN 0.

      WHEN OTHERS.

    ENDCASE.

  ENDMETHOD.


  METHOD resolve_personnel.

    mv_pernr = zcl_hr_bank_context=>get_personnel_number( ).

  ENDMETHOD.


  METHOD reload_snapshot_from_db.

    DATA(lo_repo) = zcl_hr_bank_repository=>factory( ).

    ms_snapshot = lo_repo->read_active_salary_snapshot( mv_pernr ).
    rebuild_alv_buffer( ).

  ENDMETHOD.


  METHOD rebuild_alv_buffer.

    CLEAR mt_alv.

    IF ms_snapshot-has_record = abap_true.
      APPEND VALUE #(
        bank_name = ms_snapshot-bank_name
        bankn     = ms_snapshot-bankn ) TO mt_alv.
    ELSE.
      APPEND VALUE #(
        bank_name = space
        bankn     = space ) TO mt_alv.
    ENDIF.

  ENDMETHOD.


  METHOD ensure_alv_created.

    IF mo_container IS NOT INITIAL.
      RETURN.
    ENDIF.

    CREATE OBJECT mo_container
      EXPORTING
        container_name = 'CC_MAIN'.

    CREATE OBJECT mo_grid
      EXPORTING
        i_parent = mo_container.

    DATA lt_fcat TYPE lvc_t_fcat.
    build_fieldcatalog( CHANGING ct_fcat = lt_fcat ).

    CALL METHOD mo_grid->set_table_for_first_display
      EXPORTING
        i_buffer_active               = abap_false
      CHANGING
        it_outtab                     = mt_alv
        it_fieldcatalog               = lt_fcat.

  ENDMETHOD.


  METHOD refresh_alv_display.

    CHECK mo_grid IS NOT INITIAL.

    DATA ls_stable TYPE lvc_s_stbl.
    ls_stable-row = abap_true.
    ls_stable-col = abap_true.

    mo_grid->refresh_table_display(
      EXPORTING
        is_stable = ls_stable ).

  ENDMETHOD.


  METHOD build_fieldcatalog.

    DATA ls_fcat TYPE lvc_s_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BANK_NAME'.
    ls_fcat-coltext   = 'Bank'.
    ls_fcat-outputlen = 40.
    APPEND ls_fcat TO ct_fcat.

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'BANKN'.
    ls_fcat-coltext   = 'Account number'.
    ls_fcat-outputlen = 30.
    APPEND ls_fcat TO ct_fcat.

  ENDMETHOD.


  METHOD fill_bank_listbox_vrm.

    DATA(lo_repo) = zcl_hr_bank_repository=>factory( ).
    DATA(lt_codes) = lo_repo->read_bank_codes( ).

    DATA lt_values TYPE vrm_values.
    CLEAR lt_values.

    LOOP AT lt_codes INTO DATA(ls).
      APPEND VALUE #(
        key = ls-zcode
        text = ls-zcode_text1 ) TO lt_values.
    ENDLOOP.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = 'GV_CH_BANKL'
        values = lt_values.

  ENDMETHOD.


  METHOD on_before_change_popup.

    cv_bankl = CONV #( ms_snapshot-bankl ).
    cv_bankn = ms_snapshot-bankn.

  ENDMETHOD.


  METHOD display_exception.

    MESSAGE ix->mv_text TYPE 'E'.

  ENDMETHOD.

ENDCLASS.
