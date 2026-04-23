# HR Bank Account App - RAP OData V4 (Fiori Elements)

## 1) Objects to create in ADT (in this order)

1. Interface: `ZIF_HR_BANK_CONSTANTS`
2. Exception class: `ZCX_HR_BANK_ACCOUNT`
3. Global class (service layer): `ZCL_HR_BANK_SERVICE`
4. Global class (query provider main): `ZCL_HR_BANK_QP` (interface `IF_RAP_QUERY_PROVIDER`)
5. Global class (query provider option): `ZCL_HR_BANK_OPT_QP` (interface `IF_RAP_QUERY_PROVIDER`)
6. CDS abstract entity: `ZI_HR_BANK_CHG_PARAM`
7. CDS root custom entity: `ZI_HR_BANK_ACCOUNT`
8. CDS root custom entity: `ZI_HR_BANK_OPTION`
9. Behavior definition: `ZI_HR_BANK_ACCOUNT`
10. Behavior implementation class: `ZBP_I_HR_BANK_ACCOUNT`
11. Metadata extension: `ZC_HR_BANK_ACCOUNT_MDE`
12. Metadata extension: `ZC_HR_BANK_CHG_PARAM_MDE` (for action dialog + value help)
13. Service definition: `ZUI_HR_BANK_SRV`
14. Service binding: `ZUI_HR_BANK_SRV` type **OData V4 - UI**
15. Publish service binding and use preview for Fiori Elements test

---

## 2) Mapping with your requirement

- Default screen query:
  - `PA0009` with `PERNR(logon user)`, `SUBTY = '0'`, `BEGDA <= SY-DATUM`, `ENDDA >= SY-DATUM`
  - Bank text from `ZTHR0021` with `BUKRS = '1000'`, `ZCODE_GRUP = 'A004'`, active date range
- Change button:
  - Action `ChangeAccount` (dialog parameter from abstract entity `ZI_HR_BANK_CHG_PARAM`)
  - Execute `HR_INFOTYPE_OPERATION` with `OPERATION = 'MOD'`
- Delete button:
  - Action `DeleteAccount`
  - Execute `HR_INFOTYPE_OPERATION` with `OPERATION = 'DEL'`
  - Guard: delete only when `BEGDA = SY-DATUM`
- Refresh behavior:
  - On successful action, FE rebinds list and shows latest data (blank if no active record)

---

## 3) Fiori Elements popup note

- In Fiori Elements OData V4, action with parameter opens a standard dialog automatically.
- Therefore your "Change popup" requirement is natively supported.
- Close/X behavior returns to list without forced backend refresh.

---

## 4) WebGUI comparison version (proposal)

Create classic dynpro transaction `ZHR_BANK_WEBGUI`:
- Screen 0100: 3 columns (Bank Text / Bank Account / Change + Delete pushbuttons)
- Screen 0200: Change popup (bank listbox + account input)
- Screen 0300: Delete confirm popup

Reuse **same service class** `ZCL_HR_BANK_SERVICE` in WebGUI PAI modules to keep one backend logic source (clean core and no duplicated logic).
