
import Nat        "mo:base/Nat";
import Debug      "mo:base/Debug";
import Text       "mo:base/Text";
import Time       "mo:base/Time";
import Error      "mo:base/Error";
import Principal  "mo:base/Principal";
import Utils      "../utils/utils";
import Env        "../env";
import T          "../types";
import Prim       "mo:⛔";
import Cycles     "mo:base/ExperimentalCycles";

actor class Identity(innitialHash : Text) {

  var VERSION: Nat      = 1;
  type StatusRequest    = T.StatusRequest;
  type StatusResponse   = T.StatusResponse;
  type Tokens            = T.Tokens;
  private var tokenHash = innitialHash;

  public shared({caller}) func changeHash(newHash: Text) : async (Text){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeHash: Unauthorized access. Caller is not the manager. Caller: " # Principal.toText(caller));
    };
    tokenHash := newHash;

    return tokenHash;
  };

  public shared({caller}) func getHashedTokenManager(baseHash: Text, user: Text) : async Nat32 {
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeHash: Unauthorized access. Caller is not the manager. Caller: " # Principal.toText(caller));
    };
    let myHashedToken = baseHash # tokenHash # user # baseHash;

    return Text.hash(myHashedToken);
  };

  public query ({caller}) func whoami() : async Principal {
    Debug.print("caller principal: " # debug_show Principal.toText(caller));
      return caller;
  };

  public query ({caller}) func getHashedToken(baseHash: Text) : async (Nat32, Text) {
    Debug.print("caller principal: " # debug_show Principal.toText(caller));
    let myHashedToken = baseHash # tokenHash # Principal.toText(caller) # baseHash;

    return (Text.hash(myHashedToken), Principal.toText(caller));
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

  private func getVersion() : Nat {
		return VERSION;
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

};
