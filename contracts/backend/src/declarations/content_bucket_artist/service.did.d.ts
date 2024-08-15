import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface ArtistContentBucket {
  'changeCanisterSize' : ActorMethod<[bigint], undefined>,
  'changeCycleAmount' : ActorMethod<[bigint], undefined>,
  'checkCyclesBalance' : ActorMethod<[], undefined>,
  'createContent' : ActorMethod<[ContentInit], [] | [ContentId]>,
  'getAllContentInfo' : ActorMethod<
    [ContentId],
    Array<[ContentId, ContentData]>
  >,
  'getCanisterStatus' : ActorMethod<[], CanisterStatus>,
  'getContentChunk' : ActorMethod<
    [ContentId, bigint],
    [] | [Uint8Array | number[]]
  >,
  'getContentInfo' : ActorMethod<[ContentId], [] | [ContentData]>,
  'getCurrentCyclesBalance' : ActorMethod<[], bigint>,
  'getPrincipalThis' : ActorMethod<[], Principal>,
  'getStatus' : ActorMethod<[[] | [StatusRequest]], [] | [StatusResponse]>,
  'getVersionNumber' : ActorMethod<[], bigint>,
  'putContentChunk' : ActorMethod<
    [ContentId, bigint, Uint8Array | number[]],
    undefined
  >,
  'removeContent' : ActorMethod<[ContentId, bigint], undefined>,
  'transferCyclesToThisCanister' : ActorMethod<[], undefined>,
  'transferFreezingThresholdCycles' : ActorMethod<[], undefined>,
}
export interface CanisterStatus {
  'status' : { 'stopped' : null } |
    { 'stopping' : null } |
    { 'running' : null },
  'memory_size' : bigint,
  'cycles' : bigint,
  'settings' : definite_canister_settings,
  'module_hash' : [] | [Uint8Array | number[]],
}
export interface ContentData {
  'contentId' : string,
  'userId' : UserId,
  'name' : string,
  'createdAt' : Timestamp,
  'size' : bigint,
  'tags' : Array<string>,
  'description' : string,
  'chunkCount' : bigint,
  'extension' : FileExtension,
  'uploadedAt' : Timestamp,
}
export type ContentId = string;
export interface ContentInit {
  'contentId' : string,
  'userId' : UserId,
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
export interface definite_canister_settings {
  'freezing_threshold' : bigint,
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : bigint,
  'compute_allocation' : bigint,
}
export interface _SERVICE extends ArtistContentBucket {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
