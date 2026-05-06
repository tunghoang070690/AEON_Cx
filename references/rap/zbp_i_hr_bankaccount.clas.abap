*&---------------------------------------------------------------------*
*& Class ZBP_I_HR_BANKACCOUNT
*&---------------------------------------------------------------------*
*& RAP behavior pool / saver for ZI_HR_BankAccount.
*& Delegates persistence side-effects to ZCL_HR_BANK_INFOTYPE so that
*& OData and SAP GUI share identical HR_INFOTYPE_OPERATION semantics.
*&---------------------------------------------------------------------*
CLASS zbp_i_hr_bankaccount DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_hr_bankaccount.
ENDCLASS.

CLASS zbp_i_hr_bankaccount IMPLEMENTATION.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Local types / saver (paste into ZBP_I_HR_BANKACCOUNT local types/impl)
*&---------------------------------------------------------------------*
* CLASS lhc_bankaccount DEFINITION INHERITING FROM cl_abap_behavior_handler.
*   PRIVATE SECTION.
*     METHODS validatebankcode FOR VALIDATE ON SAVE IMPORTING keys FOR BankAccount~validatebankcode.
*     METHODS setdefaults    FOR DETERMINE ON MODIFY IMPORTING keys FOR BankAccount~setdefaults.
*     METHODS save_modified  FOR MODIFY IMPORTING keys FOR BankAccount.
* ENDCLASS.
*
* METHOD lhc_bankaccount~setdefaults.
*   " READ ENTITIES OF zi_hr_bankaccount IN LOCAL MODE ...
*   " MODIFY ENTITIES OF zi_hr_bankaccount IN LOCAL MODE ENTITY BankAccount SET FIELDS ( BankCountry ) WITH VALUE 'KR' ...
* ENDMETHOD.
*
* METHOD lhc_bankaccount~validatebankcode.
*   " Ensure BankKey exists in ZTHR0021 for BUKRS 1000 / A004 / sy-datum.
* ENDMETHOD.
*
* METHOD lhc_bankaccount~save_modified.
*   " For updated: map to P0009, call ZCL_HR_BANK_INFOTYPE=>modify_salary_bank.
*   " For deleted: call delete_bank_record.
*   " Map failures to failed / reported.
* ENDMETHOD.
