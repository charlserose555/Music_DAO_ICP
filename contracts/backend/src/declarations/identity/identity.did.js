export const idlFactory = ({ IDL }) => {
  const StatusRequest = IDL.Record({
    'memory_size' : IDL.Bool,
    'version' : IDL.Bool,
    'cycles' : IDL.Bool,
    'heap_memory_size' : IDL.Bool,
  });
  const StatusResponse = IDL.Record({
    'memory_size' : IDL.Opt(IDL.Nat),
    'version' : IDL.Opt(IDL.Nat),
    'cycles' : IDL.Opt(IDL.Nat),
    'heap_memory_size' : IDL.Opt(IDL.Nat),
  });
  const Identity = IDL.Service({
    'changeHash' : IDL.Func([IDL.Text], [IDL.Text], []),
    'getHashedToken' : IDL.Func([IDL.Text], [IDL.Nat32, IDL.Text], ['query']),
    'getHashedTokenManager' : IDL.Func([IDL.Text, IDL.Text], [IDL.Nat32], []),
    'getStatus' : IDL.Func(
        [IDL.Opt(StatusRequest)],
        [IDL.Opt(StatusResponse)],
        ['query'],
      ),
    'whoami' : IDL.Func([], [IDL.Principal], ['query']),
  });
  return Identity;
};
export const init = ({ IDL }) => { return [IDL.Text]; };
