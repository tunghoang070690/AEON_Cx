CLASS zcl_hr_bank_opt_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_hr_bank_opt_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA lt_rows TYPE zcl_hr_bank_service=>tt_bank_option.

    lt_rows = zcl_hr_bank_service=>get_bank_options( ).

    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.

    IF io_request->is_data_requested( ) = abap_true.
      io_response->set_data( lt_rows ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
