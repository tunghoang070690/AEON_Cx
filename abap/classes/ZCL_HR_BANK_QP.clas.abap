CLASS zcl_hr_bank_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_hr_bank_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA lt_rows TYPE zcl_hr_bank_service=>tt_account_row.
    DATA ls_row  TYPE zcl_hr_bank_service=>ty_account_row.

    TRY.
        lt_rows = zcl_hr_bank_service=>get_current_salary_account( ).
      CATCH zcx_hr_bank_account.
        CLEAR ls_row.
        APPEND ls_row TO lt_rows.
    ENDTRY.

    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.

    IF io_request->is_data_requested( ) = abap_true.
      io_response->set_data( lt_rows ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
