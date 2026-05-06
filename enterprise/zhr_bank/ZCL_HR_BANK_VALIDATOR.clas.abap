*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_VALIDATOR
*&---------------------------------------------------------------------*
*& Domain validation before HR gateway calls.
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS validate_change_input
      IMPORTING
        !iv_bank_code TYPE zthr0021-zcode
        !iv_bankn     TYPE bankn
      RAISING
        zcx_hr_bank .

    CLASS-METHODS validate_delete_eligibility
      IMPORTING
        !iv_begda TYPE begda
      RAISING
        zcx_hr_bank .

ENDCLASS.


CLASS zcl_hr_bank_validator IMPLEMENTATION.

  METHOD validate_change_input.

    IF iv_bank_code IS INITIAL OR iv_bankn IS INITIAL.
      RAISE EXCEPTION TYPE zcx_hr_bank
        EXPORTING
          iv_code = zcx_hr_bank=>gc_codes-validation_fail
          iv_text = |Bank code and account number are required.|.
    ENDIF.

  ENDMETHOD.


  METHOD validate_delete_eligibility.

    IF iv_begda <> sy-datum.
      RAISE EXCEPTION TYPE zcx_hr_bank
        EXPORTING
          iv_code = zcx_hr_bank=>gc_codes-validation_fail
          iv_text = |Deletion only allowed when record start date equals system date.|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
