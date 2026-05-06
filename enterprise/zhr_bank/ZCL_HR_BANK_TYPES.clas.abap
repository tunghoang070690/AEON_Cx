*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_TYPES
*&---------------------------------------------------------------------*
*& DTOs and shared constants (no business logic; no instantiation).
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_types DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_pernr TYPE pernr_d.
    TYPES ty_bankk TYPE bankk.
    TYPES ty_bankn TYPE bankn.
    TYPES ty_subty TYPE subty.
    TYPES ty_begda TYPE begda.
    TYPES ty_endda TYPE endda.

    TYPES: BEGIN OF ty_alv_row,
             bank_name TYPE zthr0021-zcode_text1,
             bankn     TYPE bankn,
           END OF ty_alv_row.
    TYPES tt_alv_grid TYPE STANDARD TABLE OF ty_alv_row WITH EMPTY KEY.

    TYPES: BEGIN OF ty_bank_snapshot,
             has_record TYPE abap_bool,
             pernr      TYPE pernr_d,
             subty      TYPE subty,
             begda      TYPE begda,
             endda      TYPE endda,
             bankl      TYPE bankk,
             bankn      TYPE bankn,
             bank_name  TYPE zthr0021-zcode_text1,
           END OF ty_bank_snapshot.

    TYPES: BEGIN OF ty_bank_code,
             zcode       TYPE zthr0021-zcode,
             zcode_text1 TYPE zthr0021-zcode_text1,
           END OF ty_bank_code.
    TYPES tt_bank_code TYPE STANDARD TABLE OF ty_bank_code WITH EMPTY KEY.

    CONSTANTS:
      mc_bukrs        TYPE bukrs VALUE '1000',
      mc_code_group   TYPE zthr0021-zcode_grup VALUE 'A004',
      mc_infty        TYPE infty VALUE '0009',
      mc_subty_salary TYPE subty VALUE '0',
      mc_banks        TYPE banks VALUE 'KR',
      mc_endda_high   TYPE endda VALUE '99991231'.

ENDCLASS.
CLASS zcl_hr_bank_types IMPLEMENTATION.
ENDCLASS.
