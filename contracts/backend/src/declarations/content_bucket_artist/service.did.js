export const idlFactory = ({ IDL }) => {
  const UserId = IDL.Principal;
  const Timestamp = IDL.Int;
  const FileExtension = IDL.Variant({
    'aac' : IDL.Null,
    'avi' : IDL.Null,
    'gif' : IDL.Null,
    'jpg' : IDL.Null,
    'mp3' : IDL.Null,
    'mp4' : IDL.Null,
    'png' : IDL.Null,
    'svg' : IDL.Null,
    'wav' : IDL.Null,
    'jpeg' : IDL.Null,
  });
  const ContentInit = IDL.Record({
    'contentId' : IDL.Text,
    'userId' : UserId,
    'name' : IDL.Text,
    'createdAt' : Timestamp,
    'size' : IDL.Nat,
    'tags' : IDL.Vec(IDL.Text),
    'description' : IDL.Text,
    'chunkCount' : IDL.Nat,
    'extension' : FileExtension,
  });
  const ContentId = IDL.Text;
  const ContentData = IDL.Record({
    'contentId' : IDL.Text,
    'userId' : UserId,
    'name' : IDL.Text,
    'createdAt' : Timestamp,
    'size' : IDL.Nat,
    'tags' : IDL.Vec(IDL.Text),
    'description' : IDL.Text,
    'chunkCount' : IDL.Nat,
    'extension' : FileExtension,
    'uploadedAt' : Timestamp,
  });
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
  const ArtistContentBucket = IDL.Service({
    'changeCanisterSize' : IDL.Func([IDL.Nat], [], ['oneway']),
    'changeCycleAmount' : IDL.Func([IDL.Nat], [], ['oneway']),
    'checkCyclesBalance' : IDL.Func([], [], []),
    'createContent' : IDL.Func([ContentInit], [IDL.Opt(ContentId)], []),
    'getAllContentInfo' : IDL.Func(
        [ContentId],
        [IDL.Vec(IDL.Tuple(ContentId, ContentData))],
        ['query'],
      ),
    'getCanisterStatus' : IDL.Func([], [CanisterStatus], []),
    'getContentChunk' : IDL.Func(
        [ContentId, IDL.Nat],
        [IDL.Opt(IDL.Vec(IDL.Nat8))],
        ['query'],
      ),
    'getContentInfo' : IDL.Func([ContentId], [IDL.Opt(ContentData)], ['query']),
    'getCurrentCyclesBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getPrincipalThis' : IDL.Func([], [IDL.Principal], ['query']),
    'getStatus' : IDL.Func(
        [IDL.Opt(StatusRequest)],
        [IDL.Opt(StatusResponse)],
        [],
      ),
    'getVersionNumber' : IDL.Func([], [IDL.Nat], ['query']),
    'putContentChunk' : IDL.Func(
        [ContentId, IDL.Nat, IDL.Vec(IDL.Nat8)],
        [],
        [],
      ),
    'removeContent' : IDL.Func([ContentId, IDL.Nat], [], []),
    'transferCyclesToThisCanister' : IDL.Func([], [], []),
    'transferFreezingThresholdCycles' : IDL.Func([], [], []),
  });
  return ArtistContentBucket;
};
export const init = ({ IDL }) => {
  return [IDL.Principal, IDL.Principal, IDL.Principal];
};
