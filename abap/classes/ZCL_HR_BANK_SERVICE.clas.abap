CLASS zcl_hr_bank_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_account_row,
        pernr      TYPE pernr_d,
        banktext   TYPE zthr0021-zcode_text1,
        bankcode   TYPE pa0009-bankl,
        bankno     TYPE pa0009-bankn,
        subty      TYPE pa0009-subty,
        begda      TYPE pa0009-begda,
        endda      TYPE pa0009-endda,
      END OF ty_account_row,
      tt_account_row TYPE STANDARD TABLE OF ty_account_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_bank_option,
        bankcode TYPE zthr0021-zcode,
        banktext TYPE zthr0021-zcode_text1,
      END OF ty_bank_option,
      tt_bank_option TYPE STANDARD TABLE OF ty_bank_option WITH EMPTY KEY.

    CLASS-METHODS get_current_salary_account
      IMPORTING
        iv_uname         TYPE syuname OPTIONAL
      RETURNING
        VALUE(rt_result) TYPE tt_account_row
      RAISING
        zcx_hr_bank_account.

    CLASS-METHODS get_bank_options
      RETURNING
        VALUE(rt_result) TYPE tt_bank_option.

    CLASS-METHODS change_salary_account
      IMPORTING
        iv_uname TYPE syuname OPTIONAL
        iv_bankl TYPE pa0009-bankl
        iv_bankn TYPE pa0009-bankn
      RAISING
        zcx_hr_bank_account.

    CLASS-METHODS delete_salary_account
      IMPORTING
        iv_uname TYPE syuname OPTIONAL
      RAISING
        zcx_hr_bank_account.

    CLASS-METHODS get_current_salary_account_row
      IMPORTING
        iv_uname      TYPE syuname OPTIONAL
      RETURNING
        VALUE(rs_row) TYPE ty_account_row
      RAISING
        zcx_hr_bank_account.

  PRIVATE SECTION.
    CLASS-METHODS get_user_pernr
      IMPORTING
        iv_uname        TYPE syuname OPTIONAL
      RETURNING
        VALUE(rv_pernr) TYPE pernr_d
      RAISING
        zcx_hr_bank_account.
ENDCLASS.

CLASS zcl_hr_bank_service IMPLEMENTATION.
  METHOD get_user_pernr.
    DATA lv_uname TYPE syuname.

    lv_uname = COND #( WHEN iv_uname IS INITIAL THEN sy-uname ELSE iv_uname ).

    " Map current user to active personnel number.
    SELECT SINGLE pernr
      FROM pa0105
      WHERE usrid = @lv_uname
        AND usrty = '0001'
        AND begda <= @sy-datum
        AND endda >= @sy-datum
      INTO @rv_pernr.

    IF rv_pernr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_hr_bank_account
        EXPORTING
          iv_text = |No active PERNR for user { lv_uname }|.
    ENDIF.
  ENDMETHOD.

  METHOD get_current_salary_account.
    DATA lv_pernr TYPE pernr_d.
    DATA ls_row   TYPE ty_account_row.

    lv_pernr = get_user_pernr( iv_uname = iv_uname ).
    CLEAR ls_row.

    " Query active salary account (SUBTY = 0) at current date.
    SELECT SINGLE
      pernr,
      subty,
      begda,
      endda,
      bankl AS bankcode,
      bankn AS bankno
      FROM pa0009
      WHERE pernr = @lv_pernr
        AND subty = @zif_hr_bank_constants=>gc_subty_salary
        AND begda <= @sy-datum
        AND endda >= @sy-datum
      INTO CORRESPONDING FIELDS OF @ls_row.

    ls_row-pernr = lv_pernr.

    IF ls_row-bankcode IS NOT INITIAL.
      " Resolve bank display text from custom code table.
      SELECT SINGLE
        zcode_text1
        FROM zthr0021
        WHERE bukrs      = @zif_hr_bank_constants=>gc_bukrs
          AND zcode_grup = @zif_hr_bank_constants=>gc_code_group
          AND zcode      = @ls_row-bankcode
          AND begda     <= @sy-datum
          AND endda     >= @sy-datum
        INTO @ls_row-banktext.
    ENDIF.

    APPEND ls_row TO rt_result.
  ENDMETHOD.

  METHOD get_bank_options.
    " All valid bank options for listbox/value help.
    SELECT
      zcode       AS bankcode,
      zcode_text1 AS banktext
      FROM zthr0021
      WHERE bukrs      = @zif_hr_bank_constants=>gc_bukrs
        AND zcode_grup = @zif_hr_bank_constants=>gc_code_group
        AND begda     <= @sy-datum
        AND endda     >= @sy-datum
      ORDER BY zcode
      INTO TABLE @rt_result.
  ENDMETHOD.

  METHOD change_salary_account.
    DATA lv_pernr TYPE pernr_d.
    DATA ls_p0009 TYPE p0009.

    lv_pernr = get_user_pernr( iv_uname = iv_uname ).

    ls_p0009-pernr = lv_pernr.
    ls_p0009-infty = zif_hr_bank_constants=>gc_infty_0009.
    ls_p0009-subty = zif_hr_bank_constants=>gc_subty_salary.
    ls_p0009-begda = sy-datum.
    ls_p0009-endda = '99991231'.
    ls_p0009-banks = zif_hr_bank_constants=>gc_country_kr.
    ls_p0009-bankl = iv_bankl.
    ls_p0009-bankn = iv_bankn.

    " Standard HR write API for infotype 0009.
    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = zif_hr_bank_constants=>gc_infty_0009
        number        = lv_pernr
        subtype       = zif_hr_bank_constants=>gc_subty_salary
        validitybegin = sy-datum
        validityend   = '99991231'
        record        = ls_p0009
        operation     = 'MOD'
      EXCEPTIONS
        OTHERS        = 1.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_hr_bank_account
        EXPORTING
          iv_text = |HR_INFOTYPE_OPERATION MOD failed for PERNR { lv_pernr }|.
    ENDIF.
  ENDMETHOD.

  METHOD delete_salary_account.
    DATA lv_pernr TYPE pernr_d.
    DATA lt_curr  TYPE tt_account_row.
    DATA ls_curr  TYPE ty_account_row.
    DATA ls_p0009 TYPE p0009.

    lv_pernr = get_user_pernr( iv_uname = iv_uname ).
    lt_curr = get_current_salary_account( iv_uname = iv_uname ).
    READ TABLE lt_curr INTO ls_curr INDEX 1.

    IF sy-subrc <> 0 OR ls_curr-bankno IS INITIAL.
      RETURN.
    ENDIF.

    IF ls_curr-begda <> sy-datum.
      RAISE EXCEPTION TYPE zcx_hr_bank_account
        EXPORTING
          iv_text = |Delete allowed only when BEGDA = today|.
    ENDIF.

    ls_p0009-pernr = lv_pernr.
    ls_p0009-infty = zif_hr_bank_constants=>gc_infty_0009.
    ls_p0009-subty = ls_curr-subty.
    ls_p0009-begda = ls_curr-begda.
    ls_p0009-endda = ls_curr-endda.
    ls_p0009-bankl = ls_curr-bankcode.
    ls_p0009-bankn = ls_curr-bankno.

    " Standard HR delete API for infotype 0009.
    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = zif_hr_bank_constants=>gc_infty_0009
        number        = lv_pernr
        subtype       = ls_curr-subty
        validitybegin = ls_curr-begda
        validityend   = ls_curr-endda
        record        = ls_p0009
        operation     = 'DEL'
      EXCEPTIONS
        OTHERS        = 1.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_hr_bank_account
        EXPORTING
          iv_text = |HR_INFOTYPE_OPERATION DEL failed for PERNR { lv_pernr }|.
    ENDIF.
  ENDMETHOD.

  METHOD get_current_salary_account_row.
    DATA lt_result TYPE tt_account_row.

    lt_result = get_current_salary_account( iv_uname = iv_uname ).
    READ TABLE lt_result INTO rs_row INDEX 1.
  ENDMETHOD.
ENDCLASS.
