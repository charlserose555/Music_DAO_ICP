export const idlFactory = ({ IDL }) => {
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
  return IDL.Service({
    'addCanister' : IDL.Func([IDL.Principal], [], []),
    'cyclesBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getAllCanisters' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(CanisterId, IDL.Nat64))],
        ['query'],
      ),
    'getCanisterCycleValue' : IDL.Func(
        [IDL.Principal],
        [IDL.Opt(IDL.Nat64)],
        ['query'],
      ),
    'getCanisterStatus' : IDL.Func([], [CanisterStatus], []),
    'getStatus' : IDL.Func(
        [IDL.Opt(StatusRequest)],
        [IDL.Opt(StatusResponse)],
        ['query'],
      ),
    'getTotalNumberCanisters' : IDL.Func([], [IDL.Nat], ['query']),
    'removeCanister' : IDL.Func([IDL.Principal], [], []),
    'topUpCanister' : IDL.Func([IDL.Principal, IDL.Nat64], [IDL.Bool], []),
    'topUpCanistersBatch' : IDL.Func(
        [IDL.Vec(IDL.Principal), IDL.Nat64],
        [],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
