*&---------------------------------------------------------------------*
*& Include MZHR_BANKI01
*&---------------------------------------------------------------------*
*& PAI modules — commands, popup lifecycle, HR_INFOTYPE_OPERATION calls.
*& Message texts: create message class ZHR_BANK or replace with literals.
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'CHNG'.
      PERFORM prepare_change_popup_before_call.
      CALL SCREEN 0200 STARTING AT 10 10 ENDING AT 70 22.

    WHEN 'DEL'.
      IF gs_keys-pernr IS INITIAL OR gs_keys-begda IS INITIAL.
        MESSAGE |No active salary bank record is available to delete.| TYPE 'S' DISPLAY LIKE 'E'.
        CLEAR ok_code.
        RETURN.
      ENDIF.
      CALL SCREEN 0300 STARTING AT 15 12 ENDING AT 65 18.

    WHEN 'BACK' OR 'EXIT'.
      LEAVE PROGRAM.

    WHEN OTHERS.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.


MODULE user_command_0200 INPUT.

  CASE ok_code.
    WHEN 'SAVE'.

      TRY.
          zcl_hr_bank_infotype=>modify_salary_bank(
            EXPORTING
              iv_pernr = gv_pernr
              iv_bankl = gv_ch_bankl
              iv_bankn = gv_ch_bankn ).

          gv_main_must_refresh = abap_true.
          LEAVE TO SCREEN 0.

        CATCH zcx_hr_bank_infotype INTO DATA(lx_save).
          PERFORM display_infotype_exception USING lx_save.
      ENDTRY.

    WHEN 'CANC'.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.


MODULE user_command_0300 INPUT.

  CASE ok_code.
    WHEN 'YES'.
      PERFORM execute_delete_from_popup.

    WHEN 'CANC'.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.
