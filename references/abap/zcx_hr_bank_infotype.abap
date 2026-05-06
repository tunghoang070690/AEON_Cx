*&---------------------------------------------------------------------*
*& Exception ZCX_HR_BANK_INFOTYPE
*&---------------------------------------------------------------------*
CLASS zcx_hr_bank_infotype DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_t_return TYPE bapiret2_t.

    DATA mt_return TYPE ty_t_return READ-ONLY.

    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !mt_return TYPE ty_t_return OPTIONAL.

ENDCLASS.


CLASS zcx_hr_bank_infotype IMPLEMENTATION.

  METHOD constructor.
    super->constructor( previous = previous ).
    me->mt_return = mt_return.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
