*&---------------------------------------------------------------------*
*& Interface ZIF_HR_BANK_REPOSITORY
*&---------------------------------------------------------------------*
*& Centralizes table reads (single source for SELECT).
*&---------------------------------------------------------------------*
INTERFACE zif_hr_bank_repository PUBLIC .

  METHODS read_active_salary_snapshot
    IMPORTING
      !iv_pernr TYPE zcl_hr_bank_types=>ty_pernr
    RETURNING
      VALUE(rs_snapshot) TYPE zcl_hr_bank_types=>ty_bank_snapshot .

  METHODS read_bank_codes
    RETURNING
      VALUE(rt_codes) TYPE zcl_hr_bank_types=>tt_bank_code .

  METHODS read_pa0009_record
    IMPORTING
      !iv_pernr TYPE zcl_hr_bank_types=>ty_pernr
      !iv_subty TYPE zcl_hr_bank_types=>ty_subty
      !iv_begda TYPE zcl_hr_bank_types=>ty_begda
      !iv_endda TYPE zcl_hr_bank_types=>ty_endda
    RETURNING
      VALUE(rs_record) TYPE p0009 .

ENDINTERFACE.
