@EndUserText.label: 'HR Salary Bank Account (PA0009)'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZI_HR_BankAccount
  as select from pa0009 as SalaryBank
  association [0..1] to ZI_HR_BankCodeText as _BankText
    on  SalaryBank.bankl = _BankText.BankCode
{
  key SalaryBank.pernr as PersonnelNumber,
  key SalaryBank.infty as Infotype,
  key SalaryBank.subty as Subtype,
  key SalaryBank.begda as ValidFrom,
  key SalaryBank.endda as ValidTo,
      SalaryBank.objps as ObjectID,
      SalaryBank.sprps as LockIndicator,
      SalaryBank.bankl as BankKey,
      SalaryBank.bankn as BankAccountNumber,
      SalaryBank.banks as BankCountry,
      /* Resolved text for list display; validity of text rows validated in behavior */
      _BankText.BankName,
      _BankText
}
where SalaryBank.infty = '0009'
  and SalaryBank.subty = '0'
