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
        ['query'],
      ),
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
