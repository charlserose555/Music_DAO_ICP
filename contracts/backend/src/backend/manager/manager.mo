import Cycles             "mo:base/ExperimentalCycles";
import Principal          "mo:base/Principal";
import Error              "mo:base/Error";
import IC                 "../ic.types";
import FanBucket          "../fan/account-bucket";
import ArtistBucket       "../artist/account-bucket";
import Nat                "mo:base/Nat";
import Map                "mo:stable-hash-map/Map";
import Debug              "mo:base/Debug";
import Text               "mo:base/Text";
import T                  "../types";
import Nat64              "mo:base/Nat64";
import Iter               "mo:base/Iter";
import Blob               "mo:base/Blob";
import Buffer             "mo:base/Buffer";
import CanisterUtils      "../utils/canister.utils";
import WalletUtils        "../utils/wallet.utils";
import Utils              "../utils/utils";
import Prim               "mo:⛔";
import Env                "../env";

actor Manager {

  type FanAccountData                 = T.FanAccountData;
  type ArtistAccountData              = T.ArtistAccountData;
  type UserType                       = T.UserType;
  type UserId                         = T.UserId;
  type CanisterId                     = T.CanisterId;
  type StatusRequest                  = T.StatusRequest;
  type StatusResponse                 = T.StatusResponse;
  type Tokens                         = T.Tokens;
  type CanisterStatus                 = IC.canister_status_response;
  
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils       = WalletUtils.WalletUtils();

  private let ic : IC.Self = actor "aaaaa-aa";

  private let cyclesManagerId : Principal = Principal.fromText("exmw2-raaaa-aaaan-qecxa-cai");

  let { thash; phash; } = Map;

  stable var CYCLE_AMOUNT : Nat         = 100_000_000_000;
  stable var numOfFanAccounts: Nat      = 0;
  stable var MAX_CANISTER_SIZE: Nat     = 68_700_000_000; // <-- approx. 64GB
  stable var numOfArtistAccounts: Nat   = 0;
  var VERSION: Nat                      = 1;
  let top_up_amount                     =  2_000_000_000_000;
  
  

  stable let userToCanisterMap    = Map.new<Text, (Principal, Nat64)>(thash);
  stable let fanAccountsMap       = Map.new<UserId, CanisterId>(phash);
  stable let artistAccountsMap    = Map.new<UserId, CanisterId>(phash);



// #region - CREATE ACCOUNT CANISTERS
  public shared({caller}) func createProfileFan(accountData: FanAccountData) : async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@createProfileFan: Unauthorized access. Caller is not the manager. Caller: " # Principal.toText(caller));
    };
    await createCanister(accountData.userPrincipal, #fan, ?accountData, null);
  };




  public shared({caller}) func createProfileArtist(accountData: ArtistAccountData) : async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("@createProfileArtist: Unauthorized access. Caller is not the manager. Caller: " # Principal.toText(caller));
    };
    await createCanister(accountData.userPrincipal, #artist, null, ?accountData);
  };  




  private func createCanister(userID: Principal, userType: UserType, accountDataFan: ?FanAccountData, accountDataArtist: ?ArtistAccountData): async (Principal) {
    Debug.print("@createCanister: userID: " # Principal.toText(userID));
    
    Cycles.add<system>(1_000_000_000_000);

    var canisterId: ?Principal = null;

    if (userType == #fan) {
      switch(Map.get(fanAccountsMap, phash, userID)){
        case(?exists){
          throw Error.reject("@createCanister: This principal is already associated with an account");
        }; case null{
          let b = await FanBucket.FanBucket(accountDataFan, userID);
          canisterId := ?(Principal.fromActor(b));
        }
      }
    } else {
      switch(Map.get(artistAccountsMap, phash, userID)){
        case(?exists){
          throw Error.reject("@createCanister: This principal is already associated with an account");
        }; case null {
          let b = await ArtistBucket.ArtistBucket(accountDataArtist, userID, cyclesManagerId);
          canisterId := ?(Principal.fromActor(b));
        };
      };
    };

    let bal = getCurrentCycles();
    Debug.print("@createCanister: Cycles Balance After Canister Creation: " #debug_show bal);

    // if(bal < CYCLE_AMOUNT){
    //    // notify frontend that cycles is below threshold
    //    throw Error.reject("@createCanister: Manager canister is out of cycles! Please replenish supply.");
    // };

    switch (canisterId) {
      case null {
        throw Error.reject("@createCanister: Bucket init error, your account canister could not be created.");
      };
      case (?canisterId) {
        let self: Principal = Principal.fromActor(Manager);

        let controllers: ?[Principal] = ?[canisterId, userID, self, cyclesManagerId, Principal.fromText(Env.manager[0])];
        
        await ic.update_settings(({canister_id = canisterId; 
          settings = {
            controllers = controllers;
            freezing_threshold = null;
            memory_allocation = null;
            compute_allocation = null;
          }}));

          await walletUtils.transferCycles(canisterId, 2_000_000_000_000);

        if (userType == #fan) {   
          ignore Map.put(fanAccountsMap, phash, userID, canisterId);
          numOfFanAccounts := numOfFanAccounts + 1;
        } else {   
          ignore Map.put(artistAccountsMap, phash, userID, canisterId);
          numOfArtistAccounts := numOfArtistAccounts + 1;
        };
        return canisterId;
      };
    };
  };


  private func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept<system>(Nat.min(available, top_up_amount));
    // let accepted = Cycles.accept(top_up_amount);
    { accepted = Nat64.fromNat(accepted) };
  };

// #endregion






// #region - FETCH STATE
  public query func getTotalFanAccounts() :  async Nat{    
    numOfFanAccounts   
  };  




  public query func getTotalArtistAccounts() :  async Nat{   
    numOfArtistAccounts   
  }; 




  public query({caller}) func getFanAccountEntries() : async [(Principal, Principal)]{    
    if (not Utils.isManager(caller)) {
      throw Error.reject("@getFanAccountEntries: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    Iter.toArray(Map.entries(fanAccountsMap));    
  };




  public query({caller}) func getArtistAccountEntries() : async [(UserId, CanisterId)]{   
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@getArtistAccountEntries: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    var res = Buffer.Buffer<(UserId, CanisterId)>(2);
    for((key, value) in Map.entries(artistAccountsMap)){
      var artistId : Principal = key;
      var canisterId : Principal = value;
      res.add(artistId, canisterId);
    };       
    return Buffer.toArray(res);

    // Iter.toArray(Map.entries(artistAccountsMap));    
  };




  public query({caller}) func getCanisterFan(fan: Principal) : async (?Principal){    
    assert(caller == fan or Utils.isManager(caller));
    Map.get(fanAccountsMap, phash, fan);   
  };




  public query({caller}) func getCanisterArtist(artist: Principal) : async (?Principal){   
    // assert(caller == artist or Utils.isManager(caller));
    Map.get(artistAccountsMap, phash, artist);    
  };




  public query({caller}) func getOwnerOfFanCanister(canisterId: Principal) : async (?UserId){ 
    if (not Utils.isManager(caller)) {
      throw Error.reject("@getOwnerOfFanCanister: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    for((key, value) in Map.entries(fanAccountsMap)){
      var fan: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return fan;
      };
    };
    return null;
  };




  public query({caller}) func getOwnerOfArtistCanister(canisterId: Principal) : async (?UserId){ 
    if (not Utils.isManager(caller)) {
      throw Error.reject("@getOwnerOfArtistCanister: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    for((key, value) in Map.entries(artistAccountsMap)){
      var artist: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return artist;
      };
    };
    return null;
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
// #endregion






// #region - UTILS
  public shared({caller}) func changeCycleAmount(amount: Nat) : (){  // utils based 
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCycleAmount: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    CYCLE_AMOUNT := amount;   
  };




  public shared({caller}) func changeCanisterSize(newSize: Nat) : (){    // utils based
    if (not Utils.isManager(caller)) {
      throw Error.reject("@changeCanisterSize: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    MAX_CANISTER_SIZE := newSize;
  };




  public shared({caller}) func transferOwnershipFan(currentOwner: Principal, newOwner: Principal) : async (){
    assert(caller == currentOwner or Utils.isManager(caller));
    switch(Map.get(fanAccountsMap, phash, currentOwner)){
      case(?canisterId){
        Map.delete(fanAccountsMap, phash, currentOwner);
        ignore Map.put(fanAccountsMap, phash, newOwner, canisterId);

      }; case null throw Error.reject("@transferOwnershipFan: This fan account doesnt exist");
    };
  };




  public shared({caller}) func transferOwnershipArtist(currentOwner: Principal, newOwner: Principal) : async (){
    assert(caller == currentOwner or Utils.isManager(caller));
    switch(Map.get(artistAccountsMap, phash, currentOwner)){
      case(?canisterId){
        ignore Map.replace(artistAccountsMap, phash, newOwner, canisterId);
      }; case null throw Error.reject("@transferOwnershipArtist: This artist account doesnt exist.");
    };
  };





  public shared({caller}) func transferCyclesToAccountCanister(canisterId : Principal, amount : Nat) : async () { 
    // assert(caller == canisterId or Utils.isManager(caller));
    for(value in Map.vals(artistAccountsMap)){
      if(canisterId == value){
        await walletUtils.transferCycles(canisterId, amount);
      }
    };
  };

  public  func transferCyclesToCanister(canisterId : Principal, amount : Nat) : async () { 
    // assert(caller == canisterId or Utils.isManager(caller));
    
        await walletUtils.transferCycles(canisterId, amount);
      
  };



  public shared({caller}) func transferCyclesToContentCanister(accountCanisterId : Principal, contentCanisterId : Principal, amount : Nat) : async () { 
    // assert(caller == contentCanisterId or Utils.isManager(caller) or caller == accountCanisterId);
    for(value in Map.vals(artistAccountsMap)){
      if(accountCanisterId == value){
        let can = actor(Principal.toText(accountCanisterId)): actor { 
          getAllContentCanisters: () -> async [CanisterId];
        };
        for(canID in Iter.fromArray(await can.getAllContentCanisters())){
          if(canID == contentCanisterId){
            await walletUtils.transferCycles(contentCanisterId, amount);
          }
        };
      }
    };
  };




  public shared({caller}) func deleteAccountCanister(user: UserId, canisterId: Principal, userType: UserType) :  async (Bool){
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@deleteAccountCanister: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    if(userType == #fan){
      switch(Map.get(fanAccountsMap, phash, user)){
        case(?fanAccount){
          Map.delete(fanAccountsMap, phash, user);
          await canisterUtils.deleteCanister(?canisterId);
          return true;
        };
        case null false
      }
    }else{
       switch(Map.get(artistAccountsMap, phash, user)){
        case(?artistAccount){
          Map.delete(artistAccountsMap, phash, user);
          await canisterUtils.deleteCanister(?canisterId);
          return true;
        };
        case null false
      }
    }
  };




  public shared({caller}) func installCode(canisterId : Principal, owner : Blob, wasmModule : Blob) : async () {
    Debug.print("@installCode: caller is: " # Principal.toText(caller));
    if (not Utils.isManager(caller)) {
      throw Error.reject("@installCode: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    };
    Debug.print("install code has been initiated");
    await canisterUtils.installCode(canisterId, owner, wasmModule);
  };


   public shared({caller}) func getCanisterStatus() : async CanisterStatus {
    // if (not Utils.isManager(caller)) {
    //   throw Error.reject("@cyclesBalance: Unauthorized access. Caller is not the manager. Caller is: " # Principal.toText(caller));
    // };
    return await canisterUtils.canisterStatus(?Principal.fromActor(Manager));
  };


  // #endregion
};
