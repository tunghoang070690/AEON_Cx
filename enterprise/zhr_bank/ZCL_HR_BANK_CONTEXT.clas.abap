*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_CONTEXT
*&---------------------------------------------------------------------*
*& Resolves dialog user → personnel number (customer-specific).
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get_personnel_number
      IMPORTING
        !iv_uname TYPE syuname DEFAULT sy-uname
      RETURNING
        VALUE(rv_pernr) TYPE zcl_hr_bank_types=>ty_pernr
      RAISING
        zcx_hr_bank .

ENDCLASS.


CLASS zcl_hr_bank_context IMPLEMENTATION.

  METHOD get_personnel_number.

    CLEAR rv_pernr.

    " Primary: user parameter PER (SU01 / PA03 personnel default).
    GET PARAMETER ID 'PER' FIELD rv_pernr.
    IF rv_pernr IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Customer mapping example (uncomment & replace with your logic).
    " SELECT SINGLE pernr FROM zthr_emp_user WHERE uname = @iv_uname INTO @rv_pernr.

    IF rv_pernr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_hr_bank
        EXPORTING
          iv_code = zcx_hr_bank=>gc_codes-no_personnel
          iv_text = |Personnel number not found for user { iv_uname }.|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
