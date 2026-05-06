# HR Bank Account (PA0009 / ZTHR0021) — SAP GUI & WebGUI (Dynpro) — Full Implementation

This document is the **enterprise delivery guide** for the **SAP GUI / WebGUI** version of the bank salary account inquiry and maintenance process. It assumes **HCM Personnel Administration** (infotype **0009**, subtype **0**), custom table **ZTHR0021**, and optional **CI** fields on **PA0009** (`ZBANKL`, `ZBANKN`, `ZTNSMD`).

A **copy-paste–ready** code package is in the repository:

| Content | Path |
|--------|------|
| Module pool (main, TOP, PBO, PAI, subroutines) | `references/gui/` |
| Global classes (query, infotype, context) | `references/abap/` |
| Exception classes | `references/abap/zcx_*.abap` |

**Transaction (suggested):** `ZBANK`  
**Module pool (suggested):** `SAPMZHR_BANK` (program type **M**)

---

## 1. Clean Core & technology compliance

- **No modifications** to SAP standard; all logic in custom **Z** namespace.
- **HR API:** `HR_INFOTYPE_OPERATION` (required for infotype maintenance).
- **Modern ABAP:** `SELECT ... INTO @data`, value operators, `TRY`/`CATCH` for `ZCX_HR_BANK_INFOTYPE`.
- **Encapsulation:** `ZCL_HR_BANK_QUERY` (read), `ZCL_HR_BANK_INFOTYPE` (MOD/DEL), `ZCL_HR_BANK_CONTEXT` (user → PERNR).
- **Custom fields on PA0009:** mirror `BANKL`/`BANKN` to `ZBANKL`/`ZBANKN` in `ZCL_HR_BANK_INFOTYPE` when your **P0009** include requires it (code comments in class).

---

## 2. Recommended package structure (SE80 / ADT)

| Package / subpackage | Purpose |
|----------------------|---------|
| `ZHR_BANK` | Root |
| `ZHR_BANK_CORE` | `ZCL_HR_BANK_*`, exceptions |
| `ZHR_BANK_GUI` | Module pool `SAPMZHR_BANK`, screens, GUI statuses, texts |
| `ZHR_BANK_MSG` | Message class `ZHR_BANK` (optional; samples use `MESSAGE \|...\|` literal ) |

Create packages with **SE80 → Workbench → Edit → Other object → Package** or ADT.

---

## 3. Naming conventions (summary)

| Object type | Pattern | Example |
|-------------|---------|---------|
| Module pool | `SAPM` + app | `SAPMZHR_BANK` |
| Includes | `MZHR_BANK` + suffix | `MZHR_BANKTOP`, `MZHR_BANKO01`, … |
| Transaction | `Z` + mnemonic | `ZBANK` |
| Classes | `ZCL_` | `ZCL_HR_BANK_QUERY` |
| Exceptions | `ZCX_` | `ZCX_HR_BANK_INFOTYPE` |
| GUI status | Functional name | `MAIN`, `POPUP_CH`, `POPUP_DL` |

---

## 4. Global classes (SE24 / ADT)

Create & activate in this order:

1. **`ZCX_HR_BANK_INFOTYPE`** — see `references/abap/zcx_hr_bank_infotype.abap`
2. **`ZCX_HR_BANK_NO_PERNR`** — see `references/abap/zcx_hr_bank_no_pernr.abap`
3. **`ZCL_HR_BANK_INFOTYPE`** — see `references/abap/zcl_hr_bank_infotype.abap`
4. **`ZCL_HR_BANK_QUERY`** — see `references/abap/zcl_hr_bank_query.abap`
5. **`ZCL_HR_BANK_CONTEXT`** — see `references/abap/zcl_hr_bank_context.abap` (**implement** your **UNAME → PERNR** strategy where the comment indicates)

**PERNR resolution:** The sample uses **`GET PARAMETER ID 'PER'`** first (user parameter in SU01). Replace or extend with your standard (ESS mapping / Z-table / BAdI).

---

## 5. Module pool source (SE38 / ADT)

### 5.1 Program attributes

- **Type:** **Module pool** (**M**)
- **Name:** `SAPMZHR_BANK`
- **Application area:** Customer HR (optional)

### 5.2 Includes

Copy from repository:

| Include | Role |
|---------|------|
| Main program line | `references/gui/sapmzhr_bank.prog.abap` |
| TOP | `references/gui/mzhr_banktop.prog.abap` |
| PBO | `references/gui/mzhr_banko01.prog.abap` |
| PAI | `references/gui/mzhr_banki01.prog.abap` |
| Forms / ALV | `references/gui/mzhr_bankf01.prog.abap` |

**Note:** Rename includes only if your naming standard differs; **keep include names consistent** in SE38.

### 5.3 First screen (transaction entry)

**SE80 → Program → SAPMZHR_BANK → Attributes**

Set **Screen sequence** / **Initial screen** to **0100** (after screens exist).

---

## 6. Screen definitions (SE51 / Screen Painter)

Create screens under program **`SAPMZHR_BANK`**.

### Screen **0100** — Main inquiry (next screen **0**)

| Element | Type | Name | Notes |
|---------|------|------|--------|
| Custom control | Custom Control | `CC_MAIN` | Full width; holds ALV grid |
| Pushbutton | Text | — | **Change**, function code **CHNG** |
| Pushbutton | Text | — | **Delete**, function code **DEL** |
| OK field | OK box | `OK_CODE` | Type **OKCODE** (or CHAR20), **sy-ucomm** compatible |

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

### Screen **0200** — Change (modal dialog)

**Attributes:** **Modal dialog box**, **next screen** **0**.

| Element | Type | Name | Notes |
|---------|------|------|--------|
| Text field | Output only | — | Label **Account type** / value **급여** (static text) |
| Dropdown/listbox | Input | `GV_CH_BANKL` | Domain length = `ZTHR0021-ZCODE` |
| Input | Input/Output | `GV_CH_BANKN` | Maps to `GV_CH_BANKN` in TOP (same spelling) |
| Pushbutton | Save | **SAVE** |
| Pushbutton | Close/Cancel | **CANC** |
| OK | `OK_CODE` | | |

**Important:** The listbox field name must match **VRM** id in `MZHR_BANKF01` → **`VRM_SET_VALUES`** (`GV_CH_BANKL`).

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0200.

PROCESS AFTER INPUT.
  MODULE user_command_0200.
```

### Screen **0300** — Delete confirmation (modal dialog)

**Attributes:** **Modal dialog box**, **next screen** **0**.

| Element | Notes |
|---------|--------|
| Text | `Do you want to delete this account?` |
| Button **Yes** | FC **YES** |
| Button **Close/Cancel** | FC **CANC** |
| **OK_CODE** | |

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0300.

PROCESS AFTER INPUT.
  MODULE user_command_0300.
```

---

## 7. GUI statuses & title bars (SE41 / SE51)

### Status **MAIN** (screen 0100)

| Code | Function text | Icon (optional) |
|------|----------------|-----------------|
| **CHNG** | Change | |
| **DEL** | Delete | |
| **BACK** | Back | Standard |
| **EXIT** | Exit | Standard |

Assign function keys (e.g. **F8** Change, **F9** Delete) per UX policy.

### Status **POPUP_CH** (screen 0200)

| Code | Text |
|------|------|
| **SAVE** | Save |
| **CANC** | Cancel |

### Status **POPUP_DL** (screen 0300)

| Code | Text |
|------|------|
| **YES** | Yes |
| **CANC** | Cancel |

### Title bars

Create texts **MAIN**, **POP_CH**, **POP_DL** (short descriptions for window titles).

---

## 8. ALV handling (Screen 0100)

- **Control:** `CL_GUI_CUSTOM_CONTAINER` + `CL_GUI_ALV_GRID`.
- **Table:** `GT_ALV` with **Bank name** (`ZTHR0021-ZCODE_TEXT1`) and **Account** (`BANKN`).
- **Lifecycle:** Create objects once (`GO_CONTAINER` initial); on each PBO after reload, **`REFRESH_TABLE_DISPLAY`** with stable rows/cols.

**WebGUI:** SAP GUI for HTML generally supports **Docking / Custom Container + ALV**. Test in your NetWeaver/S/4 release; if grid rendering fails, **fallback:** replace ALV with **table control** bound to `GT_ALV` (same internal table, same modules).

---

## 9. Popup handling & refresh semantics

| Action | `GV_MAIN_MUST_REFRESH` |
|--------|-------------------------|
| Successful **Save** on change popup | **abap_true** → next main PBO reloads from DB |
| **Cancel/Close** on change/delete popup | unchanged (**false** after last successful load) → **no** reload |
| Successful **Yes** on delete | **abap_true** |

Implementation detail: **`CALL SCREEN` modal** returns to **0100**; **0100 PBO** runs again. Reload occurs **only** when `GV_MAIN_MUST_REFRESH` is set **before** leaving the popup.

---

## 10. Business rules wired in code

| Rule | Implementation |
|------|----------------|
| Active salary record | `ZCL_HR_BANK_QUERY=>READ_ACTIVE_SALARY_ACCOUNT` — `SUBTY = 0`, validity includes **SY-DATUM** |
| Bank text | `ZTHR0021` — `BUKRS = 1000`, `ZCODE_GRUP = A004`, code = `PA0009-BANKL` |
| Change | `HR_INFOTYPE_OPERATION` **MOD** via `ZCL_HR_BANK_INFOTYPE=>MODIFY_SALARY_BANK` |
| Delete confirmation row | `READ_PA0009_RECORD` builds **`P0009`** payload |
| Delete only if **BEGDA = SY-DATUM** | `EXECUTE_DELETE_FROM_POPUP` (see `MZHR_BANKF01`) |

---

## 11. Authorization

Before go-live, insert **`AUTHORITY-CHECK`** for **`P_ORGIN`** (or successor) for infotype **0009**, subtype **0**, with **R** (inquiry) / **W** (change) / **D** (delete) as required. A template comment is in **`LOAD_MAIN_DATA`**.

---

## 12. Transaction code **ZBANK** (SE93)

1. **SE93** → Create → Transaction with parameters (dialog).
2. Transaction code: **`ZBANK`**.
3. Start object: **Transaction** / Program **SAPMZHR_BANK** / Screen **0100** (per program attributes).

---

## 13. Step-by-step creation order (checklist)

1. SE11 / ADT: confirm **ZTHR0021** and **PA0009** CI fields exist.
2. Create package hierarchy **`ZHR_BANK_*`**.
3. SE24: exceptions → **`ZCL_HR_BANK_QUERY`** → **`ZCL_HR_BANK_INFOTYPE`** → **`ZCL_HR_BANK_CONTEXT`** (customize PERNR).
4. SE38: create program **`SAPMZHR_BANK`**, type **M**, add includes from repo.
5. SE51: screens **0100**, **0200**, **0300** as above.
6. SE41: statuses **MAIN**, **POPUP_CH**, **POPUP_DL** + title bars.
7. SE93: **`ZBANK`**.
8. SU01 (test user): set **`PER`** parameter **or** implement **`ZCL_HR_BANK_CONTEXT`**.
9. PA30 / test data: create infotype **0009** subtype **0** for test **PERNR**.
10. Test: inquiry → change → cancel (no refresh) → change → save (refresh) → delete rules.

---

## 14. Troubleshooting

| Symptom | Check |
|---------|--------|
| Empty PERNR | **Context** class + SU01 parameter **`PER`**. |
| Listbox empty | **ZTHR0021** data for **1000 / A004 / validity**. |
| MOD fails | **`HR_INFOTYPE_OPERATION`** return — see **`DISPLAY_INFOTYPE_EXCEPTION`**. |
| WebGUI ALV blank | Custom container name **`CC_MAIN`** matches screen; test **SAP GUI for HTML** note for your release. |

---

*This guide matches the reference sources under `references/gui` and `references/abap`. Adjust DDIC names (`P0009` vs `PA0009` lines) if your system uses a different infotype structure name.*
