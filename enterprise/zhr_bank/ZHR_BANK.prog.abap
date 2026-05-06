*&---------------------------------------------------------------------*
*& Report ZHR_BANK  (Executable Program / Dialog Transaction Entry)
*&---------------------------------------------------------------------*
*& Bank salary account inquiry & maintenance (PA0009 subty 0).
*& Architecture: all logic in global classes; MODULEs delegate only.
*& Transaction: ZHRB → Dialog, program ZHR_BANK, screen 0100.
*&---------------------------------------------------------------------*
REPORT zhr_bank NO STANDARD PAGE HEADING LINE-SIZE 1023.

INCLUDE zhr_bank_top.
INCLUDE zhr_bank_pbo.
INCLUDE zhr_bank_pai.

START-OF-SELECTION.
  " SE38 direct run: enter main dynpro. SE93 dialog transactions skip this block.
  CALL SCREEN 0100.
