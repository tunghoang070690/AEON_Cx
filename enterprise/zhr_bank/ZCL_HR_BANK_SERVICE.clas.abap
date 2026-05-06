*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_SERVICE
*&---------------------------------------------------------------------*
*& Application service orchestrating validation, repository reads and HR gateway.
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS change_salary_bank
      IMPORTING
        !iv_pernr     TYPE zcl_hr_bank_types=>ty_pernr
        !iv_bank_code TYPE zthr0021-zcode
        !iv_bankn     TYPE zcl_hr_bank_types=>ty_bankn
      RAISING
        zcx_hr_bank .

    CLASS-METHODS delete_salary_bank
      IMPORTING
        !iv_pernr TYPE zcl_hr_bank_types=>ty_pernr
        !is_snapshot TYPE zcl_hr_bank_types=>ty_bank_snapshot
      RAISING
        zcx_hr_bank .

ENDCLASS.


CLASS zcl_hr_bank_service IMPLEMENTATION.

  METHOD change_salary_bank.

    zcl_hr_bank_validator=>validate_change_input(
      iv_bank_code = iv_bank_code
      iv_bankn     = iv_bankn ).

    zcl_hr_bank_gateway=>modify_salary_bank(
      iv_pernr = iv_pernr
      iv_bankl = CONV #( iv_bank_code )
      iv_bankn = iv_bankn ).

  ENDMETHOD.


  METHOD delete_salary_bank.

    zcl_hr_bank_validator=>validate_delete_eligibility( iv_begda = is_snapshot-begda ).

    DATA(lo_repo) = zcl_hr_bank_repository=>factory( ).

    DATA(ls_p0009) = lo_repo->read_pa0009_record(
        iv_pernr = iv_pernr
        iv_subty = is_snapshot-subty
        iv_begda = is_snapshot-begda
        iv_endda = is_snapshot-endda ).

    IF ls_p0009-pernr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_hr_bank
        EXPORTING
          iv_code = zcx_hr_bank=>gc_codes-validation_fail
          iv_text = |Bank row could not be read for deletion.|.
    ENDIF.

    zcl_hr_bank_gateway=>delete_bank_record(
      iv_pernr = iv_pernr
      is_p0009 = ls_p0009 ).

  ENDMETHOD.

ENDCLASS.
