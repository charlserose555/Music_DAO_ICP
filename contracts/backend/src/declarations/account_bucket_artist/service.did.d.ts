import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface ArtistAccountData {
  'createdAt' : Timestamp,
  'userPrincipal' : Principal,
}
export interface ArtistAccountData__1 {
  'createdAt' : Timestamp,
  'userPrincipal' : Principal,
}
export interface ArtistBucket {
  'changeCanisterSize' : ActorMethod<[bigint], undefined>,
  'changeCycleAmount' : ActorMethod<[bigint], undefined>,
  'createContent' : ActorMethod<[ContentInit], [] | [[ContentId, Principal]]>,
  'deleteAccount' : ActorMethod<[], undefined>,
  'deleteContentCanister' : ActorMethod<[Principal], boolean>,
  'getAllContentCanisters' : ActorMethod<[], Array<CanisterId>>,
  'getCanisterOfContent' : ActorMethod<[ContentId], [] | [CanisterId]>,
  'getCurrentCyclesBalance' : ActorMethod<[], bigint>,
  'getEntriesOfCanisterToContent' : ActorMethod<
    [],
    Array<[CanisterId, ContentId]>
  >,
  'getPrincipalThis' : ActorMethod<[], Principal>,
  'getProfileInfo' : ActorMethod<[UserId], [] | [ArtistAccountData__1]>,
  'getStatus' : ActorMethod<[[] | [StatusRequest]], [] | [StatusResponse]>,
  'getVersionNumber' : ActorMethod<[], bigint>,
  'initCanister' : ActorMethod<[], boolean>,
  'removeContent' : ActorMethod<[ContentId, bigint], undefined>,
  'transferFreezingThresholdCycles' : ActorMethod<[], undefined>,
  'updateProfileInfo' : ActorMethod<[ArtistAccountData__1], boolean>,
}
export type CanisterId = Principal;
export type ContentId = string;
export interface ContentInit {
  'contentId' : string,
  'userId' : UserId__1,
  'name' : string,
  'createdAt' : Timestamp,
  'size' : bigint,
  'tags' : Array<string>,
  'description' : string,
  'chunkCount' : bigint,
  'extension' : FileExtension,
}
export type FileExtension = { 'aac' : null } |
  { 'avi' : null } |
  { 'gif' : null } |
  { 'jpg' : null } |
  { 'mp3' : null } |
  { 'mp4' : null } |
  { 'png' : null } |
  { 'svg' : null } |
  { 'wav' : null } |
  { 'jpeg' : null };
export interface StatusRequest {
  'memory_size' : [] | [boolean],
  'trax_balance' : [] | [boolean],
  'version' : [] | [boolean],
  'cycles' : [] | [boolean],
  'heap_memory_size' : [] | [boolean],
  'ckbtc_balance' : [] | [boolean],
  'icp_balance' : [] | [boolean],
}
export interface StatusResponse {
  'memory_size' : [] | [bigint],
  'trax_balance' : [] | [bigint],
  'version' : [] | [bigint],
  'cycles' : [] | [bigint],
  'heap_memory_size' : [] | [bigint],
  'ckbtc_balance' : [] | [bigint],
  'icp_balance' : [] | [Tokens],
}
export type Timestamp = bigint;
export interface Tokens { 'e8s' : bigint }
export type UserId = Principal;
export type UserId__1 = Principal;
export interface _SERVICE extends ArtistBucket {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
