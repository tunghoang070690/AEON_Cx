@EndUserText.label: 'HR Salary Bank Account (projection)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define root view entity ZC_HR_BankAccount
  provider contract transactional_query
  as projection on ZI_HR_BankAccount
{
  key PersonnelNumber,
  key Infotype,
  key Subtype,
  key ValidFrom,
  key ValidTo,
      ObjectID,
      LockIndicator,
      BankKey,
      BankAccountNumber,
      BankCountry,
      BankName,
      _BankText
}
