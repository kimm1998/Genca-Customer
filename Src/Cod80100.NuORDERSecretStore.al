// codeunit 80101 "NuORDER Secret Store"
// {
//     Access = Internal;

//     local procedure KeyPrefix(): Text
//     begin
//         exit('NuORDER.');
//     end;

//     procedure SetConsumerSecret(ValueTxt: Text)
//     begin
//         IsolatedStorage.SetEncrypted(KeyPrefix() + 'consumer_secret', ValueTxt, DataScope::Company);
//     end;

//     procedure TryGetConsumerSecret(var ValueTxt: Text): Boolean
//     begin
//         exit(IsolatedStorage.Get(KeyPrefix() + 'consumer_secret', DataScope::Company, ValueTxt));
//     end;

//     procedure SetToken(ValueTxt: Text)
//     begin
//         IsolatedStorage.SetEncrypted(KeyPrefix() + 'token', ValueTxt, DataScope::Company);
//     end;

//     procedure TryGetToken(var ValueTxt: Text): Boolean
//     begin
//         exit(IsolatedStorage.Get(KeyPrefix() + 'token', DataScope::Company, ValueTxt));
//     end;

//     procedure SetTokenSecret(ValueTxt: Text)
//     begin
//         IsolatedStorage.SetEncrypted(KeyPrefix() + 'token_secret', ValueTxt, DataScope::Company);
//     end;

//     procedure TryGetTokenSecret(var ValueTxt: Text): Boolean
//     begin
//         exit(IsolatedStorage.Get(KeyPrefix() + 'token_secret', DataScope::Company, ValueTxt));
//     end;

//     procedure HasValue(Suffix: Text): Boolean
//     var
//         Dummy: Text;
//     begin
//         exit(IsolatedStorage.Get(KeyPrefix() + Suffix, DataScope::Company, Dummy));
//     end;

//     procedure ClearAuth()
//     begin
//         IsolatedStorage.Delete(KeyPrefix() + 'token', DataScope::Company);
//         IsolatedStorage.Delete(KeyPrefix() + 'token_secret', DataScope::Company);
//     end;
// }