CLASS zbp_i_hr_bank_account DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_behavior_handler.
ENDCLASS.

CLASS lhc_account DEFINITION INHERITING FROM cl_abap_behavior_handler FINAL.
  PRIVATE SECTION.
    METHODS changeaccount FOR MODIFY
      IMPORTING keys FOR ACTION zi_hr_bank_account~changeaccount RESULT result.

    METHODS deleteaccount FOR MODIFY
      IMPORTING keys FOR ACTION zi_hr_bank_account~deleteaccount RESULT result.
ENDCLASS.

CLASS zbp_i_hr_bank_account IMPLEMENTATION.
ENDCLASS.

CLASS lhc_account IMPLEMENTATION.
  METHOD changeaccount.
    TRY.
        LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
          zcl_hr_bank_service=>change_salary_account(
            iv_bankl = <ls_key>-%param-bankcode
            iv_bankn = <ls_key>-%param-bankno ).

          APPEND VALUE #( %tky = <ls_key>-%tky ) TO result.
        ENDLOOP.
      CATCH zcx_hr_bank_account INTO DATA(lx_error).
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lx_error->mv_text ) )
          TO reported-zi_hr_bank_account.
    ENDTRY.
  ENDMETHOD.

  METHOD deleteaccount.
    TRY.
        zcl_hr_bank_service=>delete_salary_account( ).

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
          APPEND VALUE #( %tky = <ls_key>-%tky ) TO result.
        ENDLOOP.
      CATCH zcx_hr_bank_account INTO DATA(lx_error).
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lx_error->mv_text ) )
          TO reported-zi_hr_bank_account.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
