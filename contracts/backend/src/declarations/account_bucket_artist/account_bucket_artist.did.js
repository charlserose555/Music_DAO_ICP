export const idlFactory = ({ IDL }) => {
  const Timestamp = IDL.Int;
  const ArtistAccountData = IDL.Record({
    'createdAt' : Timestamp,
    'userPrincipal' : IDL.Principal,
  });
  const UserId__1 = IDL.Principal;
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
    'userId' : UserId__1,
    'name' : IDL.Text,
    'createdAt' : Timestamp,
    'size' : IDL.Nat,
    'tags' : IDL.Vec(IDL.Text),
    'description' : IDL.Text,
    'chunkCount' : IDL.Nat,
    'extension' : FileExtension,
  });
  const ContentId = IDL.Text;
  const UserId = IDL.Principal;
  const CanisterId = IDL.Principal;
  const ArtistAccountData__1 = IDL.Record({
    'createdAt' : Timestamp,
    'userPrincipal' : IDL.Principal,
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
  const ArtistBucket = IDL.Service({
    'changeCanisterSize' : IDL.Func([IDL.Nat], [], ['oneway']),
    'changeCycleAmount' : IDL.Func([IDL.Nat], [], ['oneway']),
    'createContent' : IDL.Func(
        [ContentInit],
        [IDL.Opt(IDL.Tuple(ContentId, IDL.Principal))],
        [],
      ),
    'deleteAccount' : IDL.Func([IDL.Principal], [], []),
    'deleteContentCanister' : IDL.Func([UserId, IDL.Principal], [IDL.Bool], []),
    'getAllContentCanisters' : IDL.Func([], [IDL.Vec(CanisterId)], ['query']),
    'getCanisterOfContent' : IDL.Func(
        [ContentId],
        [IDL.Opt(CanisterId)],
        ['query'],
      ),
    'getCurrentCyclesBalance' : IDL.Func([], [IDL.Nat], []),
    'getEntriesOfCanisterToContent' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(CanisterId, ContentId))],
        ['query'],
      ),
    'getPrincipalThis' : IDL.Func([], [IDL.Principal], ['query']),
    'getProfileInfo' : IDL.Func(
        [UserId],
        [IDL.Opt(ArtistAccountData__1)],
        ['query'],
      ),
    'getStatus' : IDL.Func(
        [IDL.Opt(StatusRequest)],
        [IDL.Opt(StatusResponse)],
        ['query'],
      ),
    'initCanister' : IDL.Func([], [IDL.Bool], []),
    'removeContent' : IDL.Func([ContentId, IDL.Nat], [], []),
    'transferFreezingThresholdCycles' : IDL.Func([], [], []),
    'updateProfileInfo' : IDL.Func([ArtistAccountData__1], [IDL.Bool], []),
  });
  return ArtistBucket;
};
export const init = ({ IDL }) => {
  const Timestamp = IDL.Int;
  const ArtistAccountData = IDL.Record({
    'createdAt' : Timestamp,
    'userPrincipal' : IDL.Principal,
  });
  return [IDL.Opt(ArtistAccountData), IDL.Principal];
};
