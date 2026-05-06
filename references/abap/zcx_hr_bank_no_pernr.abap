*&---------------------------------------------------------------------*
*& Exception ZCX_HR_BANK_NO_PERNR
*&---------------------------------------------------------------------*
CLASS zcx_hr_bank_no_pernr DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL.

ENDCLASS.

CLASS zcx_hr_bank_no_pernr IMPLEMENTATION.
  METHOD constructor.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    if_t100_message~t100key = if_t100_message=>default_textid.
  ENDMETHOD.
ENDCLASS.
