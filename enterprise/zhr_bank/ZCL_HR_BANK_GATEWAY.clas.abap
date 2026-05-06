*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_GATEWAY
*&---------------------------------------------------------------------*
*& Clean-core HR boundary: all PA infotype writes via HR_INFOTYPE_OPERATION.
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_gateway DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS modify_salary_bank
      IMPORTING
        !iv_pernr TYPE zcl_hr_bank_types=>ty_pernr
        !iv_bankl TYPE bankk
        !iv_bankn TYPE zcl_hr_bank_types=>ty_bankn
      RAISING
        zcx_hr_bank .

    CLASS-METHODS delete_bank_record
      IMPORTING
        !iv_pernr TYPE zcl_hr_bank_types=>ty_pernr
        !is_p0009 TYPE p0009
      RAISING
        zcx_hr_bank .

  PRIVATE SECTION.

    CLASS-METHODS call_hr_infotype_operation
      IMPORTING
        !iv_operation       TYPE pspar-operation
        !iv_pernr           TYPE zcl_hr_bank_types=>ty_pernr
        !iv_subty           TYPE zcl_hr_bank_types=>ty_subty
        !iv_validity_begin  TYPE zcl_hr_bank_types=>ty_begda
        !iv_validity_end    TYPE zcl_hr_bank_types=>ty_endda
        !is_record          TYPE p0009
      RAISING
        zcx_hr_bank .

ENDCLASS.


CLASS zcl_hr_bank_gateway IMPLEMENTATION.

  METHOD modify_salary_bank.

    DATA ls_p0009 TYPE p0009.

    ls_p0009-pernr = iv_pernr.
    ls_p0009-infty = zcl_hr_bank_types=>mc_infty.
    ls_p0009-subty = zcl_hr_bank_types=>mc_subty_salary.
    ls_p0009-endda = zcl_hr_bank_types=>mc_endda_high.
    ls_p0009-begda = sy-datum.
    ls_p0009-banks = zcl_hr_bank_types=>mc_banks.
    ls_p0009-bankl = iv_bankl.
    ls_p0009-bankn = iv_bankn.

    " Mirror customer-include fields on P0009 if present (activate when CI exists).
    " ASSIGN COMPONENT 'ZBANKL' OF STRUCTURE ls_p0009 TO FIELD-SYMBOL(<zb>).
    " IF sy-subrc = 0. <zb> = iv_bankl. ENDIF.

    call_hr_infotype_operation(
      iv_operation      = 'MOD'
      iv_pernr          = iv_pernr
      iv_subty          = zcl_hr_bank_types=>mc_subty_salary
      iv_validity_begin = sy-datum
      iv_validity_end   = zcl_hr_bank_types=>mc_endda_high
      is_record         = ls_p0009 ).

  ENDMETHOD.


  METHOD delete_bank_record.

    call_hr_infotype_operation(
      iv_operation      = 'DEL'
      iv_pernr          = iv_pernr
      iv_subty          = is_p0009-subty
      iv_validity_begin = is_p0009-begda
      iv_validity_end   = is_p0009-endda
      is_record         = is_p0009 ).

  ENDMETHOD.


  METHOD call_hr_infotype_operation.

    DATA ls_return TYPE bapireturn1.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty           = zcl_hr_bank_types=>mc_infty
        number          = iv_pernr
        subtype         = iv_subty
        validitybegin   = iv_validity_begin
        validityend     = iv_validity_end
        record          = is_record
        operation       = iv_operation
      IMPORTING
        return          = ls_return
      EXCEPTIONS
        OTHERS          = 1.

    IF sy-subrc <> 0 OR ( ls_return-type IS NOT INITIAL AND ls_return-type CA 'EA' ).
      RAISE EXCEPTION TYPE zcx_hr_bank
        EXPORTING
          iv_code = zcx_hr_bank=>gc_codes-hr_operation
          iv_text = |HR_INFOTYPE_OPERATION failed ({ iv_operation })|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
