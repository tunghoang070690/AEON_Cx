*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_QUERY
*&---------------------------------------------------------------------*
*& Purpose: Read PA0009 (salary bank) and ZTHR0021 (bank code texts).
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_active_bank_row,
             pernr       TYPE pernr_d,
             subty       TYPE subty,
             begda       TYPE begda,
             endda       TYPE endda,
             bankl       TYPE bankk,
             bankn       TYPE bankn,
             bank_name   TYPE zthr0021-zcode_text1,
           END OF ty_active_bank_row.

    TYPES: BEGIN OF ty_bank_code_line,
             zcode       TYPE zthr0021-zcode,
             zcode_text1 TYPE zthr0021-zcode_text1,
           END OF ty_bank_code_line.
    TYPES ty_t_bank_code TYPE STANDARD TABLE OF ty_bank_code_line WITH EMPTY KEY.

    "! Single current-valid salary account (SUBTY 0) for employee.
    CLASS-METHODS read_active_salary_account
      IMPORTING
        !iv_pernr TYPE pernr_d
      RETURNING
        VALUE(rs_row) TYPE ty_active_bank_row.

    "! Bank list for popup / value help (all valid codes for group A004).
    CLASS-METHODS read_bank_code_list
      RETURNING
        VALUE(rt_rows) TYPE ty_t_bank_code.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS mc_bukrs       TYPE bukrs VALUE '1000'.
    CONSTANTS mc_code_grup TYPE zthr0021-zcode_grup VALUE 'A004'.

ENDCLASS.


CLASS zcl_hr_bank_query IMPLEMENTATION.

  METHOD read_active_salary_account.

    DATA ls_pa0009 TYPE pa0009.

    CLEAR rs_row.

    SELECT SINGLE FROM pa0009
      FIELDS pernr, subty, begda, endda, bankl, bankn
      WHERE pernr = @iv_pernr
        AND subty = @zcl_hr_bank_infotype=>mc_subty
        AND begda <= @sy-datum
        AND endda >= @sy-datum
      INTO CORRESPONDING FIELDS OF @ls_pa0009.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rs_row-pernr = ls_pa0009-pernr.
    rs_row-subty = ls_pa0009-subty.
    rs_row-begda = ls_pa0009-begda.
    rs_row-endda = ls_pa0009-endda.
    rs_row-bankl = ls_pa0009-bankl.
    rs_row-bankn = ls_pa0009-bankn.

    SELECT SINGLE zcode_text1 FROM zthr0021
      WHERE bukrs       = @mc_bukrs
        AND zcode_grup = @mc_code_grup
        AND zcode      = @ls_pa0009-bankl
        AND begda      <= @sy-datum
        AND endda      >= @sy-datum
      INTO @rs_row-bank_name.

  ENDMETHOD.


  METHOD read_bank_code_list.

    SELECT FROM zthr0021
      FIELDS zcode, zcode_text1
      WHERE bukrs       = @mc_bukrs
        AND zcode_grup = @mc_code_grup
        AND begda      <= @sy-datum
        AND endda      >= @sy-datum
      ORDER BY zcode_text1
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.

  ENDMETHOD.

ENDCLASS.
