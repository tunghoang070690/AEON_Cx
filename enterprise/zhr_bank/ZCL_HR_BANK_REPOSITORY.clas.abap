*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_REPOSITORY
*&---------------------------------------------------------------------*
*& Encapsulates database reads for PA0009 and ZTHR0021 (no updates).
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_repository DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_hr_bank_repository.

    CLASS-METHODS factory
      RETURNING
        VALUE(ro_repo) TYPE REF TO zif_hr_bank_repository .

ENDCLASS.


CLASS zcl_hr_bank_repository IMPLEMENTATION.

  METHOD factory.
    CREATE OBJECT ro_repo TYPE zcl_hr_bank_repository.
  ENDMETHOD.


  METHOD zif_hr_bank_repository~read_active_salary_snapshot.

    CLEAR rs_snapshot.

    SELECT SINGLE FROM pa0009 AS pa
      FIELDS pa~pernr,
             pa~subty,
             pa~begda,
             pa~endda,
             pa~bankl,
             pa~bankn
      WHERE pa~pernr = @iv_pernr
        AND pa~infty = @zcl_hr_bank_types=>mc_infty
        AND pa~subty = @zcl_hr_bank_types=>mc_subty_salary
        AND pa~begda <= @sy-datum
        AND pa~endda >= @sy-datum
      INTO @DATA(ls_pa).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rs_snapshot-has_record = abap_true.
    rs_snapshot-pernr      = ls_pa-pernr.
    rs_snapshot-subty      = ls_pa-subty.
    rs_snapshot-begda      = ls_pa-begda.
    rs_snapshot-endda      = ls_pa-endda.
    rs_snapshot-bankl      = ls_pa-bankl.
    rs_snapshot-bankn      = ls_pa-bankn.

    SELECT SINGLE zthr0021~zcode_text1
      FROM zthr0021
      WHERE bukrs       = @zcl_hr_bank_types=>mc_bukrs
        AND zcode_grup = @zcl_hr_bank_types=>mc_code_group
        AND zcode      = @ls_pa-bankl
        AND begda      <= @sy-datum
        AND endda      >= @sy-datum
      INTO @rs_snapshot-bank_name.

  ENDMETHOD.


  METHOD zif_hr_bank_repository~read_bank_codes.

    SELECT FROM zthr0021
      FIELDS zcode, zcode_text1
      WHERE bukrs       = @zcl_hr_bank_types=>mc_bukrs
        AND zcode_grup = @zcl_hr_bank_types=>mc_code_group
        AND begda      <= @sy-datum
        AND endda      >= @sy-datum
      ORDER BY zcode_text1
      INTO CORRESPONDING FIELDS OF TABLE @rt_codes.

  ENDMETHOD.


  METHOD zif_hr_bank_repository~read_pa0009_record.

    DATA ls_db TYPE pa0009.

    CLEAR rs_record.

    SELECT SINGLE * FROM pa0009
      WHERE pernr = @iv_pernr
        AND infty = @zcl_hr_bank_types=>mc_infty
        AND subty = @iv_subty
        AND begda = @iv_begda
        AND endda = @iv_endda
      INTO CORRESPONDING FIELDS OF @ls_db.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    MOVE-CORRESPONDING ls_db TO rs_record.

  ENDMETHOD.

ENDCLASS.
