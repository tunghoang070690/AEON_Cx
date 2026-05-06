*&---------------------------------------------------------------------*
*& Include          MZHR_BANKTOP
*&---------------------------------------------------------------------*
*& Global types, data, and ALV references for bank inquiry screens.
*& Screens: 0100 main (ALV), 0200 change popup, 0300 delete confirm.
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_grid_alv,
         bank_name TYPE zthr0021-zcode_text1,
         bankn     TYPE bankn,
       END OF ty_grid_alv.

DATA gt_alv TYPE STANDARD TABLE OF ty_grid_alv WITH EMPTY KEY.

" Full logical row from PA0009 + text (used for Change/Delete keys).
DATA gs_keys TYPE zcl_hr_bank_query=>ty_active_bank_row.

DATA ok_code TYPE sy-ucomm.

" After successful HR_INFOTYPE_OPERATION from popup, next PBO reloads grid.
DATA gv_main_must_refresh TYPE abap_bool VALUE abap_true.

DATA gv_pernr TYPE pernr_d.

DATA gt_bank_list TYPE zcl_hr_bank_query=>ty_t_bank_code.

" Change popup working fields (bind to screen 0200 fields).
DATA gv_ch_bankl TYPE zthr0021-zcode.
DATA gv_ch_bankn TYPE bankn.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_alv       TYPE REF TO cl_gui_alv_grid.
