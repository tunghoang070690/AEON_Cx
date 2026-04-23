REPORT zhr_pa_upload_oop_v5.

TYPE-POOLS: icon.
TABLES: sscrfields.

TYPES: BEGIN OF ty_input,
         row_no TYPE i,
         pernr  TYPE pernr_d,
         begda  TYPE begda,
         endda  TYPE endda,
         massn  TYPE massn,
         massg  TYPE massg,
         werks  TYPE werks_d,
         btrtl  TYPE btrtl,
         persg  TYPE persg,
         persk  TYPE persk,
         orgeh  TYPE orgeh,
         stell  TYPE stell,
         plans  TYPE plans,
         abkrs  TYPE abkrs,
         ansvh  TYPE ansvh,
         nachn  TYPE p0002-nachn,
         vorna  TYPE p0002-vorna,
         midnm  TYPE p0002-midnm,
         perid  TYPE p0002-perid,
         gbdat  TYPE gbdat,
         gesch  TYPE p0002-gesch,
         sprsl  TYPE spras,
         natio  TYPE natio,
         famst  TYPE p0002-famst,
       END OF ty_input.
TYPES ty_t_input TYPE STANDARD TABLE OF ty_input WITH EMPTY KEY.

TYPES: BEGIN OF ty_log,
         row_no   TYPE i,
         pernr    TYPE pernr_d,
         infty    TYPE infty,
         msgty    TYPE c LENGTH 1,
         message  TYPE string,
       END OF ty_log.
TYPES ty_t_log TYPE STANDARD TABLE OF ty_log WITH EMPTY KEY.

DATA gv_title TYPE c LENGTH 40 VALUE 'Upload Employee Actions'.
DATA gs_fk1 TYPE smp_dyntxt.
DATA gs_fk2 TYPE smp_dyntxt.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE gv_title.
PARAMETERS p_file TYPE rlgrap-filename LOWER CASE.
SELECTION-SCREEN END OF BLOCK b1.

CLASS lcx_upload DEFINITION FINAL INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    DATA text TYPE string READ-ONLY.
    METHODS constructor IMPORTING iv_text TYPE string.
ENDCLASS.

CLASS lcl_util DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS trim
      IMPORTING iv_value TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    CLASS-METHODS alpha_in_pernr
      IMPORTING iv_raw TYPE string
      RETURNING VALUE(rv_pernr) TYPE pernr_d.
    CLASS-METHODS normalize_date
      IMPORTING iv_raw TYPE string
      RETURNING VALUE(rv_date) TYPE d.
    CLASS-METHODS normalize_gender
      IMPORTING iv_raw TYPE string
      RETURNING VALUE(rv_gender) TYPE p0002-gesch.
    CLASS-METHODS normalize_language
      IMPORTING iv_raw TYPE string
      RETURNING VALUE(rv_spras) TYPE spras.
    CLASS-METHODS is_error_return
      IMPORTING is_return TYPE bapireturn1
      RETURNING VALUE(rv_error) TYPE abap_bool.
    CLASS-METHODS return_message
      IMPORTING is_return TYPE bapireturn1
      RETURNING VALUE(rv_msg) TYPE string.
ENDCLASS.

CLASS lcl_logger DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS add
      IMPORTING
        iv_row_no  TYPE i
        iv_pernr   TYPE pernr_d
        iv_infty   TYPE infty
        iv_msgty   TYPE c
        iv_message TYPE string.
    METHODS add_table IMPORTING it_log TYPE ty_t_log.
    METHODS has_error RETURNING VALUE(rv_has) TYPE abap_bool.
    METHODS display RAISING lcx_upload.
  PRIVATE SECTION.
    DATA mt_log TYPE ty_t_log.
ENDCLASS.

CLASS lcl_memory DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS save_pending IMPORTING it_input TYPE ty_t_input.
    CLASS-METHODS load_pending RETURNING VALUE(rt_input) TYPE ty_t_input.
    CLASS-METHODS clear_pending.
  PRIVATE SECTION.
    CONSTANTS gc_memid TYPE c LENGTH 24 VALUE 'ZHR_PA_UPLOAD_PENDING'.
ENDCLASS.

CLASS lcl_excel_reader DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING iv_file TYPE rlgrap-filename.
    METHODS read
      EXPORTING
        et_input TYPE ty_t_input
        et_log   TYPE ty_t_log
      RAISING lcx_upload.
  PRIVATE SECTION.
    DATA mv_file TYPE rlgrap-filename.
    METHODS upload_xlsx RETURNING VALUE(rv_xstr) TYPE xstring RAISING lcx_upload.
    METHODS parse_xlsx
      IMPORTING iv_xstr TYPE xstring
      EXPORTING et_input TYPE ty_t_input
                et_log   TYPE ty_t_log
      RAISING lcx_upload.
    METHODS get_cell
      IMPORTING is_row TYPE any iv_index TYPE i
      RETURNING VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS lcl_hr_service DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_logger TYPE REF TO lcl_logger.
    METHODS validate_all IMPORTING it_input TYPE ty_t_input.
    METHODS save_all IMPORTING it_input TYPE ty_t_input.
  PRIVATE SECTION.
    DATA mo_logger TYPE REF TO lcl_logger.
    METHODS lock_pernr
      IMPORTING
        iv_pernr  TYPE pernr_d
        iv_row_no TYPE i
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS unlock_pernr IMPORTING iv_pernr TYPE pernr_d.
    METHODS post_row
      IMPORTING is_input TYPE ty_input
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS post_0000 IMPORTING is_input TYPE ty_input RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS post_0001 IMPORTING is_input TYPE ty_input RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS post_0002 IMPORTING is_input TYPE ty_input RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS add_return_log
      IMPORTING
        iv_row_no TYPE i
        iv_pernr  TYPE pernr_d
        iv_infty  TYPE infty
        is_return TYPE bapireturn1.
ENDCLASS.

CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS set_function_texts.
    CLASS-METHODS handle_download RAISING lcx_upload.
    METHODS constructor IMPORTING iv_file TYPE rlgrap-filename.
    METHODS execute_upload RAISING lcx_upload.
    METHODS save_pending RAISING lcx_upload.
  PRIVATE SECTION.
    CONSTANTS c_relid TYPE wwwdatatab-relid VALUE 'MI'.
    CONSTANTS c_objid TYPE wwwdatatab-objid VALUE 'ZHR_UPL_XLSX'.
    CONSTANTS c_dft   TYPE string VALUE 'zhr_pa_upload_layout.xlsx'.
    DATA mv_file TYPE rlgrap-filename.
    CLASS-METHODS download_template RETURNING VALUE(rv_fullpath) TYPE string RAISING lcx_upload.
ENDCLASS.

INITIALIZATION.
  lcl_app=>set_function_texts( ).

AT SELECTION-SCREEN OUTPUT.
  lcl_app=>set_function_texts( ).

AT SELECTION-SCREEN.
  TRY.
      CASE sscrfields-ucomm.
        WHEN 'FC01'.
          lcl_app=>handle_download( ).
          sscrfields-ucomm = ''.
          LEAVE TO SCREEN sy-dynnr.
        WHEN 'FC02'.
          NEW lcl_app(
            iv_file = p_file )->save_pending( ).
          sscrfields-ucomm = ''.
          LEAVE TO SCREEN sy-dynnr.
      ENDCASE.
    CATCH lcx_upload INTO DATA(lx_scr).
      MESSAGE lx_scr->text TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

START-OF-SELECTION.
  TRY.
      NEW lcl_app(
        iv_file = p_file )->execute_upload( ).
    CATCH lcx_upload INTO DATA(lx_main).
      MESSAGE lx_main->text TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

CLASS lcx_upload IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    text = iv_text.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD trim.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF '"' IN rv_value WITH ''.
    CONDENSE rv_value.
  ENDMETHOD.

  METHOD alpha_in_pernr.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = trim( iv_raw )
      IMPORTING
        output = rv_pernr.
  ENDMETHOD.

  METHOD normalize_date.
    DATA lv TYPE string.
    lv = trim( iv_raw ).
    REPLACE ALL OCCURRENCES OF '-' IN lv WITH ''.
    REPLACE ALL OCCURRENCES OF '.' IN lv WITH ''.
    REPLACE ALL OCCURRENCES OF '/' IN lv WITH ''.
    CONDENSE lv NO-GAPS.
    CLEAR rv_date.

    IF lv CO '0123456789' AND strlen( lv ) <= 5.
      rv_date = '18991230' + CONV i( lv ).
    ELSEIF lv CO '0123456789' AND strlen( lv ) = 8.
      IF lv+0(4) BETWEEN '1900' AND '9999'.
        rv_date = lv.
      ELSEIF lv+4(4) BETWEEN '1900' AND '9999'.
        rv_date = |{ lv+4(4) }{ lv+2(2) }{ lv+0(2) }|.
      ENDIF.
    ENDIF.

    IF rv_date IS NOT INITIAL.
      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date = rv_date
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.
      IF sy-subrc <> 0.
        CLEAR rv_date.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD normalize_gender.
    DATA lv TYPE string.
    lv = trim( iv_raw ).
    TRANSLATE lv TO UPPER CASE.
    IF lv = '1' OR lv = 'M' OR lv = 'MALE'.
      rv_gender = '1'.
    ELSEIF lv = '2' OR lv = 'F' OR lv = 'FEMALE'.
      rv_gender = '2'.
    ENDIF.
  ENDMETHOD.

  METHOD normalize_language.
    DATA lv TYPE string.
    lv = trim( iv_raw ).
    TRANSLATE lv TO UPPER CASE.
    IF lv IS INITIAL.
      CLEAR rv_spras.
      RETURN.
    ENDIF.
    IF strlen( lv ) = 1.
      rv_spras = lv.
      RETURN.
    ENDIF.
    IF strlen( lv ) = 2.
      SELECT SINGLE spras
        FROM t002
        WHERE laiso = @lv
        INTO @rv_spras.
    ENDIF.
  ENDMETHOD.

  METHOD is_error_return.
    rv_error = xsdbool( is_return-type CA 'AEX' ).
  ENDMETHOD.

  METHOD return_message.
    DATA lv_text TYPE string.
    IF is_return-message IS NOT INITIAL.
      rv_msg = is_return-message.
      RETURN.
    ENDIF.
    MESSAGE ID is_return-id TYPE is_return-type NUMBER is_return-number
      WITH is_return-message_v1 is_return-message_v2 is_return-message_v3 is_return-message_v4
      INTO lv_text.
    rv_msg = lv_text.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_logger IMPLEMENTATION.
  METHOD add.
    APPEND VALUE ty_log(
      row_no  = iv_row_no
      pernr   = iv_pernr
      infty   = iv_infty
      msgty   = iv_msgty
      message = iv_message ) TO mt_log.
  ENDMETHOD.

  METHOD add_table.
    APPEND LINES OF it_log TO mt_log.
  ENDMETHOD.

  METHOD has_error.
    rv_has = abap_false.
    LOOP AT mt_log ASSIGNING FIELD-SYMBOL(<ls_log>) WHERE msgty = 'E'.
      rv_has = abap_true.
      EXIT.
    ENDLOOP.
  ENDMETHOD.

  METHOD display.
    DATA lo_alv TYPE REF TO cl_salv_table.
    IF mt_log IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = mt_log ).
        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->display( ).
      CATCH cx_root INTO DATA(lx_alv).
        RAISE EXCEPTION NEW lcx_upload( iv_text = lx_alv->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_memory IMPLEMENTATION.
  METHOD save_pending.
    EXPORT pending = it_input TO MEMORY ID gc_memid.
  ENDMETHOD.

  METHOD load_pending.
    CLEAR rt_input.
    IMPORT pending = rt_input FROM MEMORY ID gc_memid.
  ENDMETHOD.

  METHOD clear_pending.
    FREE MEMORY ID gc_memid.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_excel_reader IMPLEMENTATION.
  METHOD constructor.
    mv_file = iv_file.
  ENDMETHOD.

  METHOD read.
    DATA lv_xstr TYPE xstring.
    lv_xstr = upload_xlsx( ).
    parse_xlsx(
      EXPORTING
        iv_xstr = lv_xstr
      IMPORTING
        et_input = et_input
        et_log   = et_log ).
  ENDMETHOD.

  METHOD upload_xlsx.
    DATA lt_bin TYPE solix_tab.
    DATA lv_len TYPE i.

    IF mv_file IS INITIAL.
      RAISE EXCEPTION NEW lcx_upload( iv_text = 'Vui lòng chọn file XLSX.' ).
    ENDIF.

    TRY.
        cl_gui_frontend_services=>gui_upload(
          EXPORTING
            filename   = mv_file
            filetype   = 'BIN'
          IMPORTING
            filelength = lv_len
          CHANGING
            data_tab   = lt_bin ).
      CATCH cx_root INTO DATA(lx_up).
        RAISE EXCEPTION NEW lcx_upload( iv_text = lx_up->get_text( ) ).
    ENDTRY.

    IF lv_len = 0 OR lt_bin IS INITIAL.
      RAISE EXCEPTION NEW lcx_upload( iv_text = 'File XLSX rỗng hoặc không đọc được.' ).
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_len
      IMPORTING
        buffer       = rv_xstr
      TABLES
        binary_tab   = lt_bin.
  ENDMETHOD.

  METHOD parse_xlsx.
    DATA lo_excel TYPE REF TO cl_fdt_xl_spreadsheet.
    DATA lt_ws TYPE if_fdt_doc_spreadsheet=>t_worksheet_names.
    DATA lv_ws TYPE string.
    DATA lr_data TYPE REF TO data.
    DATA lv_row TYPE i.

    FIELD-SYMBOLS <lt_sheet> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_sheet> TYPE any.

    CLEAR: et_input, et_log.

    TRY.
        lo_excel = NEW cl_fdt_xl_spreadsheet(
          document_name = CONV string( mv_file )
          xdocument     = iv_xstr ).

        lo_excel->if_fdt_doc_spreadsheet~get_worksheet_names(
          IMPORTING worksheet_names = lt_ws ).
        READ TABLE lt_ws INDEX 1 INTO lv_ws.
        IF sy-subrc <> 0 OR lv_ws IS INITIAL.
          RAISE EXCEPTION NEW lcx_upload( iv_text = 'Không tìm thấy worksheet trong XLSX.' ).
        ENDIF.

        lr_data = lo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet(
                    worksheet_name = lv_ws ).
        ASSIGN lr_data->* TO <lt_sheet>.
        IF <lt_sheet> IS NOT ASSIGNED.
          RAISE EXCEPTION NEW lcx_upload( iv_text = 'Không đọc được worksheet.' ).
        ENDIF.

        LOOP AT <lt_sheet> ASSIGNING <ls_sheet>.
          lv_row = lv_row + 1.
          IF lv_row = 1.
            CONTINUE.
          ENDIF.

          DATA(ls_input) = VALUE ty_input(
            row_no = lv_row
            pernr  = lcl_util=>alpha_in_pernr( get_cell( is_row = <ls_sheet> iv_index = 1  ) )
            begda  = lcl_util=>normalize_date( get_cell( is_row = <ls_sheet> iv_index = 2  ) )
            endda  = lcl_util=>normalize_date( get_cell( is_row = <ls_sheet> iv_index = 3  ) )
            massn  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 4  ) )
            massg  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 5  ) )
            werks  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 6  ) )
            btrtl  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 7  ) )
            persg  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 8  ) )
            persk  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 9  ) )
            orgeh  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 10 ) )
            stell  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 11 ) )
            plans  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 12 ) )
            abkrs  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 13 ) )
            ansvh  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 14 ) )
            nachn  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 15 ) )
            vorna  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 16 ) )
            midnm  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 17 ) )
            perid  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 18 ) )
            gbdat  = lcl_util=>normalize_date( get_cell( is_row = <ls_sheet> iv_index = 19 ) )
            gesch  = lcl_util=>normalize_gender( get_cell( is_row = <ls_sheet> iv_index = 20 ) )
            sprsl  = lcl_util=>normalize_language( get_cell( is_row = <ls_sheet> iv_index = 21 ) )
            natio  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 22 ) )
            famst  = lcl_util=>trim( get_cell( is_row = <ls_sheet> iv_index = 23 ) ) ).

          IF ls_input-pernr IS INITIAL
             AND ls_input-begda IS INITIAL
             AND ls_input-endda IS INITIAL
             AND ls_input-nachn IS INITIAL
             AND ls_input-vorna IS INITIAL.
            CONTINUE.
          ENDIF.

          IF ls_input-pernr IS INITIAL OR ls_input-begda IS INITIAL OR ls_input-endda IS INITIAL.
            APPEND VALUE ty_log(
              row_no  = lv_row
              pernr   = ls_input-pernr
              infty   = ''
              msgty   = 'E'
              message = 'Thiếu PERNR/BEGDA/ENDDA.' ) TO et_log.
            CONTINUE.
          ENDIF.

          IF ls_input-gesch IS INITIAL.
            APPEND VALUE ty_log(
              row_no  = lv_row
              pernr   = ls_input-pernr
              infty   = '0002'
              msgty   = 'E'
              message = 'Gender không hợp lệ (1/2 hoặc Male/Female).' ) TO et_log.
            CONTINUE.
          ENDIF.

          APPEND ls_input TO et_input.
        ENDLOOP.

      CATCH lcx_upload INTO DATA(lx_upload).
        RAISE EXCEPTION lx_upload.
      CATCH cx_root INTO DATA(lx_read).
        RAISE EXCEPTION NEW lcx_upload( iv_text = lx_read->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_cell.
    FIELD-SYMBOLS <lv_cell> TYPE any.
    CLEAR rv_value.
    ASSIGN COMPONENT iv_index OF STRUCTURE is_row TO <lv_cell>.
    IF sy-subrc = 0 AND <lv_cell> IS ASSIGNED.
      rv_value = lcl_util=>trim( |{ <lv_cell> }| ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_hr_service IMPLEMENTATION.
  METHOD constructor.
    mo_logger = io_logger.
  ENDMETHOD.

  METHOD validate_all.
    LOOP AT it_input INTO DATA(ls_input).
      DATA lv_locked_ok TYPE abap_bool.
      lv_locked_ok = lock_pernr(
        iv_pernr  = ls_input-pernr
        iv_row_no = ls_input-row_no ).
      IF lv_locked_ok = abap_false.
        CONTINUE.
      ENDIF.

      post_row( is_input = ls_input ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      unlock_pernr( iv_pernr = ls_input-pernr ).
    ENDLOOP.
  ENDMETHOD.

  METHOD save_all.
    DATA lt_locked TYPE SORTED TABLE OF pernr_d WITH UNIQUE KEY table_line.
    DATA lv_failed TYPE abap_bool VALUE abap_false.
    DATA lv_locked_ok TYPE abap_bool.
    DATA lv_pernr_initial TYPE pernr_d.

    LOOP AT it_input INTO DATA(ls_input).
      READ TABLE lt_locked WITH TABLE KEY table_line = ls_input-pernr TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        lv_locked_ok = lock_pernr(
          iv_pernr  = ls_input-pernr
          iv_row_no = ls_input-row_no ).
        IF lv_locked_ok = abap_false.
          lv_failed = abap_true.
          EXIT.
        ENDIF.
        INSERT ls_input-pernr INTO TABLE lt_locked.
      ENDIF.

      IF post_row( is_input = ls_input ) = abap_false.
        lv_failed = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_failed = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      mo_logger->add(
        iv_row_no  = 0
        iv_pernr   = lv_pernr_initial
        iv_infty   = ''
        iv_msgty   = 'E'
        iv_message = 'Save thất bại. Đã rollback toàn bộ dữ liệu.' ).
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.
      mo_logger->add(
        iv_row_no  = 0
        iv_pernr   = lv_pernr_initial
        iv_infty   = ''
        iv_msgty   = 'S'
        iv_message = 'Lưu dữ liệu thành công.' ).
    ENDIF.

    LOOP AT lt_locked INTO DATA(lv_pernr).
      unlock_pernr( iv_pernr = lv_pernr ).
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_pernr.
    DATA ls_return TYPE bapireturn1.

    rv_ok = abap_false.
    CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
      EXPORTING
        number = iv_pernr
      IMPORTING
        return = ls_return.

    IF lcl_util=>is_error_return( is_return = ls_return ) = abap_true.
      add_return_log(
        iv_row_no = iv_row_no
        iv_pernr  = iv_pernr
        iv_infty  = ''
        is_return = ls_return ).
      RETURN.
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD unlock_pernr.
    CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
      EXPORTING
        number = iv_pernr.
  ENDMETHOD.

  METHOD post_row.
    rv_ok = abap_false.

    IF post_0000( is_input = is_input ) = abap_false.
      RETURN.
    ENDIF.
    IF post_0001( is_input = is_input ) = abap_false.
      RETURN.
    ENDIF.
    IF post_0002( is_input = is_input ) = abap_false.
      RETURN.
    ENDIF.

    rv_ok = abap_true.
  ENDMETHOD.

  METHOD post_0000.
    DATA ls TYPE p0000.
    DATA lr TYPE bapireturn1.

    rv_ok = abap_false.
    ls-pernr = is_input-pernr.
    ls-begda = is_input-begda.
    ls-endda = is_input-endda.
    ls-massn = is_input-massn.
    ls-massg = is_input-massg.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = '0000'
        number        = is_input-pernr
        validitybegin = is_input-begda
        validityend   = is_input-endda
        record        = ls
        operation     = 'INS'
        tclas         = 'A'
        nocommit      = abap_true
      IMPORTING
        return        = lr.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      CALL FUNCTION 'HR_INFOTYPE_OPERATION'
        EXPORTING
          infty         = '0000'
          number        = is_input-pernr
          validitybegin = is_input-begda
          validityend   = is_input-endda
          record        = ls
          operation     = 'MOD'
          tclas         = 'A'
          nocommit      = abap_true
        IMPORTING
          return        = lr.
    ENDIF.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      add_return_log(
        iv_row_no = is_input-row_no
        iv_pernr  = is_input-pernr
        iv_infty  = '0000'
        is_return = lr ).
      RETURN.
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD post_0001.
    DATA ls TYPE p0001.
    DATA lr TYPE bapireturn1.
    DATA lv_bukrs TYPE bukrs.

    rv_ok = abap_false.

    SELECT SINGLE bukrs
      FROM t500p
      WHERE persa = @is_input-werks
      INTO @lv_bukrs.
    IF sy-subrc <> 0 OR lv_bukrs IS INITIAL.
      mo_logger->add(
        iv_row_no  = is_input-row_no
        iv_pernr   = is_input-pernr
        iv_infty   = '0001'
        iv_msgty   = 'E'
        iv_message = |Không map được BUKRS từ WERKS { is_input-werks }.| ).
      RETURN.
    ENDIF.

    ls-pernr = is_input-pernr.
    ls-begda = is_input-begda.
    ls-endda = is_input-endda.
    ls-bukrs = lv_bukrs.
    ls-werks = is_input-werks.
    ls-btrtl = is_input-btrtl.
    ls-persg = is_input-persg.
    ls-persk = is_input-persk.
    ls-orgeh = is_input-orgeh.
    ls-stell = is_input-stell.
    ls-plans = is_input-plans.
    ls-abkrs = is_input-abkrs.
    ls-ansvh = is_input-ansvh.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = '0001'
        number        = is_input-pernr
        validitybegin = is_input-begda
        validityend   = is_input-endda
        record        = ls
        operation     = 'INS'
        tclas         = 'A'
        nocommit      = abap_true
      IMPORTING
        return        = lr.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      CALL FUNCTION 'HR_INFOTYPE_OPERATION'
        EXPORTING
          infty         = '0001'
          number        = is_input-pernr
          validitybegin = is_input-begda
          validityend   = is_input-endda
          record        = ls
          operation     = 'MOD'
          tclas         = 'A'
          nocommit      = abap_true
        IMPORTING
          return        = lr.
    ENDIF.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      add_return_log(
        iv_row_no = is_input-row_no
        iv_pernr  = is_input-pernr
        iv_infty  = '0001'
        is_return = lr ).
      RETURN.
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD post_0002.
    DATA ls TYPE p0002.
    DATA lr TYPE bapireturn1.

    rv_ok = abap_false.

    ls-pernr = is_input-pernr.
    ls-begda = is_input-begda.
    ls-endda = is_input-endda.
    ls-nachn = is_input-nachn.
    ls-vorna = is_input-vorna.
    ls-midnm = is_input-midnm.
    ls-perid = is_input-perid.
    ls-gbdat = is_input-gbdat.
    ls-gesch = is_input-gesch.
    ls-sprsl = is_input-sprsl.
    ls-natio = is_input-natio.
    ls-famst = is_input-famst.

    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = '0002'
        number        = is_input-pernr
        validitybegin = is_input-begda
        validityend   = is_input-endda
        record        = ls
        operation     = 'INS'
        tclas         = 'A'
        nocommit      = abap_true
      IMPORTING
        return        = lr.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      CALL FUNCTION 'HR_INFOTYPE_OPERATION'
        EXPORTING
          infty         = '0002'
          number        = is_input-pernr
          validitybegin = is_input-begda
          validityend   = is_input-endda
          record        = ls
          operation     = 'MOD'
          tclas         = 'A'
          nocommit      = abap_true
        IMPORTING
          return        = lr.
    ENDIF.

    IF lcl_util=>is_error_return( is_return = lr ) = abap_true.
      add_return_log(
        iv_row_no = is_input-row_no
        iv_pernr  = is_input-pernr
        iv_infty  = '0002'
        is_return = lr ).
      RETURN.
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD add_return_log.
    mo_logger->add(
      iv_row_no  = iv_row_no
      iv_pernr   = iv_pernr
      iv_infty   = iv_infty
      iv_msgty   = 'E'
      iv_message = lcl_util=>return_message( is_return = is_return ) ).
  ENDMETHOD.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.
  METHOD set_function_texts.
    DATA lt_pending TYPE ty_t_input.

    gs_fk1-icon_id   = icon_export.
    gs_fk1-icon_text = 'Download Layout'.
    gs_fk1-quickinfo = 'Download Excel template'.
    sscrfields-functxt_01 = gs_fk1.

    lt_pending = lcl_memory=>load_pending( ).
    IF lt_pending IS NOT INITIAL.
      gs_fk2-icon_id   = icon_system_save.
      gs_fk2-icon_text = 'Save'.
      gs_fk2-quickinfo = 'Save validated data to DB'.
      sscrfields-functxt_02 = gs_fk2.
    ELSE.
      CLEAR sscrfields-functxt_02.
    ENDIF.
  ENDMETHOD.

  METHOD handle_download.
    DATA(lv_path) = download_template( ).
    IF lv_path IS NOT INITIAL.
      MESSAGE |Đã download layout: { lv_path }| TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    mv_file = iv_file.
  ENDMETHOD.

  METHOD execute_upload.
    DATA lo_logger TYPE REF TO lcl_logger.
    DATA lo_reader TYPE REF TO lcl_excel_reader.
    DATA lo_hr TYPE REF TO lcl_hr_service.
    DATA lt_input TYPE ty_t_input.
    DATA lt_parse TYPE ty_t_log.
    DATA lv_pernr_initial TYPE pernr_d.

    lcl_memory=>clear_pending( ).

    lo_logger = NEW lcl_logger( ).
    lo_reader = NEW lcl_excel_reader( iv_file = mv_file ).
    lo_hr     = NEW lcl_hr_service( io_logger = lo_logger ).

    lo_reader->read(
      IMPORTING
        et_input = lt_input
        et_log   = lt_parse ).
    lo_logger->add_table( it_log = lt_parse ).

    lo_hr->validate_all( it_input = lt_input ).
    IF lo_logger->has_error( ) = abap_true.
      lo_logger->display( ).
      RETURN.
    ENDIF.

    lcl_memory=>save_pending( it_input = lt_input ).
    lo_logger->add(
      iv_row_no  = 0
      iv_pernr   = lv_pernr_initial
      iv_infty   = ''
      iv_msgty   = 'S'
      iv_message = 'Validate thành công. Nhấn Save để lưu DB.' ).
    lo_logger->display( ).
  ENDMETHOD.

  METHOD save_pending.
    DATA lo_logger TYPE REF TO lcl_logger.
    DATA lo_hr TYPE REF TO lcl_hr_service.
    DATA lt_pending TYPE ty_t_input.

    lt_pending = lcl_memory=>load_pending( ).
    IF lt_pending IS INITIAL.
      RAISE EXCEPTION NEW lcx_upload( iv_text = 'Không có dữ liệu đã validate để lưu.' ).
    ENDIF.

    lo_logger = NEW lcl_logger( ).
    lo_hr     = NEW lcl_hr_service( io_logger = lo_logger ).
    lo_hr->save_all( it_input = lt_pending ).
    lo_logger->display( ).

    IF lo_logger->has_error( ) = abap_false.
      lcl_memory=>clear_pending( ).
    ENDIF.
  ENDMETHOD.

  METHOD download_template.
    DATA ls_key TYPE wwwdatatab.
    DATA lt_mime TYPE STANDARD TABLE OF w3mime WITH EMPTY KEY.
    DATA lt_bin TYPE solix_tab.
    DATA lv_name TYPE string.
    DATA lv_path TYPE string.
    DATA lv_full TYPE string.
    DATA lv_action TYPE i.
    FIELD-SYMBOLS <ls_mime> TYPE w3mime.

    ls_key-relid = c_relid.
    ls_key-objid = c_objid.
    CALL FUNCTION 'WWWDATA_IMPORT'
      EXPORTING
        key               = ls_key
      TABLES
        mime              = lt_mime
      EXCEPTIONS
        wrong_object_type = 1
        import_error      = 2
        OTHERS            = 3.
    IF sy-subrc <> 0 OR lt_mime IS INITIAL.
      RAISE EXCEPTION NEW lcx_upload( iv_text = |Không tìm thấy SMW0 object { c_objid }.| ).
    ENDIF.

    LOOP AT lt_mime ASSIGNING <ls_mime>.
      APPEND VALUE solix( line = <ls_mime>-line ) TO lt_bin.
    ENDLOOP.

    TRY.
        cl_gui_frontend_services=>file_save_dialog(
          EXPORTING
            default_extension = 'xlsx'
            default_file_name = c_dft
          CHANGING
            filename          = lv_name
            path              = lv_path
            fullpath          = lv_full
            user_action       = lv_action ).
        IF lv_action = cl_gui_frontend_services=>action_cancel.
          RETURN.
        ENDIF.
        cl_gui_frontend_services=>gui_download(
          EXPORTING
            filename = lv_full
            filetype = 'BIN'
          CHANGING
            data_tab = lt_bin ).
      CATCH cx_root INTO DATA(lx_dl).
        RAISE EXCEPTION NEW lcx_upload( iv_text = lx_dl->get_text( ) ).
    ENDTRY.
    rv_fullpath = lv_full.
  ENDMETHOD.
ENDCLASS.
