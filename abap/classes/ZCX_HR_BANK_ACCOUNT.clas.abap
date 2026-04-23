CLASS zcx_hr_bank_account DEFINITION
  PUBLIC
  FINAL
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_text  TYPE string
        previous TYPE REF TO cx_root OPTIONAL.
ENDCLASS.

CLASS zcx_hr_bank_account IMPLEMENTATION.
  METHOD constructor.
    super->constructor( previous = previous ).
    mv_text = iv_text.
  ENDMETHOD.
ENDCLASS.
