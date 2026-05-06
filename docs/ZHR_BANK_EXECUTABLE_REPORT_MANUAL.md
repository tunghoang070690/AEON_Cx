# ZHR_BANK — Executable ABAP Report + Full OOP (Copy‑Paste Manual)

This manual targets **restricted SAP systems**: **no Git/abapGit**. Every artifact is **plain ABAP** created via **SE38 / SE24 / SE51 / SE41 / SE93**.

## Architecture decisions (mandatory SAP constraints)

| Constraint | How this solution complies |
|------------|----------------------------|
| **No module pool** | Program **`ZHR_BANK`** is **type 1 Executable program**. Dynpros belong to this report. |
| **Dynpro MODULEs cannot live in SE24 classes** | **`INCLUDE ZHR_BANK_PBO` / `ZHR_BANK_PAI`** contain **only** `MODULE … ENDMODULE.` stubs that delegate to **`ZCL_HR_BANK_UI`**. All business/UI logic is OOP. |
| **Screen fields must bind to report globals** | **`INCLUDE ZHR_BANK_TOP`** declares **`OK_CODE`**, **`GV_CH_BANKL`**, **`GV_CH_BANKN`** for dynpro binding. The UI controller receives values via **MODULE parameters** (`IMPORTING`/`CHANGING`) — global SE24 classes never dereference report globals directly. |
| **No direct UPDATE/DELETE on PA0009** | Writes only via **`HR_INFOTYPE_OPERATION`** in **`ZCL_HR_BANK_GATEWAY`**. |
| **Reads encapsulated** | **`ZCL_HR_BANK_REPOSITORY`** implements **`ZIF_HR_BANK_REPOSITORY`** — all **`SELECT`** on **`PA0009`** / **`ZTHR0021`** live here. |

## Exact object inventory

| Object type | Name | Purpose |
|-------------|------|---------|
| Exception class | **`ZCX_HR_BANK`** | Unified domain/HCM errors (`MV_TEXT`, `MV_CODE`). |
| Class | **`ZCL_HR_BANK_TYPES`** | DTO types + constants (no logic). |
| Interface | **`ZIF_HR_BANK_REPOSITORY`** | Repository contract. |
| Class | **`ZCL_HR_BANK_REPOSITORY`** | SELECT encapsulation + `FACTORY` returning interface ref. |
| Class | **`ZCL_HR_BANK_GATEWAY`** | `HR_INFOTYPE_OPERATION` MOD/DEL. |
| Class | **`ZCL_HR_BANK_CONTEXT`** | Resolve **`PERNR`** for **`SY-UNAME`**. |
| Class | **`ZCL_HR_BANK_VALIDATOR`** | Delete rule (**`BEGDA = SY-DATUM`**) + change checks. |
| Class | **`ZCL_HR_BANK_SERVICE`** | Application service orchestrating validator + repo + gateway. |
| Class | **`ZCL_HR_BANK_UI`** | Dynpro + ALV controller (`CL_GUI_CUSTOM_CONTAINER` / `CL_GUI_ALV_GRID`). |
| Report | **`ZHR_BANK`** | Main program + includes (TOP/PBO/PAI). |
| Includes | **`ZHR_BANK_TOP`**, **`ZHR_BANK_PBO`**, **`ZHR_BANK_PAI`** | Global screen vars + MODULE shells. |
| Transaction | **`ZHRB`** (suggested) | Dialog transaction → screen **0100**. |
| GUI statuses | **`ZHRF_MAIN`**, **`ZHRF_POP_CH`**, **`ZHRF_POP_DL`** | Application toolbar. |
| GUI titles | **`ZHRF_MAIN`**, **`ZHRF_POP_CH`**, **`ZHRF_POP_DL`** | Title bars (text elements). |

## Creation order (follow strictly)

1. **SE24** → Exception **`ZCX_HR_BANK`** — copy `ZCX_HR_BANK.clas.abap`.
2. **SE24** → **`ZCL_HR_BANK_TYPES`** — copy `ZCL_HR_BANK_TYPES.clas.abap`.
3. **SE24** → Interface **`ZIF_HR_BANK_REPOSITORY`** — copy `ZIF_HR_BANK_REPOSITORY.intf.abap`.
4. **SE24** → **`ZCL_HR_BANK_REPOSITORY`** — **Interfaces** tab implement **`ZIF_HR_BANK_REPOSITORY`**. Copy `ZCL_HR_BANK_REPOSITORY.clas.abap`.
5. **SE24** → **`ZCL_HR_BANK_GATEWAY`** — copy `ZCL_HR_BANK_GATEWAY.clas.abap`.
6. **SE24** → **`ZCL_HR_BANK_CONTEXT`** — copy `ZCL_HR_BANK_CONTEXT.clas.abap` — **customize** `GET_PERSONNEL_NUMBER` beyond **`GET PARAMETER ID 'PER'`** for production.
7. **SE24** → **`ZCL_HR_BANK_VALIDATOR`** — copy `ZCL_HR_BANK_VALIDATOR.clas.abap`.
8. **SE24** → **`ZCL_HR_BANK_SERVICE`** — copy `ZCL_HR_BANK_SERVICE.clas.abap`.
9. **SE24** → **`ZCL_HR_BANK_UI`** — copy `ZCL_HR_BANK_UI.clas.abap`.
10. **SE38** → Create **`ZHR_BANK`**, type **Executable program**, **without** selection-screen — paste `ZHR_BANK.prog.abap` body.
11. **SE38** → Create includes **`ZHR_BANK_TOP`**, **`ZHR_BANK_PBO`**, **`ZHR_BANK_PAI`** as **Include programs** (type **I**) — paste respective files.
12. **SE38** → **Attributes** of **`ZHR_BANK`**: **Edit → Change…** set **Fixed point arithmetic** if required by project standards; under **Load distribution / Logical database** leave empty.
13. **SE51** → Screens **0100**, **0200**, **0300** on program **`ZHR_BANK`** — follow layout tables below.
14. **SE41** → GUI statuses / titles — section below.
15. **SE93** → Transaction **`ZHRB`** — Dialog transaction, target **`ZHR_BANK`** screen **0100**.
16. **SU01** → Set user parameter **`PER`** for testers **or** implement **`ZCL_HR_BANK_CONTEXT`**.

## SE38 program wiring (`ZHR_BANK`)

Main program must contain:

```abap
REPORT zhr_bank NO STANDARD PAGE HEADING LINE-SIZE 1023.

INCLUDE zhr_bank_top.
INCLUDE zhr_bank_pbo.
INCLUDE zhr_bank_pai.

START-OF-SELECTION.
  CALL SCREEN 0100.
```

**Behavior:**

- **SE93 dialog transaction** jumps directly to dynpro **0100** — **`START-OF-SELECTION` is skipped** (SAP standard).
- **SE38 → Execute** runs **`START-OF-SELECTION`** then **`CALL SCREEN 0100`** — useful for debugging.

## SE51 — Screen layouts (exact technical mapping)

### Screen **0100** — Main (full screen)

**Attributes**

| Attribute | Value |
|-----------|-------|
| Screen type | Normal screen |
| Next screen | **0100** (stay on main until `LEAVE PROGRAM`) |
| Cursor field | Optional |
| Screen group | blank |

**Screen Painter elements** (Desktop → Full screen grid ~120×50 depending on GUI size — positions below use **line / column** from Screen Painter ruler):

| Line | Col | Element type | Name | Visible length | Visual text | Fct code |
|------|-----|--------------|------|----------------|-------------|----------|
| 001 | 001 | Text field | *(none)* | 60 | `Salary bank account (current validity)` | — |
| 003 | 001 | **Custom Control** | **`CC_MAIN`** | Width **120** chars, height **12** lines | — | — |
| 018 | 002 | Pushbutton | *(auto)* | — | `Change` | **`CHNG`** |
| 018 | 030 | Pushbutton | *(auto)* | — | `Delete` | **`DEL`** |
| 024 | 001 | OK field | **`OK_CODE`** | 20 | *(blank/invisible)* | — |

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

**MODULE names must match** includes `ZHR_BANK_PBO` / `ZHR_BANK_PAI` exactly.

---

### Screen **0200** — Change (modal)

**Attributes**

| Attribute | Value |
|-----------|-------|
| Screen type | **Modal dialog box** |
| Next screen | **0** |

**Elements**

| Line | Col | Element | Name | Attributes | Fct |
|------|-----|---------|------|------------|-----|
| 001 | 001 | Text | — | Output only | `Account type` |
| 001 | 020 | Text | — | Output only literal | **`급여`** |
| 003 | 001 | Text | — | `Bank` | — |
| 003 | 015 | **Listbox / dropdown** | **`GV_CH_BANKL`** | Input, length = length of **`ZTHR0021-ZCODE`** | — |
| 005 | 001 | Text | — | `Account number` | — |
| 005 | 020 | Input/Output | **`GV_CH_BANKN`** | Type **`BANKN`** | — |
| 012 | 002 | Pushbutton | — | `Save` | **`SAVE`** |
| 012 | 030 | Pushbutton | — | `Cancel` | **`CANC`** |
| 024 | 001 | OK field | **`OK_CODE`** | 20 | | |

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0200.

PROCESS AFTER INPUT.
  MODULE user_command_0200.
```

**Listbox note:** `ZCL_HR_BANK_UI` calls **`VRM_SET_VALUES`** with id **`GV_CH_BANKL`** — the screen field name **must match exactly**.

---

### Screen **0300** — Delete confirm (modal)

**Attributes:** Modal dialog, next screen **0**.

**Elements**

| Line | Col | Element | Text / Name | Fct |
|------|-----|---------|---------------|-----|
| 002 | 002 | Text | `Do you want to delete this account?` | — |
| 008 | 002 | Pushbutton | `Yes` | **`YES`** |
| 008 | 020 | Pushbutton | `Cancel` | **`CANC`** |
| 024 | 001 | **`OK_CODE`** | | |

**Flow logic**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0300.

PROCESS AFTER INPUT.
  MODULE user_command_0300.
```

## SE41 — GUI statuses & application toolbar

Create GUI status + titles on program **`ZHR_BANK`**.

### Status **`ZHRF_MAIN`** (main)

Function keys (example mapping):

| Code | PF key | Text |
|------|--------|------|
| **CHNG** | F5 | Change |
| **DEL** | F6 | Delete |
| **BACK** | F3 | Back |
| **EXIT** | F12 | Exit |

### Status **`ZHRF_POP_CH`**

| Code | Text |
|------|------|
| **SAVE** | Save |
| **CANC** | Cancel |

### Status **`ZHRF_POP_DL`**

| Code | Text |
|------|------|
| **YES** | Yes |
| **CANC** | Cancel |

### Titles (GUI titlebar texts)

| Title ID | Text |
|----------|------|
| **ZHRF_MAIN** | `Salary bank account` |
| **ZHRF_POP_CH** | `Change salary bank` |
| **ZHRF_POP_DL** | `Confirm deletion` |

These IDs are referenced in **`ZCL_HR_BANK_UI`** via `SET TITLEBAR 'ZHRF_MAIN'` etc.

## SE93 — Transaction

| Field | Value |
|-------|-------|
| Transaction | **`ZHRB`** |
| Type | Dialog transaction |
| Program | **`ZHR_BANK`** |
| Screen | **`0100`** |

## Standard SAP objects referenced (no copying required)

| SAP object | Usage | Where |
|------------|-------|------|
| **`HR_INFOTYPE_OPERATION`** | MOD/DEL infotype **0009** | `ZCL_HR_BANK_GATEWAY` |
| **`VRM_SET_VALUES`** | Populate listbox **`GV_CH_BANKL`** | `ZCL_HR_BANK_UI=>FILL_BANK_LISTBOX_VRM` |
| **`CL_GUI_CUSTOM_CONTAINER` / `CL_GUI_ALV_GRID`** | Main grid | `ZCL_HR_BANK_UI` |
| **`PA0009`** / **`ZTHR0021`** | Master data | Repository only |
| **`P0009`** structure | FM parameter **`RECORD`** | Built from **`PA0009`** row via **`MOVE-CORRESPONDING`** in repository |

**Nothing** from SAP must be “copied” into customer namespace — only **called**.

## Full source bundle (single text file)

All `.abap` sources concatenated in creation-friendly order:

`docs/ZHR_BANK_COPY_PASTE_SOURCE_BUNDLE.txt`

Individual fragments remain under `enterprise/zhr_bank/` for partial edits.

## WebGUI / SAP GUI for HTML notes

- **`CL_GUI_ALV_GRID`** is generally supported; validate against your **NetWeaver / UI** version.
- If the grid does not render, replace **`ensure_alv_created` / `refresh_alv_display`** with a **table control** bound to the same **`MT_ALV`** — repository/service layers remain unchanged.

## Clean Core remark on PA0009 append fields

Custom **`ZBANKL` / `ZBANKN` / `ZTNSMD`** must be maintained consistently with **`BANKL` / `BANKN`** if payroll reads standard fields. Uncomment / extend the commented **`ASSIGN COMPONENT`** block in **`ZCL_HR_BANK_GATEWAY=>MODIFY_SALARY_BANK`** when your **`P0009`** CI requires it.

---

*End of manual.*
