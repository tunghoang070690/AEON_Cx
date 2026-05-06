@EndUserText.label: 'HR Bank Code Text (ZTHR0021)'
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_HR_BankCodeText
  as select from zthr0021
{
  key bukrs        as CompanyCode,
  key zcode_grup   as CodeGroup,
  key zcode        as BankCode,
  key begda        as ValidFrom,
  key endda        as ValidTo,
      zcode_text1  as BankName,
      zcode_text2  as BankName2,
      zcode_descr  as BankDescription
}
where bukrs      = '1000'
  and zcode_grup = 'A004'
