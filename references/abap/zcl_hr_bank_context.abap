*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_CONTEXT
*&---------------------------------------------------------------------*
*& Resolves personnel number for the dialog user ("logon user ID").
*& Replace default logic with your ESS mapping (e.g. USR21/PA0105/BAdI).
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Returns personnel number for bank maintenance (never hard-code).
    CLASS-METHODS get_personnel_number_for_user
      IMPORTING
        !iv_uname TYPE syuname DEFAULT sy-uname
      RETURNING
        VALUE(rv_pernr) TYPE pernr_d
      RAISING
        zcx_hr_bank_no_pernr.

ENDCLASS.


CLASS zcl_hr_bank_context IMPLEMENTATION.

  METHOD get_personnel_number_for_user.

    CLEAR rv_pernr.

    " 1) Optional: personnel number from user parameter (SU01 / PA03 defaults).
    GET PARAMETER ID 'PER' FIELD rv_pernr.

    IF rv_pernr IS NOT INITIAL.
      RETURN.
    ENDIF.

    " 2) Customer-specific mapping (example placeholder — implement per landscape).
    " SELECT SINGLE pernr FROM zthr_emp_user WHERE uname = @iv_uname INTO @rv_pernr.

    IF rv_pernr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_hr_bank_no_pernr.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
