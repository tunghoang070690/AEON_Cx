*&---------------------------------------------------------------------*
*& Include LZHR_BANKI01 (example: PBO/PAI modules for SAPMZHR_BANK)
*&---------------------------------------------------------------------*
*& Wire dynpro flow to ZCL_HR_BANK_* classes.
*& Screen 0100: main inquiry; 0200: change popup; 0300: delete confirm.
*& Refresh rule: set gv_refresh_main = abap_true only after successful
*&              MOD/DEL from popup Save/OK. On Cancel/Close, leave false.
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* MODULES pbo_0100 OUTPUT
*----------------------------------------------------------------------*
MODULE pbo_0100 OUTPUT.
  " Example: call ZCL_HR_BANK_GUI_APP=>pbo_main( ).
ENDMODULE.

*----------------------------------------------------------------------*
* MODULES pai_0100 INPUT
*----------------------------------------------------------------------*
MODULE pai_0100 INPUT.
  " Example: call ZCL_HR_BANK_GUI_APP=>pai_main( ).
ENDMODULE.

*----------------------------------------------------------------------*
* MODULES pbo_0200 OUTPUT
*----------------------------------------------------------------------*
MODULE pbo_0200 OUTPUT.
  " Populate bank listbox from ZCL_HR_BANK_QUERY=>read_bank_code_list( ).
ENDMODULE.

*----------------------------------------------------------------------*
* MODULES pai_0200 INPUT
*----------------------------------------------------------------------*
MODULE pai_0200 INPUT.
  " On Save: ZCL_HR_BANK_INFOTYPE=>modify_salary_bank( ... ).
ENDMODULE.

*----------------------------------------------------------------------*
* MODULES pbo_0300 OUTPUT
*----------------------------------------------------------------------*
MODULE pbo_0300 OUTPUT.
  " Static confirmation text only.
ENDMODULE.

*----------------------------------------------------------------------*
* MODULES pai_0300 INPUT
*----------------------------------------------------------------------*
MODULE pai_0300 INPUT.
  " On OK: ZCL_HR_BANK_INFOTYPE=>delete_bank_record( ... ).
ENDMODULE.
