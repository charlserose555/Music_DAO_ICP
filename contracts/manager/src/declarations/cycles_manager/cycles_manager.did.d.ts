import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

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
export interface StatusRequest {
  'memory_size' : boolean,
  'version' : boolean,
  'cycles' : boolean,
  'heap_memory_size' : boolean,
}
export interface StatusResponse {
  'memory_size' : [] | [bigint],
  'version' : [] | [bigint],
  'cycles' : [] | [bigint],
  'heap_memory_size' : [] | [bigint],
}
export interface definite_canister_settings {
  'freezing_threshold' : bigint,
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : bigint,
  'compute_allocation' : bigint,
}
export interface _SERVICE {
  'addCanister' : ActorMethod<[Principal], undefined>,
  'cyclesBalance' : ActorMethod<[], bigint>,
  'getAllCanisters' : ActorMethod<[], Array<[CanisterId, bigint]>>,
  'getCanisterCycleValue' : ActorMethod<[Principal], [] | [bigint]>,
  'getCanisterStatus' : ActorMethod<[], CanisterStatus>,
  'getStatus' : ActorMethod<[[] | [StatusRequest]], [] | [StatusResponse]>,
  'getTotalNumberCanisters' : ActorMethod<[], bigint>,
  'removeCanister' : ActorMethod<[Principal], undefined>,
  'topUpCanister' : ActorMethod<[Principal, bigint], boolean>,
  'topUpCanistersBatch' : ActorMethod<[Array<Principal>, bigint], undefined>,
}
