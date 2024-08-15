import Cycles             "mo:base/ExperimentalCycles";
import Principal          "mo:base/Principal";
import Error              "mo:base/Error";
import IC                 "ic.types";
import Nat                "mo:base/Nat";
import Map                "mo:stable-hash-map/Map";
import Debug              "mo:base/Debug";
import Text               "mo:base/Text";
import T                  "types";
import Hash               "mo:base/Hash";
import Nat32              "mo:base/Nat32";
import Nat64              "mo:base/Nat64";
import Iter               "mo:base/Iter";
import Float              "mo:base/Float";
import Time               "mo:base/Time";
import Int                "mo:base/Int";
import Result             "mo:base/Result";
import Blob               "mo:base/Blob";
import Array              "mo:base/Array";
import Buffer             "mo:base/Buffer";
import Trie               "mo:base/Trie";
import TrieMap            "mo:base/TrieMap";
import CanisterUtils      "utils/canister.utils";
import WalletUtils        "utils/wallet.utils";
import Utils              "utils/utils";
import Prim               "mo:⛔";
import Env                "env";
import B                  "mo:stable-buffer/StableBuffer";

actor Cycles_Manager {

 
  type UserType                       = T.UserType;
  type UserId                         = T.UserId;
  type CanisterId                     = T.CanisterId;
  type StatusRequest                  = T.StatusRequest;
  type StatusResponse                 = T.StatusResponse;
  type CanisterStatus                 = IC.canister_status_response;
  
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils       = WalletUtils.WalletUtils();

  private let ic : IC.Self = actor "aaaaa-aa";

  let { ihash; nhash; thash; phash; calcHash } = Map;
  var MAX_CANISTER_SIZE: Nat            = 68_700_000_000; // <-- approx. 64GB
  var VERSION: Nat                      = 1;
  stable var total_canisters: Nat       = 0;
  
  stable let canisterMap = Map.new<CanisterId, Nat64>(phash); 



  public shared({caller}) func addCanister(canisterId: Principal) : async (){
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };
    switch(Map.get(canisterMap, phash, canisterId)){
      case(?canId){
        throw Error.reject("@addCanister: This canister has already been added: " # Principal.toText(canisterId));
      };
      case null {
        let totalCyclesSent: Nat64 = 0;
        ignore Map.put(canisterMap, phash, canisterId, totalCyclesSent);
        total_canisters := total_canisters + 1;
      };
    };
  };



  public shared({caller}) func removeCanister(canisterId: Principal) : async (){
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };

    switch(Map.get(canisterMap, phash, canisterId)){
      case(?val){
        Map.delete(canisterMap, phash, canisterId);
      };
      case null {
        throw Error.reject("@addCanister: This canister has does not exist: " # Principal.toText(canisterId));
        let totalCyclesSent: Nat64 = 0;
        
      };
    };
  };



  public shared({caller}) func topUpCanister(canisterId: Principal, topUpAmount: Nat64) : async (Bool){
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };

    switch(Map.get(canisterMap, phash, canisterId)){
      case(?val){
        await walletUtils.transferCycles(canisterId, Nat64.toNat(topUpAmount));

        let new_cycles_val: Nat64 = val + topUpAmount;
        ignore Map.replace(canisterMap, phash, canisterId, new_cycles_val);
        return true;
      };
      case null {
        return false;
      }
    }
  };



  public shared({caller}) func topUpCanistersBatch(canisterIds: [Principal], topUpAmount: Nat64) : async (){
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };

    for(can in Iter.fromArray(canisterIds)){
      switch(Map.get(canisterMap, phash, can)){
        case(?val){
          await walletUtils.transferCycles(can, Nat64.toNat(topUpAmount));
          var new_cycles_val: Nat64 = val + topUpAmount;
          ignore Map.replace(canisterMap, phash, can, new_cycles_val);
        };
        case null { }
      }
    }
    
  };



  public query({caller}) func getAllCanisters() : async [(CanisterId, Nat64)]{
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };

    Iter.toArray(Map.entries(canisterMap));
  };



  public query({caller}) func getCanisterCycleValue(canisterId: Principal) : async ?Nat64{
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@addCanister: Unauthorized access. Caller is not the manager principal. Caller: " # Principal.toText(caller));
    // };

    switch(Map.get(canisterMap, phash, canisterId)){
      case(?val){
        return ?val;
      };
      case null {
        return null
      }
    }
  };



  public query func getTotalNumberCanisters() :  async Nat{   
    total_canisters
  }; 









  public shared({caller}) func getStatus(request: ?StatusRequest): async ?StatusResponse {
    // assert(U.isAdmin(caller));
      switch(request) {
          case (null) {
              return null;
          };
          case (?_request) {
              var cycles: ?Nat = null;
              switch(_request.cycles){
                case(?checkCycles){
                  cycles := ?getCurrentCycles();
                };case null {};
              };
              
              var memory_size: ?Nat = null;
              switch(_request.memory_size){
                case(?checkStableMemory){
                  memory_size := ?getCurrentMemory();
                };case null {};
              };

              var heap_memory_size: ?Nat = null;
              switch(_request.heap_memory_size){
                case(?checkHeapMemory){
                  heap_memory_size := ?getCurrentHeapMemory();
                };case null {};
              };
              var version: ?Nat = null;
              switch(_request.version){
                case(?checkVersion){
                  version := ?getVersion();
                };case null {};
              };
              
              var icp_balance: ?Tokens = null;
              var ckbtc_balance: ?Nat = null;
              var trax_balance: ?Nat = null;

              return ?{
                  cycles = cycles;
                  memory_size = memory_size;
                  heap_memory_size = heap_memory_size;
                  version = version;
                  icp_balance = icp_balance;
                  ckbtc_balance = ckbtc_balance;
                  trax_balance = trax_balance;
              };
          };
      };
  };



  private func getCurrentHeapMemory(): Nat {
    Prim.rts_heap_size();
  };



  private func getCurrentMemory(): Nat {
    Prim.rts_memory_size();
  };



  private func getCurrentCycles(): Nat {
    Cycles.balance();
  };



  public query func cyclesBalance() : async (Nat) {
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@cyclesBalance: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    return walletUtils.cyclesBalance();
  };



  private func getVersion() : Nat {
		return VERSION;
	};



  public shared({caller}) func getCanisterStatus() : async CanisterStatus {
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@cyclesBalance: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    return await canisterUtils.canisterStatus(?Principal.fromActor(Cycles_Manager));
  };





};
