*&---------------------------------------------------------------------*
*& Class ZCX_HR_BANK
*&---------------------------------------------------------------------*
CLASS zcx_hr_bank DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF gc_codes,
        no_personnel    TYPE string VALUE `NO_PERSONNEL`,
        validation_fail TYPE string VALUE `VALIDATION`,
        hr_operation    TYPE string VALUE `HR_OPERATION`,
      END OF gc_codes.

    DATA mv_code TYPE string READ-ONLY.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        !iv_text TYPE string OPTIONAL
        !iv_code TYPE string OPTIONAL
        !previous LIKE previous OPTIONAL.

ENDCLASS.


CLASS zcx_hr_bank IMPLEMENTATION.

  METHOD constructor.
    super->constructor( previous = previous ).
    mv_text = iv_text.
    mv_code = iv_code.
    CLEAR textid.
    if_t100_message~t100key = if_t100_message=>default_textid.
  ENDMETHOD.

ENDCLASS.
