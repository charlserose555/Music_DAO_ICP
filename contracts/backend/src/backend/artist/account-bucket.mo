import Cycles               "mo:base/ExperimentalCycles";
import Principal            "mo:base/Principal";
import Error                "mo:base/Error";
import Nat                  "mo:base/Nat";
import Debug                "mo:base/Debug";
import T                    "../types";
import Nat64                "mo:base/Nat64";
import Buffer               "mo:base/Buffer";
import CanisterUtils        "../utils/canister.utils";
import Prim                 "mo:⛔";
import Map                  "mo:stable-hash-map/Map";
import ArtistContentBucket  "./content-bucket";
import B                    "mo:stable-buffer/StableBuffer";
import Utils                "../utils/utils";
import WalletUtils          "../utils/wallet.utils";
import IC                   "../ic.types";
import Env                  "../env";

 shared({caller = managerCanister}) actor class ArtistBucket(accountInfo: ?T.ArtistAccountData, artistPrincipal: Principal, cyclesManager: Principal) = this {

  let { thash; phash; } = Map;

  type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentData               = T.ContentData;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type StatusRequest             = T.StatusRequest;
  type StatusResponse            = T.StatusResponse;
  type ManagerId                 = Principal;
  type CanisterStatus            = IC.canister_status_response;
  type Tokens                    = T.Tokens;
  
  stable var MAX_CANISTER_SIZE: Nat =     68_700_000_000; // <-- approx. 64GB
  stable var CYCLE_AMOUNT : Nat     =    100_000_000_000; 
  let top_up_amount                 =  2_000_000_000_000;


  private let ic : IC.Self        = actor "aaaaa-aa";
  var VERSION: Nat                = 3;
  stable var initialised: Bool    = false;
  stable var owner: Principal     = artistPrincipal;
  // Stable variable holding the cycles requester


  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();

  stable let artistData = Map.new<UserId, ArtistAccountData>(phash);
  stable let contentToCanister = Map.new<ContentId, CanisterId>(thash);

  stable let contentCanisterIds = B.init<CanisterId>();


// #region - CREATE CONTENT CANISTERS
  public func initCanister() : async (Bool) { // Initialise new cansiter. This is called only once after the account has been created. I
    assert(initialised == false);
    switch(accountInfo){
      case(?info){
        ignore Map.put(artistData, phash, artistPrincipal, info);
        initialised := true;
        return true;
      };case null return false;
    };
  };



  public shared({caller}) func createContent(i : ContentInit) : async ?(ContentId, Principal) {
    Debug.print("@createContent: caller of this function is:\n" # Principal.toText(caller));
    assert(caller == owner or Utils.isManager(caller));

    var uploaded : Bool = false;
    for(canister in B.vals(contentCanisterIds)){
      Debug.print("canister: " # debug_show canister);

      let can = actor(Principal.toText(canister)): actor { 
        createContent: (ContentInit) -> async (?ContentId);
      };
      switch(await can.createContent(i)){
        case(?contentId){ 
          ignore Map.put(contentToCanister, thash, contentId, canister);
          uploaded := true;
          return ?(contentId, canister);
        };
        case null { 
          return null
        };
      };
    };

    if(uploaded == false){
      switch(await createStorageCanister(i.userId)){
        case(?canID){
          B.add(contentCanisterIds, canID);
          let newCan = actor(Principal.toText(canID)): actor { 
            createContent: (ContentInit) -> async (?ContentId);
          };
          switch(await newCan.createContent(i)){
            case(?contentId){ 
              Debug.print("putting in the mapping contentId: " # debug_show contentId);
              let a = Map.put(contentToCanister, thash, contentId, canID);
                Debug.print("res: " # debug_show a);
              uploaded := true;
              return ?(contentId, canID)  
            };
            case null { 
              return null
            };
          };
        };
        case null return null;
      }
    }else{
      return null;
    }
  };



  private func createStorageCanister(owner: UserId) : async ?(Principal) {

    // await checkCyclesBalance();
    Debug.print("@createStorageCanister: owner (artist) principal: " # debug_show Principal.toText(owner));
    Debug.print("@createStorageCanister: Environment Manager Principal: " # Env.manager[0]);
    Prim.cyclesAdd<system>(1_000_000_000_000);

    var canisterId: ?Principal = null;

    let b = await ArtistContentBucket.ArtistContentBucket(owner, managerCanister, Principal.fromActor(this));
    canisterId := ?(Principal.fromActor(b));

    switch (canisterId) {
      case null {
        throw Error.reject("@createStorageCanister: Bucket initialisation error");
      };
      case (?canisterId) {

        let self: Principal = Principal.fromActor(this);

        let controllers: ?[Principal] = ?[canisterId, owner, managerCanister, self, Principal.fromText(Env.manager[0]), cyclesManager];

        let cid = { canister_id = Principal.fromActor(this)};
        Debug.print("@createStorageCanister: IC status: "  # debug_show(await ic.canister_status(cid)));
        
        await ic.update_settings(({canister_id = canisterId; 
          settings = {
            controllers = controllers;
            freezing_threshold = null;
            memory_allocation = null;
            compute_allocation = null;
          }}));
        
        await walletUtils.transferCycles(canisterId, 1_000_000_000_000);

        // let can = actor(Principal.toText(canisterId)): actor { 
        //   initializeCyclesRequester: (Principal, CyclesRequester.TopupRule) -> async ();
        // };

        // // type method = {
        // //   #by_amount : Cycles;
        // //   #to_balance : Cycles;
        // // };

        // let topupRule: CyclesRequester.TopupRule = {
        //   threshold = 1_000_000_000_000;
        //   // method.by_amount = 1_000_000_000_000;

        // };

        // await can.initializeCyclesRequester(managerCanister, topupRule);

      };
    };
    return canisterId;
  };



  public query({caller}) func getProfileInfo(user: UserId) : async (?ArtistAccountData){
    assert(caller == owner or Utils.isManager(caller));
    Map.get(artistData, phash, user);
  };



  public shared({caller}) func updateProfileInfo( info: ArtistAccountData) : async (Bool){
    assert(caller == owner or Utils.isManager(caller));
    switch(Map.get(artistData, phash, caller)){
      case(?exists){
        ignore Map.replace(artistData, phash, caller, info);
        true
      };case null false;
    };
  };



  public shared({caller}) func removeContent(contentId: ContentId, chunkNum : Nat) : async () {
    assert(caller == owner or Utils.isManager(caller));
    switch(Map.get(contentToCanister, thash, contentId)){
      case(?canID){
        let can = actor(Principal.toText(canID)): actor { 
          removeContent: (ContentId, Nat) -> async ();
        };
        await can.removeContent(contentId, chunkNum);
        ignore Map.remove(contentToCanister, thash, contentId);
      };
      case null { };
    };
  };



  public query({caller}) func getCanisterOfContent(contentId: ContentId) : async (?CanisterId){

    Debug.print("all maps: " # debug_show Map.get(contentToCanister, thash, contentId));
    assert(caller == owner or Utils.isManager(caller));
    switch(Map.get(contentToCanister, thash, contentId)){
      case(?canisterId){
        Debug.print("@getCanisterOfContent canisterId: " # debug_show canisterId);
        return ?canisterId;
      };
      case null {
        return null
      };
    };
    
  };




  public query({caller}) func getEntriesOfCanisterToContent() : async [(CanisterId, ContentId)]{
    assert(caller == owner or Utils.isManager(caller));
    var res = Buffer.Buffer<(CanisterId, ContentId)>(2);
    for((key, value) in Map.entries(contentToCanister)){
      var contentId : ContentId = key;
      var canisterId : CanisterId = value;
      res.add(canisterId, contentId);
    };       
    return Buffer.toArray(res);
  };




  public query func getAllContentCanisters() : async [CanisterId]{
    // assert(caller == owner or Utils.isManager(caller) or caller == managerCanister);
    B.toArray(contentCanisterIds);
  };
// #endregion











// #region - UTILS
  public func getCurrentCyclesBalance(): async Nat {
    Cycles.balance();
  };


  public shared({caller}) func changeCycleAmount(amount: Nat) : (){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCycleAmount: Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    CYCLE_AMOUNT := amount;
  };



  public shared({caller}) func changeCanisterSize(newSize: Nat) : (){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCanisterSize: Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    MAX_CANISTER_SIZE := newSize;
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



  private func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept<system>(Nat.min(available, top_up_amount));
    // let accepted = Cycles.accept(top_up_amount);
    { accepted = Nat64.fromNat(accepted) };
  };


  public query({caller}) func getPrincipalThis() :  async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@getPrincipalThis: Unauthorized access. Caller is not a manager.");
    };
    Principal.fromActor(this);
  };

  public shared({caller}) func deleteAccount(): async(){
    assert(caller == owner or Utils.isManager(caller));
    let canisterId :?Principal = ?(Principal.fromActor(this));
    await canisterUtils.deleteCanister(canisterId);
  };

  public shared ({caller}) func transferFreezingThresholdCycles() : async () {
    assert(Utils.isManager(caller) or caller == owner or caller == managerCanister);
    await walletUtils.transferFreezingThresholdCycles(managerCanister);
  };


  private func getVersion() : Nat {
		return VERSION;
	};  


  public query func getVersionNumber() : async Nat {
		return VERSION;
	};  




  public shared({caller}) func deleteContentCanister(canisterId: Principal) :  async (Bool){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@deleteContentCanister: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };

    for(canister in B.vals(contentCanisterIds)){
      if(canister == canisterId){
        let index = B.indexOf<Principal>(canisterId, contentCanisterIds, Principal.equal);
        switch(index){
          case(?exists){
              let j = B.remove(contentCanisterIds, exists);

              for ((key, value) in Map.entries(contentToCanister)) {
                if(value == canisterId){
                  Map.delete(contentToCanister, thash, key);
                };
              };

              await canisterUtils.deleteCanister(?canisterId);
              return true;

          }; case null return false;
        }

      };
    };
    return false;
  };

};


// public shared func wallet_send(wallet_send: shared () -> async { accepted: Nat }, amount : Nat) : async { accepted: Nat } {// Signature of the wallet recieve function in the calling canister
//     Cycles.add(amount);
//     let l = await wallet_send();
//     { accepted = amount };
//   };