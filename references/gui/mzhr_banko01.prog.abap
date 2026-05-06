*&---------------------------------------------------------------------*
*& Include MZHR_BANKO01
*&---------------------------------------------------------------------*
*& PBO modules — minimal logic; data preparation in forms (MZHR_BANKF01).
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'MAIN'.

  IF gv_main_must_refresh = abap_true.
    PERFORM load_main_data.
    gv_main_must_refresh = abap_false.
  ENDIF.

  IF go_container IS INITIAL.
    PERFORM create_alv_grid.
  ELSE.
    PERFORM refresh_alv_grid.
  ENDIF.
ENDMODULE.


MODULE status_0200 OUTPUT.
  SET PF-STATUS 'POPUP_CH'.
  SET TITLEBAR 'POP_CH'.

  PERFORM prepare_change_popup_pbo.
ENDMODULE.


MODULE status_0300 OUTPUT.
  SET PF-STATUS 'POPUP_DL'.
  SET TITLEBAR 'POP_DL'.
ENDMODULE.
