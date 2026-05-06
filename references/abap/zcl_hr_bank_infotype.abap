*&---------------------------------------------------------------------*
*& Class ZCL_HR_BANK_INFOTYPE
*&---------------------------------------------------------------------*
*& Purpose: Single gateway for PA infotype 0009 (subtype 0) changes
*&          using HR_INFOTYPE_OPERATION (shared by GUI and RAP saver).
*& Clean Core: No SAP standard modification; encapsulate HR API here.
*&---------------------------------------------------------------------*
CLASS zcl_hr_bank_infotype DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS mc_infty TYPE infty VALUE '0009'.
    CONSTANTS mc_subty TYPE subty VALUE '0'.
    CONSTANTS mc_banks TYPE banks VALUE 'KR'.
    CONSTANTS mc_endda TYPE endda VALUE '99991231'.

    "! Modify or create salary bank record (MOD per functional spec).
    CLASS-METHODS modify_salary_bank
      IMPORTING
        !iv_pernr TYPE pernr_d
        !iv_bankl TYPE bankk
        !iv_bankn TYPE bankn
      EXPORTING
        !ev_subrc TYPE sysubrc
        !et_return TYPE bapiret2_t
      RAISING
        zcx_hr_bank_infotype.

    "! Delete bank record for given validity (use displayed BEGDA/ENDDA).
    CLASS-METHODS delete_bank_record
      IMPORTING
        !iv_pernr TYPE pernr_d
        !is_p0009 TYPE p0009
      EXPORTING
        !ev_subrc TYPE sysubrc
        !et_return TYPE bapiret2_t
      RAISING
        zcx_hr_bank_infotype.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS call_hr_infotype_operation
      IMPORTING
        !iv_operation       TYPE pspar-operation
        !iv_pernr           TYPE pernr_d
        !iv_subty           TYPE subty
        !iv_validity_begin  TYPE begda
        !iv_validity_end    TYPE endda
        !is_record          TYPE p0009
      EXPORTING
        !ev_subrc           TYPE sysubrc
        !et_return          TYPE bapiret2_t.

    CLASS-METHODS append_message
      IMPORTING
        !iv_type       TYPE bapi_mtype
        !iv_id         TYPE symsgid
        !iv_number     TYPE symsgno
        !iv_message_v1 TYPE symsgv OPTIONAL
        !iv_message_v2 TYPE symsgv OPTIONAL
        !iv_message_v3 TYPE symsgv OPTIONAL
        !iv_message_v4 TYPE symsgv OPTIONAL
      CHANGING
        !ct_return     TYPE bapiret2_t.

ENDCLASS.


CLASS zcl_hr_bank_infotype IMPLEMENTATION.

  METHOD modify_salary_bank.

    DATA ls_p0009 TYPE p0009.

    CLEAR: ev_subrc, et_return.

    " Build P0009 per specification (adjust if CI fields must be filled).
    ls_p0009-pernr = iv_pernr.
    ls_p0009-infty = mc_infty.
    ls_p0009-subty = mc_subty.
    ls_p0009-endda = mc_endda.
    ls_p0009-begda = sy-datum.
    ls_p0009-banks = mc_banks.
    ls_p0009-bankl = iv_bankl.
    ls_p0009-bankn = iv_bankn.

    call_hr_infotype_operation(
      EXPORTING
        iv_operation      = 'MOD'
        iv_pernr          = iv_pernr
        iv_subty          = mc_subty
        iv_validity_begin = sy-datum
        iv_validity_end   = mc_endda
        is_record         = ls_p0009
      IMPORTING
        ev_subrc          = ev_subrc
        et_return         = et_return ).

    IF ev_subrc <> 0.
      RAISE EXCEPTION TYPE zcx_hr_bank_infotype
        EXPORTING
          mt_return = et_return.
    ENDIF.

  ENDMETHOD.


  METHOD delete_bank_record.

    CLEAR: ev_subrc, et_return.

    " Use screen data directly as specified (BEGDA/ENDDA/SUBTY on record).
    call_hr_infotype_operation(
      EXPORTING
        iv_operation      = 'DEL'
        iv_pernr          = iv_pernr
        iv_subty          = is_p0009-subty
        iv_validity_begin = is_p0009-begda
        iv_validity_end   = is_p0009-endda
        is_record         = is_p0009
      IMPORTING
        ev_subrc          = ev_subrc
        et_return         = et_return ).

    IF ev_subrc <> 0.
      RAISE EXCEPTION TYPE zcx_hr_bank_infotype
        EXPORTING
          mt_return = et_return.
    ENDIF.

  ENDMETHOD.


  METHOD call_hr_infotype_operation.

    DATA lv_subrc TYPE sysubrc.

    CLEAR: ev_subrc, et_return.

    DATA ls_return TYPE bapireturn1.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty           = mc_infty
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

    lv_subrc = sy-subrc.

    " Map classic return to BAPIRET2 table for unified UI/RAP handling.
    IF ls_return IS NOT INITIAL.
      append_message(
        EXPORTING
          iv_type       = ls_return-type
          iv_id         = ls_return-id
          iv_number     = ls_return-number
          iv_message_v1 = ls_return-message_v1
          iv_message_v2 = ls_return-message_v2
          iv_message_v3 = ls_return-message_v3
          iv_message_v4 = ls_return-message_v4
        CHANGING
          ct_return       = et_return ).
    ENDIF.

    IF lv_subrc <> 0 AND et_return IS INITIAL.
      DATA lv_msg TYPE string.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_msg.
      append_message(
        EXPORTING
          iv_type   = 'E'
          iv_id     = sy-msgid
          iv_number = sy-msgno
          iv_message_v1 = sy-msgv1
          iv_message_v2 = sy-msgv2
          iv_message_v3 = sy-msgv3
          iv_message_v4 = sy-msgv4
        CHANGING
          ct_return = et_return ).
    ENDIF.

    ev_subrc = lv_subrc.

  ENDMETHOD.


  METHOD append_message.

    DATA ls_ret TYPE bapiret2.

    ls_ret-type       = iv_type.
    ls_ret-id         = iv_id.
    ls_ret-number     = iv_number.
    ls_ret-message_v1 = iv_message_v1.
    ls_ret-message_v2 = iv_message_v2.
    ls_ret-message_v3 = iv_message_v3.
    ls_ret-message_v4 = iv_message_v4.

    APPEND ls_ret TO ct_return.

  ENDMETHOD.

ENDCLASS.
