import Principal      "mo:base/Principal";
import Nat            "mo:base/Nat";
import Nat64          "mo:base/Nat64";
import Text           "mo:base/Text";
import Iter           "mo:base/Iter";
import T              "./types";
import Account        "./utils/account";
import Time           "mo:base/Time";
import Int            "mo:base/Int";
import Error          "mo:base/Error";
import Debug          "mo:base/Debug";
import Result         "mo:base/Result";
import U              "./utils/utils";
import Blob           "mo:base/Blob";
import Cycles         "mo:base/ExperimentalCycles";
import Map            "mo:stable-hash-map/Map";
import Env            "./utils/env";
import Float          "mo:base/Float";
import ICRC1T         "./ckbtcTypes";
import Prim           "mo:⛔";
import Buffer         "mo:base/Buffer";

// actor class Tipping(_network : BT.Network) = this{
actor class Tipping() = this{
  
  type ArtistID                  = T.ArtistID;
  type FanID                     = T.FanID;
  type AdminID                   = T.AdminID;
  type AccountIdentifier         = T.AccountIdentifier;
  type ICPTs                     = T.ICPTs;
  type Ticker                    = T.Ticker;
  type Timestamp                 = T.Timestamp;
  type SubAccount                = Blob;
  type BlockIndex                = Nat64;
  type TransferArgs              = T.TransferArgs;
  type BinaryAccountBalanceArgs  = T.BinaryAccountBalanceArgs;
  type Tokens                    = T.Tokens;
  type GetBlocksArgs             = T.GetBlocksArgs;
  type QueryBlocksResponse       = T.QueryBlocksResponse;
  type Result_1                  = T.Result_1;
  type Result                    = ICRC1T.Result;
  type HttpRequest               = T.HttpRequest;
  type HttpResponse              = T.HttpResponse;
  type TippingParticipants       = T.TippingParticipants;
  type TransferArg               = ICRC1T.TransferArg;
  type Account                   = T.Account;
  type GetBlocksRequest          = ICRC1T.GetBlocksRequest;
  type GetTransactionsResponse   = ICRC1T.GetTransactionsResponse;
  type StatusRequest             = T.StatusRequest;
  type StatusResponse            = T.StatusResponse;

  type ReferralType = {
    #firstYear;
    #lifetime;
  };

  let { ihash; n64hash; phash; } = Map;
  
  let FEE : Nat64                     = 10_000;
  let FEE_CKBTC : Nat64               = 10;
  let FEE_TRAX : Nat64                = 100_000;
  stable var txNo : Nat64             = 0;
  var PLATFORM_FEE: Float             = 0.10;
  var REFERRAL_FEE_YEAR: Float        = 0.05;
  var REFERRAL_FEE_LIFETIME: Float    = 0.01;
  var VERSION: Nat                    = 1;
  let top_up_amount                   = 2_000_000_000_000;

  private type FanToTippingData       = Map.Map<FanID, TippingData>;
  private type TippingData            = Map.Map<Timestamp, (Nat, Ticker)>;

  private type ArtistToReferralData   = Map.Map<ArtistID, ReferralData>;
  private type ReferralData           = Map.Map<Timestamp, (Nat, Ticker)>;


  private type ArtistToReferralType   = Map.Map<ArtistID, ReferralType>;

  stable let tippingMap               = Map.new<ArtistID, FanToTippingData>(phash); // Keep record of every tip transaction
  stable let verifiedTxs              = Map.new<BlockIndex, FanID>(n64hash);
  stable let verifiedTxsCKBTC         = Map.new<BlockIndex, FanID>(n64hash);
  stable let verifiedTxsTRAX          = Map.new<BlockIndex, FanID>(n64hash);

                                        // referrer -> referee -> referType
  stable let referralMap              = Map.new<ArtistID, ArtistToReferralType>(phash);
  stable let referralTxs              = Map.new<ArtistID, ArtistToReferralData>(phash);


  let Ledger = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor {
  // let Ledger = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : actor {
       query_blocks : shared query GetBlocksArgs -> async QueryBlocksResponse;
       transfer : shared TransferArgs -> async  Result_1;
       account_balance : shared query BinaryAccountBalanceArgs -> async Tokens;
  };

  let CkBTCLedger = actor "mxzaz-hqaaa-aaaar-qaada-cai" : actor {
  // let CkBTCLedger = actor "be2us-64aaa-aaaaa-qaabq-cai" : actor {
       icrc1_transfer : shared TransferArg -> async Result;
       icrc1_balance_of : shared query Account -> async Nat;
       get_transactions : shared query GetBlocksRequest -> async GetTransactionsResponse;
  };

  let TRAXLedger = actor "emww2-4yaaa-aaaaq-aacbq-cai" : actor {
    // let TRAXLedger = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : actor {
         icrc1_transfer : shared TransferArg -> async Result;
         icrc1_balance_of : shared query Account -> async Nat;
         get_transactions : shared query GetBlocksRequest -> async GetTransactionsResponse;
  };

  public shared({caller}) func addToReferralMap(referrer: ArtistID, referee: ArtistID): async(){
    if (not U.isAdmin(caller)) {
      throw Error.reject("@addToReferralMap: Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    };
    let referType: ReferralType = #firstYear;
    var y : ArtistToReferralType = Map.new<ArtistID, ReferralType>(phash);
    ignore Map.put(y, phash, referee, referType);
    ignore Map.put(referralMap, phash, referrer, y);
  };


  // private func addToReferralTxs(referrer: ArtistID, referee: ArtistID, ticker: Ticker, amount: Nat64) : async (){
  //   let now = Time.now();
  //   switch(Map.get(referralTxs, phash, referee)){
  //     case(?artistToReferralTypeData){
      
  //       switch(Map.get(artistToReferralTypeData, phash, referee)){
  //           case(?referralData){
  //               var add = Map.put(referralData, ihash, now, (Nat64.toNat(amount), ticker));
  //           };
  //           case null {
  //               var y : ReferralData = Map.new<Timestamp, (Nat, Ticker)>(ihash);
  //               var a = Map.put(y, ihash, now, (Nat64.toNat(amount), ticker));
  //               var b = Map.put(artistToReferralTypeData, phash, referrer, y);
  //           };
  //       };
  //     };
  //     case null {
  //         var y : ReferralData = Map.new<Timestamp, (Nat, Ticker)>(ihash);
  //         var x : ArtistToReferralData = Map.new<ArtistID, ReferralData>(phash);
  //         var a = Map.put(y, ihash, now, (Nat64.toNat(amount), ticker));
  //         var b = Map.put(x, phash, referee, y);
  //         var c = Map.put(referralTxs, phash, referrer, x);
  //     };
  //   };
  // };
  


// , referredArtist: Bool
// #region - TRANSFER LOGIC
  public shared({caller}) func sendTip(blockIndex: Nat64, participants: TippingParticipants, amount: Nat64, ticker: Ticker) : async (){

    assert(amount > 0);

    var amountToSend: Nat64 = 0;
    var txFee: Nat64 = 0;

    if(ticker == "ICP"){
      assert(await queryBlocksICP(caller, amount, blockIndex));
      txFee := FEE;
      // if(referredArtist){
      //   amountToSend := await getDeductedAmount(amount, PLATFORM_FEE);

      //   // switch(Map.get(referralMap, phash, ))

      //   let amountToSendPlatform: Nat64 = await getDeductedAmount(amount, REFERRAL_FEE_YEAR);
      // }else{
      amountToSend := await platformDeduction(amount - txFee, ticker);
      // };
      ignore Map.put(verifiedTxs, n64hash, blockIndex, caller);

    }else if(ticker == "ckBTC"){
      assert(await queryBlocksCkBTC(caller, amount, blockIndex));
      txFee := FEE_CKBTC;
      amountToSend := await platformDeduction(amount - txFee, ticker); 
      ignore Map.put(verifiedTxsCKBTC, n64hash, blockIndex, caller);
    }else if(ticker == "TRAX"){
      assert(await queryBlocksTRAX(caller, amount, blockIndex));
      txFee := FEE_TRAX;
      amountToSend := await platformDeduction(amount - txFee, ticker); 
      ignore Map.put(verifiedTxsTRAX, n64hash, blockIndex, caller);
    }else{
      throw Error.reject("@sendTip: ticker is invalid");
    };

    Debug.print(debug_show participants);
    var count : Nat64 = 0;
      for(collabs in Iter.fromArray(participants)){
        count := count + 1;
        // amountToSend - (FEE * count)
        let participantsCut : Nat64 = await getDeductedAmount(amountToSend - (txFee * count), collabs.participantPercentage);
        Debug.print(debug_show collabs.participantID);
        Debug.print(debug_show participantsCut);

        
          switch(await transfer(collabs.participantID, participantsCut, ticker)){
            case(#ok(res)){ 
              await addToTippingMap(caller, collabs.participantID, ticker, participantsCut);
            
              Debug.print("@sendTip: Paid artist: " # debug_show collabs.participantID #"\namount: "# debug_show participantsCut #  "\nin block " # debug_show res);
            }; case(#err(msg)){
              if(ticker == "ICP"){
                Map.delete(verifiedTxs, n64hash, blockIndex);
              }else if(ticker == "ckBTC"){
                Map.delete(verifiedTxsCKBTC, n64hash, blockIndex);
              }else if(ticker == "TRAX"){
                Map.delete(verifiedTxsTRAX, n64hash, blockIndex);
              }else{
                throw Error.reject("@sendTip: Failed to delete from verified Txs - unknown ticker. " # debug_show msg);    
              };
              throw Error.reject("@sendTip: Unexpected error: " # debug_show msg);    
            };
          };
      };
  };




  private func queryBlocksICP(caller: Principal, amountToSend: Nat64, blockIndex: Nat64) : async (Bool){
      let blockQuery = await Ledger.query_blocks({
      start = blockIndex;
      length = 1;
    });

    for(block in Iter.fromArray(blockQuery.blocks)){
      switch(block.transaction){
        case(tx){
          switch(tx.operation){
                 case(?operation){
                  switch(operation){
                    case(#Transfer{from; to; amount;}){
                      Debug.print("@queryBlocksICP: amount comparison...\n amount: " # debug_show amount # "\namountToSend: " # debug_show amountToSend);
                      Debug.print("@queryBlocksICP: blockIndex: " # debug_show blockIndex);

                      if(Account.accountIdentifier(caller, Account.defaultSubaccount()) == Blob.fromArray(from) 
                         and 
                         Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount()) == Blob.fromArray(to)
                         and amountToSend == amount.e8s){

                          switch(Map.get(verifiedTxs, n64hash, blockIndex)){
                            case(?sender){
                                if(sender == caller){
                                throw Error.reject("@queryBlocksICP: This tx has already been verified.");
                                return false;
                              };
                            }; case null { 
                              return true;
                            };
                          };

                      }else{
                        throw Error.reject("@queryBlocksICP: Could not validate tx, from and to fields do not match inputs:\n" # debug_show from # " " # Principal.toText(caller) );
                        return false;
                      };
                    };
                    case(#Mint{amount;}){
                      return false;
                    };
                    case(#Burn{from;}){
                      return false;
                    };
                    case(#Approve{from;}){
                      return false;
                    };
                    case(#TransferFrom{from;}){
                      return false;
                    }
                  };
                 };
                 case(null){
                  return false;
                 };
            };
          };
        };
    };
    return false;
  };



  private func queryBlocksCkBTC(caller: Principal, amount: Nat64, blockIndex: Nat64) : async (Bool){
      let blockQuery = await CkBTCLedger.get_transactions({
      start = Nat64.toNat(blockIndex);
      length = 1;
    });

    for(tx in Iter.fromArray(blockQuery.transactions)){
      switch(tx.transfer){
        case(?transfer){
          if(caller == transfer.from.owner and Principal.fromActor(this) == transfer.to.owner and Nat64.toNat(amount) == transfer.amount){
              switch(Map.get(verifiedTxsCKBTC, n64hash, blockIndex)){
                case(?sender){
                    if(sender == caller){
                    
                    throw Error.reject("@queryBlocksCkBTC: This tx has already been verified.");
                    return false;
                    
                  };
                }; case null {
                  return true;
                };
              };
          }else{
            throw Error.reject("@queryBlocksCkBTC: Could not validate tx, from and to fields do not match inputs:\n" # debug_show transfer.from.owner # " " # Principal.toText(caller) );
            return false;
          };
        };
        case(null){
          return false;
        };           
      };
    };
    return false;
  };



  private func queryBlocksTRAX(caller: Principal, amount: Nat64, blockIndex: Nat64) : async (Bool){
      let blockQuery = await TRAXLedger.get_transactions({
      start = Nat64.toNat(blockIndex);
      length = 1;
    });

    for(tx in Iter.fromArray(blockQuery.transactions)){
      switch(tx.transfer){
        case(?transfer){
          if(caller == transfer.from.owner and Principal.fromActor(this) == transfer.to.owner and Nat64.toNat(amount) == transfer.amount){
              switch(Map.get(verifiedTxsTRAX, n64hash, blockIndex)){
                case(?sender){
                    if(sender == caller){
                    
                    throw Error.reject("@queryBlocksTRAX: This tx has already been verified.");
                    return false;
                    
                  };
                }; case null { 
                  return true;
                };
              };
          }else{
            throw Error.reject("@queryBlocksTRAX: Could not validate tx, from and to fields do not match inputs:\n" # debug_show transfer.from.owner # " " # Principal.toText(caller) );
            return false;
          };
        };
        case(null){
          return false;
        };
      };
    };
    return false;
  };




  private func addToTippingMap(fanId: FanID, artistId: ArtistID, ticker: Ticker, amount: Nat64) : async (){
    let now = Time.now();
    switch(Map.get(tippingMap, phash, artistId)){
      case(?fanToTippingData){
      
        switch(Map.get(fanToTippingData, phash, fanId)){
            case(?tippingData){
                ignore Map.put(tippingData, ihash, now, (Nat64.toNat(amount), ticker));
            };
            case null {
                var y : TippingData = Map.new<Timestamp, (Nat, Ticker)>(ihash);
                ignore Map.put(y, ihash, now, (Nat64.toNat(amount), ticker));
                ignore Map.put(fanToTippingData, phash, fanId, y);
            };
        };
        
      };
      case null {
          var y : TippingData = Map.new<Timestamp, (Nat, Ticker)>(ihash);
          var x : FanToTippingData = Map.new<FanID, TippingData>(phash);
          ignore Map.put(y, ihash, now, (Nat64.toNat(amount), ticker));
          ignore Map.put(x, phash, fanId, y);
          ignore Map.put(tippingMap, phash, artistId, x);
      };
    };
  };




  public query func getAllTippingTransactions() : async [(ArtistID, FanID, Timestamp, Nat, Ticker)]{
    var data = Buffer.Buffer<(ArtistID, FanID, Timestamp, Nat, Ticker)>(2);

    for((key, val) in Map.entries(tippingMap)){
      var artist: ArtistID = key;
      for((key, value) in Map.entries(val)){
        var fanID: FanID = key;
          for((k, v) in Map.entries(value)){
              var timestamp: Timestamp = k;
              var amount: Nat = v.0;
              var ticker: Ticker = v.1;
              data.add(artist, fanID, timestamp, amount, ticker);
          }
      }
    };
   return Buffer.toArray(data);
  };




  private func platformDeduction(amount : Nat64, ticker: Ticker) : async Nat64 {
    let traxAccount: Principal = Principal.fromText(Env.traxAccount);
    let fee = await getDeductedAmount(amount, PLATFORM_FEE);
    // Debug.print("deducted amount: " # debug_show fee);
    
    switch(await transfer(traxAccount, fee, ticker)){
      case(#ok(res)){
        Debug.print("@platformDeduction:\nFee of: " # debug_show fee # "\nwith ticker: " # ticker #"\npaid to trax account: " # debug_show traxAccount # "\nin block " # debug_show res);
      };case(#err(msg)){
        throw Error.reject("@platformDeduction: Unexpected error:\n" # debug_show msg);
      }
    };
    
    let amountAfterDeduction = await getRemainingAfterDeduction(amount, 0.10);
    return amountAfterDeduction;
  };




  private func transfer(to: Principal, amount: Nat64, ticker: Ticker): async Result.Result<Nat64, Text>{
    let now = Time.now();
    try {
      if(ticker == "ICP"){

        let res = await Ledger.transfer({
          memo = txNo; 
          from_subaccount = null;
          to = Blob.toArray(Account.accountIdentifier(to, Account.defaultSubaccount()));
          amount = { e8s = amount };
          fee = { e8s = FEE };
          created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
        });
        
        switch (res) {
          case (#Ok(blockIndex)) {
            txNo += 1;
            Debug.print("@transfer:\nPaid recipient ICP: " # debug_show to # "\nin block " # debug_show blockIndex);
            return #ok(blockIndex);
          };
          case (#Err(transferError)) {
            return #err("@transfer: Couldn't transfer ICP funds to default account:\n" # debug_show (transferError));
          };
        };

      }else if(ticker == "ckBTC"){

        let transferResult = await CkBTCLedger.icrc1_transfer(
          {
            amount = Nat64.toNat(amount);
            from_subaccount = null;
            created_at_time = null;
            fee = ?10;
            memo = null;
            to = {
              owner = to;
              subaccount = null;
            };
          }
        );

        switch (transferResult) {
          case (#Ok(transferResult)) {
              txNo += 1;
              Debug.print("@transfer: Paid recipient ckBTC: " # debug_show to # " in block " # debug_show transferResult);
              return #ok(Nat64.fromNat(transferResult));
          };
          case (#Err(transferError)) {
            return #err("@transfer: Couldn't transfer ckBTC funds to default account:\n" # debug_show (transferError));
          };
          
        };

      }else if(ticker == "TRAX"){

        let transferResult = await TRAXLedger.icrc1_transfer(
          {
            amount = Nat64.toNat(amount);
            from_subaccount = null;
            created_at_time = null;
            fee = ?100_000;
            memo = null;
            to = {
              owner = to;
              subaccount = null;
            };
          }
        );

        switch (transferResult) {
          case (#Ok(transferResult)) {
              txNo += 1;
              Debug.print("@transfer: Paid recipient TRAX: " # debug_show to # " in block " # debug_show transferResult);
              return #ok(Nat64.fromNat(transferResult));
          };
          case (#Err(transferError)) {
            return #err("@transfer: Couldn't transfer TRAX funds to default account:\n" # debug_show (transferError));
          };
          
        };

      }else{
        throw Error.reject("@transfer: ticker in invalid");
      };
      
    } catch (error : Error) {
      return #err("@transfer: Reject message: " # Error.message(error));
    };
  };
// #endregion





// #region - HELPER FUNCTIONS
  private func getRemainingAfterDeduction(amount: Nat64, percent: Float) : async(Nat64){
    let priceFloat : Float = Float.fromInt(Nat64.toNat(amount));
    let deduction :  Float = priceFloat * percent;
    return Nat64.fromNat(Int.abs(Float.toInt(priceFloat - deduction)))
  };




  private func getDeductedAmount(amount: Nat64, percent: Float) : async(Nat64){
    let priceFloat : Float = Float.fromInt(Nat64.toNat(amount));
    return Nat64.fromNat(Int.abs(Float.toInt(priceFloat * percent)));
  };
// #endregion









// #region - UTILS
  public shared({caller}) func drainCanisterBalance(amount: Nat64, to: Principal, ticker: Ticker) : async(Bool){
    if (not U.isAdmin(caller)) {
      throw Error.reject("@drainCanisterBalance: Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    }else{
      switch(await transfer(to, amount, ticker)){
        case(#ok(res)){
          return true;
        };
        case(#err(msg)){
          throw Error.reject("@drainCanisterBalance: Unexpected error:\n" # debug_show msg);
          return false;
        };
      }
    };
  };




  public shared({caller}) func changePlatformFee(fee: Float) : async(){
    if (not U.isAdmin(caller)) {
      throw Error.reject("@changePlatformFee: Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    }else{
      PLATFORM_FEE := fee;
    };
  };




  public func accountIdentifierToBlob (accountIdentifier : AccountIdentifier) : async T.AccountIdentifierToBlobResult {
    U.accountIdentifierToBlob({
      accountIdentifier;
      canisterId = ?Principal.fromActor(this);
    });
  };






  public func canisterAccount() : async Account.AccountIdentifier {
    await myAccountId(Principal.fromActor(this));
  };




  private func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept<system>(Nat.min(available, top_up_amount));
    { accepted = Nat64.fromNat(accepted) };
  };




  public query func cyclesBalance() : async Nat {
      return Cycles.balance();
  };




  public func icpBalanceOfCanister() : async Tokens {
    await Ledger.account_balance({ account = Blob.toArray(await myAccountId(Principal.fromActor(this))) });
  };



  public func icpBalance(principal: Principal) : async Tokens {
    await Ledger.account_balance({ account = Blob.toArray(await myAccountId(principal)) });
  };




  public func ckbtcBalance(principal: Principal) : async Nat{
    await CkBTCLedger.icrc1_balance_of(
      {owner = principal; subaccount = null }
    );
  };

  public func traxBalance(principal: Principal) : async Nat{
    await TRAXLedger.icrc1_balance_of(
      {owner = principal; subaccount = null }
    );
  };


  public func ckbtcBalanceOfCanister() : async Nat{
    await CkBTCLedger.icrc1_balance_of(
      {owner = Principal.fromActor(this); subaccount = null }
    );
  };

  public func traxBalanceOfCanister() : async Nat{
    await TRAXLedger.icrc1_balance_of(
      {owner = Principal.fromActor(this); subaccount = null }
    );
  };




  public func myAccountId(principal: Principal) : async Account.AccountIdentifier {
    Account.accountIdentifier(principal, Account.defaultSubaccount());
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
              switch(_request.icp_balance){
                case(?checkIcpBal){
                  switch(await icpBalanceOfCanister()){
                    case(_bal){
                      icp_balance := ?_bal;
                    };
                  };
                };case null {};
              };

              var ckbtc_balance: ?Nat = null;
              switch(_request.ckbtc_balance){
                case(?checkCkbtcBal){
                  switch(await ckbtcBalanceOfCanister()){
                    case(_bal){
                      ckbtc_balance := ?_bal;
                    };
                  };
                };case null {};
              };

              var trax_balance: ?Nat = null;
              switch(_request.trax_balance){
                case(?checkTraxBal){
                  switch(await traxBalanceOfCanister()){
                    case(_bal){
                      trax_balance := ?_bal;
                    };
                  };
                };case null {};
              };

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



  private func getVersion() : Nat {
		return VERSION;
	};  

// #endregion
}