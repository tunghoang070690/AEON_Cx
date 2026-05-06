*&---------------------------------------------------------------------*
*& Include MZHR_BANKF01
*&---------------------------------------------------------------------*
*& Main grid load, ALV lifecycle, listbox values, delete orchestration.
*&---------------------------------------------------------------------*

FORM load_main_data.

  TRY.
      gv_pernr = zcl_hr_bank_context=>get_personnel_number_for_user( ).
    CATCH zcx_hr_bank_no_pernr.
      MESSAGE |Personnel number could not be resolved for the current user.| TYPE 'E'.
      RETURN.
  ENDTRY.

  " Example HR authorization — activate with your role design (P_ORGIN / successor).
  " AUTHORITY-CHECK OBJECT 'P_ORGIN'
  "   ID 'INFTY' FIELD '0009'
  "   ID 'SUBTY' FIELD '0'
  "   ID 'AUTHC' FIELD 'R'.
  " IF sy-subrc <> 0.
  "   MESSAGE |No authorization for bank infotype 0009.| TYPE 'E'.
  "   RETURN.
  " ENDIF.

  DATA(ls_act) = zcl_hr_bank_query=>read_active_salary_account( gv_pernr ).

  CLEAR gt_alv.

  IF ls_act-pernr IS NOT INITIAL.
    APPEND VALUE #( bank_name = ls_act-bank_name bankn = ls_act-bankn ) TO gt_alv.
    gs_keys = ls_act.
  ELSE.
    APPEND VALUE #( bank_name = space bankn = space ) TO gt_alv.
    CLEAR gs_keys.
  ENDIF.

ENDFORM.


FORM create_alv_grid.

  CREATE OBJECT go_container
    EXPORTING
      container_name = 'CC_MAIN'.

  CREATE OBJECT go_alv
    EXPORTING
      i_parent = go_container.

  DATA lt_fcat TYPE lvc_t_fcat.
  PERFORM build_fieldcatalog CHANGING lt_fcat.

  CALL METHOD go_alv->set_table_for_first_display
    EXPORTING
      i_buffer_active = abap_false
    CHANGING
      it_outtab         = gt_alv
      it_fieldcatalog   = lt_fcat.

ENDFORM.


FORM refresh_alv_grid.

  CHECK go_alv IS NOT INITIAL.

  DATA ls_stable TYPE lvc_s_stbl.
  ls_stable-row = abap_true.
  ls_stable-col = abap_true.

  go_alv->refresh_table_display(
    EXPORTING
      is_stable = ls_stable ).

ENDFORM.


FORM build_fieldcatalog CHANGING ct_fcat TYPE lvc_t_fcat.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BANK_NAME'.
  ls_fcat-coltext   = 'Bank'.
  ls_fcat-outputlen = 40.
  APPEND ls_fcat TO ct_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BANKN'.
  ls_fcat-coltext   = 'Account number'.
  ls_fcat-outputlen = 30.
  APPEND ls_fcat TO ct_fcat.

ENDFORM.


FORM prepare_change_popup_before_call.
  gv_ch_bankl = gs_keys-bankl.
  gv_ch_bankn = gs_keys-bankn.
ENDFORM.


FORM prepare_change_popup_pbo.

  gt_bank_list = zcl_hr_bank_query=>read_bank_code_list( ).

  DATA lt_values TYPE vrm_values.
  CLEAR lt_values.

  LOOP AT gt_bank_list INTO DATA(ls).
    APPEND VALUE #( key = ls-zcode text = ls-zcode_text1 ) TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_CH_BANKL'
      values = lt_values.

ENDFORM.


FORM display_infotype_exception USING io TYPE REF TO zcx_hr_bank_infotype.

  DATA ls_ret TYPE bapiret2.

  READ TABLE io->mt_return INTO ls_ret INDEX 1.
  IF sy-subrc = 0.
    IF ls_ret-type IS INITIAL.
      ls_ret-type = 'E'.
    ENDIF.
    MESSAGE ID ls_ret-id TYPE ls_ret-type NUMBER ls_ret-number
      WITH ls_ret-message_v1 ls_ret-message_v2 ls_ret-message_v3 ls_ret-message_v4.
  ELSE.
    MESSAGE |Bank infotype operation failed.| TYPE 'E'.
  ENDIF.

ENDFORM.


FORM execute_delete_from_popup.

  IF gs_keys-begda <> sy-datum.
    MESSAGE |Deletion is only allowed when the record start date equals the current date.| TYPE 'E'.
    RETURN.
  ENDIF.

  DATA(ls_p0009) = zcl_hr_bank_query=>read_pa0009_record(
      iv_pernr = gs_keys-pernr
      iv_subty = gs_keys-subty
      iv_begda = gs_keys-begda
      iv_endda = gs_keys-endda ).

  IF ls_p0009-pernr IS INITIAL.
    MESSAGE |Could not read bank infotype row for deletion.| TYPE 'E'.
    RETURN.
  ENDIF.

  TRY.
      zcl_hr_bank_infotype=>delete_bank_record(
        EXPORTING
          iv_pernr = gv_pernr
          is_p0009 = ls_p0009 ).

      gv_main_must_refresh = abap_true.
      LEAVE TO SCREEN 0.

    CATCH zcx_hr_bank_infotype INTO DATA(lx_del).
      PERFORM display_infotype_exception USING lx_del.
  ENDTRY.

ENDFORM.
