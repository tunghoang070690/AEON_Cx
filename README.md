# AEON_Cx

## HR bank account — SAP GUI / WebGUI (Dynpro)

Step-by-step enterprise implementation for bank inquiry and maintenance (infotype **0009**, subtype **0**, **`HR_INFOTYPE_OPERATION`**) is documented here:

- [docs/Z_HR_BANK_GUI_WEBGUI_IMPLEMENTATION.md](docs/Z_HR_BANK_GUI_WEBGUI_IMPLEMENTATION.md)

### Reference sources (copy into SAP)

- Module pool **SAPMZHR_BANK** includes: [references/gui/](references/gui/)
- Global classes & exceptions: [references/abap/](references/abap/)

Adjust SE51 screen field names and **PERNR → user** mapping (`ZCL_HR_BANK_CONTEXT`) to your landscape before productive use.
