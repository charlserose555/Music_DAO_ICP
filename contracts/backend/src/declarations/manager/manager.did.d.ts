import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface ArtistAccountData {
  'createdAt' : Timestamp,
  'userPrincipal' : Principal,
}
export type CanisterId = Principal;
export interface CanisterStatus {
  'status' : { 'stopped' : null } |
    { 'stopping' : null } |
    { 'running' : null },
  'memory_size' : bigint,
  'cycles' : bigint,
  'settings' : definite_canister_settings,
  'module_hash' : [] | [Uint8Array | number[]],
}
export interface FanAccountData {
  'createdAt' : Timestamp,
  'userPrincipal' : Principal,
}
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
export type UserType = { 'fan' : null } |
  { 'artist' : null };
export interface definite_canister_settings {
  'freezing_threshold' : bigint,
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : bigint,
  'compute_allocation' : bigint,
}
export interface _SERVICE {
  'changeCanisterSize' : ActorMethod<[bigint], undefined>,
  'changeCycleAmount' : ActorMethod<[bigint], undefined>,
  'createProfileArtist' : ActorMethod<[ArtistAccountData], Principal>,
  'createProfileFan' : ActorMethod<[FanAccountData], Principal>,
  'cyclesBalance' : ActorMethod<[], bigint>,
  'deleteAccountCanister' : ActorMethod<[UserId, Principal, UserType], boolean>,
  'getArtistAccountEntries' : ActorMethod<[], Array<[UserId, CanisterId]>>,
  'getCanisterArtist' : ActorMethod<[Principal], [] | [Principal]>,
  'getCanisterFan' : ActorMethod<[Principal], [] | [Principal]>,
  'getCanisterStatus' : ActorMethod<[], CanisterStatus>,
  'getFanAccountEntries' : ActorMethod<[], Array<[Principal, Principal]>>,
  'getOwnerOfArtistCanister' : ActorMethod<[Principal], [] | [UserId]>,
  'getOwnerOfFanCanister' : ActorMethod<[Principal], [] | [UserId]>,
  'getStatus' : ActorMethod<[[] | [StatusRequest]], [] | [StatusResponse]>,
  'getTotalArtistAccounts' : ActorMethod<[], bigint>,
  'getTotalFanAccounts' : ActorMethod<[], bigint>,
  'installCode' : ActorMethod<
    [Principal, Uint8Array | number[], Uint8Array | number[]],
    undefined
  >,
  'transferCyclesToAccountCanister' : ActorMethod<
    [Principal, bigint],
    undefined
  >,
  'transferCyclesToCanister' : ActorMethod<[Principal, bigint], undefined>,
  'transferCyclesToContentCanister' : ActorMethod<
    [Principal, Principal, bigint],
    undefined
  >,
  'transferOwnershipArtist' : ActorMethod<[Principal, Principal], undefined>,
  'transferOwnershipFan' : ActorMethod<[Principal, Principal], undefined>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
