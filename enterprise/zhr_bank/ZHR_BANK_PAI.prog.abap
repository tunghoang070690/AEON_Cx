*&---------------------------------------------------------------------*
*& Include ZHR_BANK_PAI  (Input modules — delegate only)
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.
  zcl_hr_bank_ui=>screen_0100_pai(
    iv_ucomm = ok_code
    CHANGING
      cv_bankl = gv_ch_bankl
      cv_bankn = gv_ch_bankn ).
  CLEAR ok_code.
ENDMODULE.


MODULE user_command_0200 INPUT.
  zcl_hr_bank_ui=>screen_0200_pai(
    iv_ucomm     = ok_code
    iv_bank_code = gv_ch_bankl
    iv_bankn     = gv_ch_bankn ).
  CLEAR ok_code.
ENDMODULE.


MODULE user_command_0300 INPUT.
  zcl_hr_bank_ui=>screen_0300_pai( ok_code ).
  CLEAR ok_code.
ENDMODULE.
