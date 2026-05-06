# Bank Account Inquiry (PA0009 Subtype 0) — SAP GUI/WebGUI and RAP OData V4

This document describes a **dual-track** implementation for an HR bank account inquiry and maintenance process:

1. **SAP GUI / WebGUI** — classical dynpro (module pool) with popup subscreens.
2. **OData V4 RAP** — CDS data model, behavior, service, and Fiori consumption patterns aligned with **Clean Core** (released APIs, clear layering, no direct modification of SAP standard).

Assumptions:

- **SAP S/4HANA** or **SAP ERP** with **HCM / Personnel Administration** and infotype **0009** (Bank Details).
- Custom fields on **PA0009** via a **customer include** (see section 2). Table **ZTHR0021** exists as specified.
- Company code for text resolution: **BUKRS = '1000'**, code group **ZCODE_GRUP = 'A004'**.
- Country for bank: **BANKS = 'KR'** (as in your specification).

---

## 1. Naming conventions (suggested)

| Layer | Prefix / pattern | Example |
|--------|------------------|---------|
| Package | `ZHR_<AREA>` | `ZHR_BANK` |
| Data element / domain | `ZDE_`, `ZDO_` | `ZDE_HR_BANK_CODE` |
| Database table (custom) | `ZTHR*` | `ZTHR0021` (given) |
| CDS interface (internal) | `ZI_` | `ZI_HR_BankAccount` |
| CDS consumption / BO projection | `ZC_` | `ZC_HR_BankAccount` |
| Behavior pool / saver | `ZBP_` | `ZBP_I_HR_BankAccount` |
| Service definition | `ZSD_` | `ZSD_HR_BANK_ACCOUNT` |
| Service binding | OData V4 UI | `ZSB_HR_BANK_ACCOUNT_O2` |
| Global classes | `ZCL_` | `ZCL_HR_BANK_INFOTYPE` |
| Transaction | `Z` + mnemonic | `ZBANK` |
| Message class | `ZHR_BANK` | `ZHR_BANK` |

Use **ADT (ABAP Development Tools)** for all RAP artifacts; use **Screen Painter** or ADT Screen Editor for dynpros.

---

## 2. PA0009 custom fields (Clean Core)

Standard table **PA0009** must not be changed with append structures in cloud/extensibility-restricted systems. On **on-prem** systems, custom fields are typically added via:

- **Customer include** in CI structure assigned to **PA0009** (transaction **SM30** / **PU00** configuration depends on release), or
- **Business Add-In / extensibility** where your release supports it.

For this design, the specification names:

- `ZBANKL` — bank key (parallel to or replacing use of `BANKL` depending on your design),
- `ZBANKN` — bank account number,
- `ZTNSMD` — move type.

**Recommendation:** For **bank key and account number**, use standard fields **`BANKL`** and **`BANKN`** on **PA0009** so **`HR_INFOTYPE_OPERATION`** and payroll interfaces stay aligned. Use **Z fields** only when a regulatory requirement forces a separate storage from standard **BANKL/BANKN**. If you must use Z fields, ensure the **P0009** structure used in **`HR_INFOTYPE_OPERATION`** includes those fields via the same CI include as the database table.

Document the CI include name (e.g. `CI_P0009`) in your technical specification.

---

## 3. High-level architecture

### 3.1 SAP GUI / WebGUI

```
Transaction ZBANK
    └── Program SAPMZHR_BANK (module pool type M)
            ├── Screen 0100 — main inquiry (table control / ALV grid optional)
            ├── Screen 0200 — modal screen for Change (bank listbox + account)
            ├── Screen 0300 — modal screen for Delete confirmation
            ├── GUI status ZHR_BANK_MAIN / ZHR_BANK_POPUP
            └── Classes:
                  ZCL_HR_BANK_GUI_APP      — orchestration, PERNR from sy-uname mapping
                  ZCL_HR_BANK_QUERY        — PA0009 + ZTHR0021 reads
                  ZCL_HR_BANK_INFOTYPE     — HR_INFOTYPE_OPERATION wrapper + messages
```

**Separation of concerns:**

- **Dynpro** — PBO/PAI only; minimal logic.
- **Application class** — selection, validation, navigation between screens.
- **Infotype class** — single place for `HR_INFOTYPE_OPERATION` (MOD/DEL), return codes, BAPIRETURN-style messaging.

### 3.2 RAP OData V4

```
Released / internal CDS:
    ZI_HR_BankAccount (root, transactional)
        └── Association to ZI_HR_BankCodeText (readonly value help / text)

Projection + metadata:
    ZC_HR_BankAccount
    + ZC_HR_BankAccount_M (metadata extension — labels, F4, side effects)

Behavior:
    ZI_HR_BankAccount behavior definition
        draft (optional) or strict transactional
        determination / validation
        actions: none mandatory — use standard update + delete
    ZBP_I_HR_BankAccount — saver class calling ZCL_HR_BANK_INFOTYPE

Service:
    ZSD_HR_BANK_ACCOUNT
    ZSB_HR_BANK_ACCOUNT_O2 — OData V4 UI binding
```

**Clean Core:**

- No **kernel** modifications; no implicit enhancements in SAP standard.
- Encapsulate **`HR_INFOTYPE_OPERATION`** in **`ZCL_HR_BANK_INFOTYPE`** (same class as GUI) so GUI and RAP share one **infotype gateway**.
- Authorizations: **P_ORGIN** (or successor **P_ORGINCON** / context-dependent HR auth in your release) with infotype **0009**, subtype **0**, and appropriate authorization levels (**R** read, **W** write, **D** delete). Wrap checks in **`ZCL_HR_BANK_AUTH`**.

---

## 4. Authorization

1. **HR master data:** **`P_ORGIN`** (classic) with **`INFTY = '0009'`**, **`SUBTY = '0'`** (or `SUBTY` interval).
2. **Self-service scenario:** If only **own** data is allowed, implement **context** via **`HR_READ_INFOTYPE_AUTH`** / **`RH_READ_INFTY`** patterns or **ESS** roles; alternatively map **`SY-UNAME`** → **`PERNR`** via **`PA0105`** or your **central user** mapping and then check **`HR_CHECK_EMPLOYEE_MASTER_DATA`** (release-specific; use SAP documentation for your version).
3. **Custom table ZTHR0021:** **`Z:ZTHR0021`** auth object (create **`ZAUTH_HR_BANK`** with **`ACTVT`** **03** display, **02** change if maintained via same app) or reuse **company code** authorization **F_BKPF_BUK** / **`K_BUKRS`** as appropriate for who may see bank master texts.

Document role **Z_R_HR_BANK_INQUIRY** and **Z_R_HR_BANK_MAINT** in Solution Manager / SAP Cloud ALM.

---

## 5. Shared logic: infotype operations

Central method (pseudo-signature):

- `MODIFY_SALARY_BANK( iv_pernr, iv_bankl, iv_bankn )` — builds **P0009**, calls **`HR_INFOTYPE_OPERATION`** with **`OPERATION = 'MOD'`**, **`VALIDITYBEGIN = sy-datum`**, **`VALIDITYEND = '99991231'`**, **`SUBTYPE = '0'`**.
- `DELETE_BANK_RECORD( iv_pernr, is_p0009_key )` — **`OPERATION = 'DEL'`** with **`VALIDITYBEGIN` / `VALIDITYEND`** from the **currently displayed** interval (your spec also mentions “delete where start date equals current date” — implement **exactly one** rule agreed with functional team; HR **DEL** usually requires the **exact validity** of the record to delete).

**Validity splitting:** **`HR_INFOTYPE_OPERATION`** with **`MOD`** performs time constraint handling per **VC** model of infotype 0009. You pass the **new** validity and record; SAP splits or adjusts overlapping intervals per configuration. If **no active record** exists, **`MOD`** may create; verify with SAP note / PA infotype documentation for your release — alternative is **`INS`** for insert when no record exists; your specification says **MOD** — implement **`MOD`** first; if integration tests fail on empty case, add **`HR_READ_INFOTYPE`** / **`PA_READ_XXXX`** check and branch to **`INS`** only if SAP documents allow.

---

## 6. SAP GUI / WebGUI — detailed design

### 6.1 Package structure

```
$ZHR_BANK (package)
  ├── ZHR_BANK_GUI (subpackage)     — M pool, screens, CUA
  ├── ZHR_BANK_CORE (subpackage)   — ZCL_HR_BANK_* shared
  └── ZHR_BANK_MSG (message class ZHR_BANK)
```

### 6.2 Transaction

- **SE93**: Transaction **`ZBANK`**, parameter transaction or dialog transaction calling **`SAPMZHR_BANK`** screen **0100**.

### 6.3 Screens

| Screen | Type | Purpose |
|--------|------|---------|
| 0100 | Main | Table control: col1 text, col2 BANKN, col3 pushbuttons Change / Delete |
| 0200 | Modal dialog | Change: account type text “급여”, bank F4/listbox, account number |
| 0300 | Modal dialog | Delete: text “Do you want to delete this account?” OK / Cancel |

**Flow:**

1. **0100 PBO** — load current user **PERNR**, read **PA0009** (subtype **0**, valid today), read **ZTHR0021** for **BANKL** text; fill table control.
2. **Change** — **`CALL SCREEN 0200 STARTING AT ... ENDING AT ...`** (or full-screen popup).
3. **0200 PAI** — on **Save**, call **`ZCL_HR_BANK_INFOTYPE`**, if success **`SET SCREEN 0` `LEAVE SCREEN`** then set a **static** flag **`gv_refresh_main = abap_true`** so **0100 PBO** refreshes (your rule: closing with **X** / **Close** sets **`gv_refresh_main = abap_false`**).
4. **Delete** — **`CALL SCREEN 0300`**. **OK** → **DEL** → on success same refresh flag as change success.

**“No refresh” on cancel:** Do not set refresh flag; **0100** PBO runs on return from modal — use **`SUPPRESS DIALOG`** pattern or **`gs_tc`-`*-fld`** unchanged: simplest is **in PBO of 0100**, only re-select if **`gv_refresh_after_popup = abap_true`**.

### 6.4 GUI status

- **PF-STATUS** `MAIN` for 0100: **Change**, **Delete**, **Back**, **Exit**.
- **PF-STATUS** `POPUP` for 0200/0300: **Save** / **OK**, **Cancel**, **Close** mapped to **E** cancel function.

### 6.5 WebGUI

Same module pool runs in **WebGUI** if:

- No **unsupported** controls (some obsolete controls may be restricted),
- **Sizing** for table control is acceptable,
- **F1/F4** behavior tested in browser.

Prefer **SAP GUI for HTML** compatibility matrix for your **NetWeaver** / **S/4** release.

---

## 7. RAP OData V4 — detailed design

### 7.1 Fiori Elements and “popups”

Pure **Fiori Elements (draft)** does not offer classic **modal dynpro** popups. **Technical options (Clean Core–friendly):**

| Option | Description |
|--------|-------------|
| **A. Object page + inline edit** | Root entity on list; **Edit** navigates to **object page** with fields editable; **Save** triggers RAP save. No separate popup. |
| **B. Fiori extension (freestyle fragment)** | **Fiori Elements extension** adds a **XML fragment** dialog (`sap.m.Dialog`) bound to a **local JSON model**; on **Confirm**, call **bound action** or **`PATCH`** via OData model. |
| **C. SideEffects** | After **PATCH**, **`SideEffects`** annotations refresh the main list — matches your “refresh after success”. |
| **D. Intent-based navigation** | Navigate to a **minimal freestyle** view only for change/delete; return with **router** `navBack`. |

**Recommendation for “comparison” with GUI:** Use **B** for **true** popup UX, or **A** for lowest TCO and full Fiori Elements compliance.

### 7.2 CDS root view (conceptual)

Root **must** expose fields needed for UI and for **DEL** key (begin/end, subty, pernr):

- **PERNR**, **SUBTY**, **BEGDA**, **ENDDA**, **BANKL**, **BANKN**, **BANKS** (from **PA0009**),
- **BankName** from association to **ZTHR0021** (filtered by **BUKRS**, **ZCODE_GRUP**, validity).

Use **`@AccessControl.authorizationCheck: #CHECK`** with a **CDS access control** DCL that delegates to **`P_ORGIN`** via **`MAPPED INSTANCE`** (S/4 HCM CDS DCL patterns — adjust to your system’s supported DCL on HR tables; if DCL on **PA0009** is not supported, use **`#NOT_ALLOWED`** on S/4HANA Cloud public cloud and move read to **API**; on-prem many customers use **SACD** with **`AUTHORITY-CHECK`** in **RAP handler** instead).

### 7.3 Behavior definition (essentials)

- **`strict ( 0 );`** or **`lock master`** as required.
- **`update;`**
- **`delete;`**
- **`field ( readonly ) PERNR, SUBTY;`** if self-service should not change keys.
- **`determination` on modify** — default **BANKS = 'KR'** if empty.
- **`validation`** — bank code must exist in **ZTHR0021** for **BUKRS 1000**, group **A004**, valid today.

### 7.4 Saver / **`HR_INFOTYPE_OPERATION`**

In **`METHOD save_modified`** of **`ZBP_I_HR_BankAccount`** (or dedicated saver behavior implementation):

- Loop **`failed`** / **`reported`** first for early exit.
- For **`update`** instances: map RAP image → **P0009**, call **`ZCL_HR_BANK_INFOTYPE=>MODIFY_SALARY_BANK`**.
- For **`delete`**: call **`DELETE_BANK_RECORD`** with displayed validity.

Map **`sy-subrc`** / **return** structure from **`HR_INFOTYPE_OPERATION`** into **`failed-bankaccount`** and **`reported`** with **message** from **`ZCL_HR_BANK_MESSAGE`**.

---

## 8. Step-by-step implementation guide

### Phase 0 — Basis

1. Create package **`ZHR_BANK`** (software component **`Z`** or customer namespace).
2. Create message class **`ZHR_BANK`**.
3. Ensure **CI include** on **PA0009** / **P0009** is consistent (if Z fields used).

### Phase 1 — Core ABAP

1. Create **`ZCL_HR_BANK_QUERY`** — methods **`READ_ACTIVE_SALARY_ACCOUNT`**, **`READ_BANK_LIST`**, **`READ_BANK_TEXT`**.
2. Create **`ZCL_HR_BANK_INFOTYPE`** — **`MODIFY_SALARY_BANK`**, **`DELETE_BANK_RECORD`** wrapping **`HR_INFOTYPE_OPERATION`**.
3. Create **`ZCL_HR_BANK_AUTH`** — **`CHECK_DISPLAY`**, **`CHECK_MAINTAIN`**.
4. Unit tests **`ZCL_HR_BANK_QUERY`** with **`ABAP_UNIT`** test doubles for **PA0009** / **ZTHR0021** (if test data API available).

### Phase 2 — SAP GUI

1. Program **`SAPMZHR_BANK`** (type **M**), screens **0100**, **0200**, **0300**.
2. Define **table control** `TC_BANK` on **0100** (optional: use **CL_GUI_ALV_GRID** in container for nicer WebGUI).
3. PBO/PAI modules call **`ZCL_HR_BANK_GUI_APP`**.
4. **SE93** **`ZBANK`**.

### Phase 3 — RAP

1. CDS **`ZI_HR_BankAccount`** (root) + **`ZI_HR_BankCodeText`** (text / value help).
2. CDS projection **`ZC_HR_BankAccount`** + **`ZC_HR_BankAccount_M`** metadata extension.
3. Behavior definition for **`ZI_HR_BankAccount`**; implementation class **`ZBP_I_HR_BankAccount`**.
4. Service definition **`ZSD_HR_BANK_ACCOUNT`**, binding **OData V4 – UI**.
5. Publish on **SAP Gateway** / **Embedded Steampunk** as per your landscape.
6. Fiori app: **List Report** / **Worklist** + **Object Page** or **FE extension** for popup (section 7.1).

### Phase 4 — Test

1. **GUI:** change, cancel, delete confirm/cancel, refresh only after success.
2. **RAP:** OData read filter by **logon user** mapping (implementation-specific), update/delete, message display, **SideEffects** refresh.

---

## 9. Exact code locations (reference)

| Artifact | Where to create |
|----------|------------------|
| Module pool | ADT: **New** → **ABAP Program** → type **Module Pool**, name **`SAPMZHR_BANK`** |
| Screens | **Double-click** program → **Screens** |
| GUI status | **Goto** → **GUI Status** |
| Classes | **New** → **ABAP Class** |
| CDS | **New** → **Core Data Services** → **Data Definition** |
| Behavior | **New** → **Behavior Definition** |
| Service | **New** → **Service Definition** / **Service Binding** |

---

## 10. Source code samples (repository)

Runnable **ABAP** reference implementations (adjust names/includes to your system) live under:

- `references/abap/zcl_hr_bank_infotype.abap` — **`HR_INFOTYPE_OPERATION`** wrapper.
- `references/abap/zcl_hr_bank_query.abap` — **PA0009** + **ZTHR0021** queries.
- `references/abap/zhr_bank_sapm_gui_modules.abap` — **PBO/PAI** module stubs calling shared classes.
- `references/rap/` — CDS / BDEF / BIMP text samples (copy into ADT).

**Note:** CDS and behavior files in `references/rap/` use **comment headers**; import them through **ADT** (not SE80) for full syntax support.

**RAP root key fields:** The sample root view **`ZI_HR_BankAccount`** uses **`PERNR, INFTY, SUBTY, BEGDA, ENDDA`** as the **key** (typical **PA0009** primary key in on-prem systems). If your release uses a different key definition (for example including **`OBJPS`** / **`SPRPS`**), adjust the **`key`** list and the **`persistent table`** mapping in the behavior definition accordingly before activation.

**Managed RAP on `PA0009`:** A fully **managed** behavior with **`persistent table pa0009`** is only supported where your **ABAP Platform / HCM** combination allows transactional RAP on that table. If activation fails, switch to **unmanaged** RAP with an **ABAP** persistence handler that still calls **`ZCL_HR_BANK_INFOTYPE`** (same infotype gateway, still Clean Core from an encapsulation perspective).

---

## 11. OData service registration (reminder)

1. Activate all CDS + BDEF + classes.
2. **`ZSB_HR_BANK_ACCOUNT_O2`** → **Publish** local service endpoint.
3. **/IWFND/MAINT_SERVICE** or **SAP Gateway** hub — depending on hub vs embedded.
4. **Fiori launchpad** — tile pointing to **Semantic Object** / **Action** you define in **`manifest.json`**.

---

## 12. Glossary (process ↔ technical)

| Business | Technical |
|----------|-----------|
| Current valid account | **PA0009** **SUBTY = '0'**, **BEGDA <= sy-datum <= ENDDA** |
| Bank label | **ZTHR0021** where **ZCODE = PA0009-BANKL** and code group **A004** |
| Change | **MOD** + **P0009** with new **BANKL/BANKN** |
| Delete | **DEL** with key validity from UI row |

---

*End of implementation guide. Copy ABAP/RAP samples from `references/` into your development system and adapt to your SAP release and authorization concept.*
