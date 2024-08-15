export const idlFactory = ({ IDL }) => {
  const Timestamp = IDL.Int;
  const ArtistAccountData = IDL.Record({
    'createdAt' : Timestamp,
    'userPrincipal' : IDL.Principal,
  });
  const FanAccountData = IDL.Record({
    'createdAt' : Timestamp,
    'userPrincipal' : IDL.Principal,
  });
  const UserId = IDL.Principal;
  const UserType = IDL.Variant({ 'fan' : IDL.Null, 'artist' : IDL.Null });
  const CanisterId = IDL.Principal;
  const definite_canister_settings = IDL.Record({
    'freezing_threshold' : IDL.Nat,
    'controllers' : IDL.Opt(IDL.Vec(IDL.Principal)),
    'memory_allocation' : IDL.Nat,
    'compute_allocation' : IDL.Nat,
  });
  const CanisterStatus = IDL.Record({
    'status' : IDL.Variant({
      'stopped' : IDL.Null,
      'stopping' : IDL.Null,
      'running' : IDL.Null,
    }),
    'memory_size' : IDL.Nat,
    'cycles' : IDL.Nat,
    'settings' : definite_canister_settings,
    'module_hash' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const StatusRequest = IDL.Record({
    'memory_size' : IDL.Opt(IDL.Bool),
    'trax_balance' : IDL.Opt(IDL.Bool),
    'version' : IDL.Opt(IDL.Bool),
    'cycles' : IDL.Opt(IDL.Bool),
    'heap_memory_size' : IDL.Opt(IDL.Bool),
    'ckbtc_balance' : IDL.Opt(IDL.Bool),
    'icp_balance' : IDL.Opt(IDL.Bool),
  });
  const Tokens = IDL.Record({ 'e8s' : IDL.Nat64 });
  const StatusResponse = IDL.Record({
    'memory_size' : IDL.Opt(IDL.Nat),
    'trax_balance' : IDL.Opt(IDL.Nat),
    'version' : IDL.Opt(IDL.Nat),
    'cycles' : IDL.Opt(IDL.Nat),
    'heap_memory_size' : IDL.Opt(IDL.Nat),
    'ckbtc_balance' : IDL.Opt(IDL.Nat),
    'icp_balance' : IDL.Opt(Tokens),
  });
  return IDL.Service({
    'changeCanisterSize' : IDL.Func([IDL.Nat], [], ['oneway']),
    'changeCycleAmount' : IDL.Func([IDL.Nat], [], ['oneway']),
    'createProfileArtist' : IDL.Func([ArtistAccountData], [IDL.Principal], []),
    'createProfileFan' : IDL.Func([FanAccountData], [IDL.Principal], []),
    'cyclesBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'deleteAccountCanister' : IDL.Func(
        [UserId, IDL.Principal, UserType],
        [IDL.Bool],
        [],
      ),
    'getArtistAccountEntries' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(UserId, CanisterId))],
        ['query'],
      ),
    'getCanisterArtist' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(IDL.Principal)],
        ['query'],
      ),
    'getCanisterFan' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(IDL.Principal)],
        ['query'],
      ),
    'getCanisterStatus' : IDL.Func([], [CanisterStatus], []),
    'getFanAccountEntries' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Principal))],
        ['query'],
      ),
    'getOwnerOfArtistCanister' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(UserId)],
        ['query'],
      ),
    'getOwnerOfFanCanister' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(UserId)],
        ['query'],
      ),
    'getStatus' : IDL.Func(
        [IDL.Opt(StatusRequest)],
        [IDL.Opt(StatusResponse)],
        [],
      ),
    'getTotalArtistAccounts' : IDL.Func([], [IDL.Nat], ['query']),
    'getTotalFanAccounts' : IDL.Func([], [IDL.Nat], ['query']),
    'installCode' : IDL.Func(
        [IDL.Principal, IDL.Vec(IDL.Nat8), IDL.Vec(IDL.Nat8)],
        [],
        [],
      ),
    'transferCyclesToAccountCanister' : IDL.Func(
        [IDL.Principal, IDL.Nat],
        [],
        [],
      ),
    'transferCyclesToCanister' : IDL.Func([IDL.Principal, IDL.Nat], [], []),
    'transferCyclesToContentCanister' : IDL.Func(
        [IDL.Principal, IDL.Principal, IDL.Nat],
        [],
        [],
      ),
    'transferOwnershipArtist' : IDL.Func(
        [IDL.Principal, IDL.Principal],
        [],
        [],
      ),
    'transferOwnershipFan' : IDL.Func([IDL.Principal, IDL.Principal], [], []),
  });
};
export const init = ({ IDL }) => { return []; };
