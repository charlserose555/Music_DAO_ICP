import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Identity {
  'changeHash' : ActorMethod<[string], string>,
  'getHashedToken' : ActorMethod<[string], [number, string]>,
  'getHashedTokenManager' : ActorMethod<[string, string], number>,
  'getStatus' : ActorMethod<[[] | [StatusRequest]], [] | [StatusResponse]>,
  'whoami' : ActorMethod<[], Principal>,
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
export interface _SERVICE extends Identity {}
