import Cycles               "mo:base/ExperimentalCycles";
import Principal            "mo:base/Principal";
import Error                "mo:base/Error";
import Nat                  "mo:base/Nat";
import Debug                "mo:base/Debug";
import Text                 "mo:base/Text";
import T                    "../types";
import Hash                 "mo:base/Hash";
import Nat32                "mo:base/Nat32";
import Nat64                "mo:base/Nat64";
import Iter                 "mo:base/Iter";
import Float                "mo:base/Float";
import Time                 "mo:base/Time";
import Int                  "mo:base/Int";
import Result               "mo:base/Result";
import Blob                 "mo:base/Blob";
import Array                "mo:base/Array";
import Buffer               "mo:base/Buffer";
import Trie                 "mo:base/Trie";
import TrieMap              "mo:base/TrieMap";
import CanisterUtils        "../utils/canister.utils";
import Prim                 "mo:⛔";
import Map                  "mo:stable-hash-map/Map";
import Utils                "../utils/utils";
import WalletUtils          "../utils/wallet.utils";
import S                    "mo:base/ExperimentalStableMemory";
import IC                   "../ic.types";

actor class ArtistContentBucket(owner: Principal, manager: Principal, artistBucket: Principal) = this {

  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentData               = T.ContentData;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type ChunkData                 = T.ChunkData;
  type StatusRequest             = T.StatusRequest;
  type StatusResponse            = T.StatusResponse;
  type Thumbnail                 = T.Thumbnail;
  type Trailer                   = T.Trailer;
  type CanisterStatus            = IC.canister_status_response;
  type Tokens                    = T.Tokens;
  
  let { ihash; nhash; thash; phash; calcHash } = Map;

  stable var canisterOwner: Principal = owner;
  stable var managerCanister: Principal = manager;
  stable var initialised: Bool = false;
  stable var MAX_CANISTER_SIZE: Nat =     68_700_000_000; // <-- approx. 64GB
  stable var CYCLE_AMOUNT : Nat     =  100_000_000_000; // minimum amount of cycles needed to create new canister 
  let maxCycleAmount                = 80_000_000_000_000; // canister cycles capacity 
  let top_up_amount                 = 1_000_000_000_000;
  var VERSION: Nat                  = 3; 

  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  stable let content = Map.new<ContentId, ContentData>(thash);
  stable let chunksData = Map.new<ChunkId, ChunkData>(thash);



// #region - CREATE & UPLOAD CONTENT
  public shared({caller}) func createContent(i : ContentInit) : async ?ContentId {
    assert(caller == owner or Utils.isManager(caller) or caller == artistBucket);
    let now = Time.now();
    // let videoId = Principal.toText(i.userId) # "-" # i.name # "-" # (Int.toText(now));
    switch (Map.get(content, thash, i.contentId)) {
    case (?_) { throw Error.reject("Content ID already taken")};
    case null { 
       let a = Map.put(content, thash, i.contentId,
                        {
                          contentId = i.contentId;
                          userId = i.userId;
                          name = i.name;
                          createdAt = i.createdAt;
                          uploadedAt = now;
                          description =  i.description;
                          chunkCount = i.chunkCount;
                          tags = i.tags;
                          extension = i.extension;
                          size = i.size;
                        });
        // await checkCyclesBalance();
       ?i.contentId
     };
    }
  };



  public shared({caller}) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : Blob) : async (){
    assert(caller == owner or Utils.isManager(caller));
    let a = Map.put(chunksData, thash, chunkId(contentId, chunkNum), chunkData);
  };



  public query({caller}) func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?Blob {
    assert(caller == owner or Utils.isManager(caller));
    Map.get(chunksData, thash, chunkId(contentId, chunkNum));
  };



  private func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };



  public shared({caller}) func removeContent(contentId: ContentId, chunkNum : Nat) : async () {
    assert(caller == owner or Utils.isManager(caller) or caller == artistBucket);
    let a = Map.remove(chunksData, thash, chunkId(contentId, chunkNum));
    let b = Map.remove(content, thash, contentId);
  };



  public query({caller}) func getContentInfo(id: ContentId) : async ?ContentData{
    // assert(caller == owner or Utils.isManager(caller));
    Map.get(content, thash, id);
  };

  public query({caller}) func getAllContentInfo(id: ContentId) : async [(ContentId, ContentData)]{
    // assert(caller == owner or Utils.isManager(caller));
    var res = Buffer.Buffer<(ContentId, ContentData)>(2);
    for((key, value) in Map.entries(content)){
      var contentId : ContentId = key;
      var contentData : ContentData = value;
      res.add(contentId, contentData);
    };       
    return Buffer.toArray(res);
    // Map.get(content, thash, id);
  };
// #endregion



  

  




// #region - UTILS
  public shared({caller}) func checkCyclesBalance () : async(){
    assert(caller == owner or Utils.isManager(caller) or caller == Principal.fromActor(this));
    Debug.print("@checkCyclesBalance: creator of this smart contract:\n" # debug_show manager);
    let bal = getCurrentCycles();
    Debug.print("@checkCyclesBalance: Cycles Balance After Canister Creation:\n" # debug_show bal);
    if(bal < CYCLE_AMOUNT){
       await transferCyclesToThisCanister();
    };
  };

   public query func getCurrentCyclesBalance(): async Nat {
    Cycles.balance();
  };




  // public func transferCyclesToThisCanister() : async (){
  //   let self: Principal = Principal.fromActor(this);

  //   let can = actor(Principal.toText(managerCanister)): actor { 
  //     transferCyclesToContentCanister: (Principal, Principal, Nat) -> async ();
  //   };
  //   let accepted = await wallet_receive();
  //   await can.transferCyclesToContentCanister(artistBucket, self, Nat64.toNat(accepted.accepted));
  // };


  public func transferCyclesToThisCanister() : async (){
    let self: Principal = Principal.fromActor(this);
    let can = actor(Principal.toText(managerCanister)): actor { 
      transferCyclesToCanister: (Principal, Nat) -> async ();
    };
    let accepted = await wallet_receive();
    await can.transferCyclesToCanister(self, Nat64.toNat(accepted.accepted));
  };




  public shared({caller}) func changeCycleAmount(amount: Nat) : (){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCycleAmount: Unauthorized access. Caller is not the manager. caller is:\n" # Principal.toText(caller));
    };
    CYCLE_AMOUNT := amount;
  };




  public shared({caller}) func changeCanisterSize(newSize: Nat) : (){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCanisterSize: Unauthorized access. Caller is not the manager. caller is:\n" # Principal.toText(caller));
    };
    MAX_CANISTER_SIZE := newSize;
  };




  public shared ({caller}) func transferFreezingThresholdCycles() : async () {
    assert(Utils.isManager(caller) or caller == owner or caller == managerCanister or caller == artistBucket);
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@transferFreezingThresholdCycles: Unauthorized access. Caller is not a manager. caller is: \n" # Principal.toText(caller));
    // };

    await walletUtils.transferFreezingThresholdCycles(managerCanister);
  };



  private func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, top_up_amount));
    // let accepted = Cycles.accept(top_up_amount);
    { accepted = Nat64.fromNat(accepted) };
  };



  public query({caller}) func getPrincipalThis() :  async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@getPrincipalThis: Unauthorized access. Caller is not a manager. caller is: \n" # Principal.toText(caller));
    };
    Principal.fromActor(this);
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





  
  private func getVersion() : Nat {
		return VERSION;
	}; 


  public query func getVersionNumber() : async Nat {
		return VERSION;
	};  


  public shared({caller}) func getCanisterStatus() : async CanisterStatus {
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@cyclesBalance: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    return await canisterUtils.canisterStatus(?Principal.fromActor(this));
  };

// #endregion
  
}