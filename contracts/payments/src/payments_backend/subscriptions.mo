import Hash       "mo:base/Hash";
import Principal  "mo:base/Principal";
import Nat        "mo:base/Nat";
import Nat32      "mo:base/Nat32";
import Nat64      "mo:base/Nat64";
import Nat8       "mo:base/Nat64";
import Text       "mo:base/Text";
import Iter       "mo:base/Iter";
import Float      "mo:base/Float";
import T          "./types";
import Account    "./utils/account";
import Time       "mo:base/Time";
import Int        "mo:base/Int";
import Error      "mo:base/Error";
import Debug      "mo:base/Debug";
import Result     "mo:base/Result";
import U          "./utils/utils";
import Hex        "./utils/Hex";
import Blob       "mo:base/Blob";
import Array      "mo:base/Array";
import Buffer     "mo:base/Buffer";
import Trie       "mo:base/Trie";
import TrieMap    "mo:base/TrieMap";
import Cycles     "mo:base/ExperimentalCycles";
import Char       "mo:base/Char";
import Int64      "mo:base/Int64";
import Timer      "mo:base/Timer";
import Env        "./utils/env";
// import StableMap  "mo:stable-hash-map/Map";
import Map  "mo:stable-hash-map/Map";

import Ledger     "canister:ledger";
import XRC        "canister:xrc";






// TODO
// * Add functionality for PPV content (royalty sharing) to be able change participants and revenue share after initial posting
// * Adding tiers to subscriptions? (feature)
// * Ability to pause subscriptions (feature)

// * onlyOwner checks throughout contract 
// * Add msg.caller param to payment functions.
// * Change Int.hash to own hashing function or use Stable hashmap 
// * Optimise SC memory and speed, checking types and function logic


// import E "../exchange_rate/main";

actor Subscriptions {
  type ContentID                 = T.ContentID;
  type Content                   = T.Content;
  type ArtistID                  = T.ArtistID;
  type FanID                     = T.FanID;
  type AdminID                   = T.AdminID;
  type AccountIdentifier         = T.AccountIdentifier;
  type ICPTs                     = T.ICPTs;
  type Ticker                    = T.Ticker;
  type Timestamp                 = T.Timestamp;
  type SubPrice                  = T.SubPrice;
  type SubType                   = T.SubscriptionType;
  type SubAccount                = Blob;
  type Percentage                = T.Percentage;
  type TransactionID             = T.TransactionID;
  type Participants              = T.Participants;
  type Strikes                   = Nat;

  
  private type FanToTime          = Map.Map<FanID, (Timestamp, Nat64, Ticker)>;
  
  private type SubInfo            = Map.Map<FanID, (Timestamp, SubPrice, SubType, Ticker)>;
  private type SubRevenue         = Map.Map<Ticker, Nat64>;

  private type FanToTxData        = Map.Map<FanID, TxData>; 
  private type TxData             = Map.Map<Timestamp, (Nat64, Ticker)>; 

  private type FanToStrikes       = Map.Map<ArtistID, Strikes>; 

  let icp_fee: Nat = 10_000;
  stable var txNo : Nat64 = 0;

  let { ihash; nhash; thash; phash; calcHash } = Map;


  stable let subTxMap = Map.new<ArtistID, FanToTxData>(phash); 
  stable let subMap = Map.new<ArtistID, SubInfo>(phash); // Mapping keeping trax of artist a fan subscribes to and the timestamp of next subscription payment.
  stable let artistTotalSubRevenue = Map.new<ArtistID, SubRevenue>(phash); // total revenue earned through subs
  stable let latePaymentMap = Map.new<FanID, FanToStrikes>(phash); 
  

  var count          =                      0;
  let n              =                    120;
  let nMonth         =                2629800;
  let oneMin: Int    =         60_000_000_000;
  let twoMins: Int   =             oneMin * 2;
  let fourMins: Int  =             oneMin * 4;
  let fiveMins: Int  =             oneMin * 5;
  let oneDay: Int    =     86_400_000_000_000;
  let oneMonth: Int  =  2_629_800_000_000_000;
  let oneYear: Int   =          oneMonth * 12;
  

  system func timer(set : Nat64 -> ()) : async () {
    set(Nat64.fromIntWrap(Time.now()) + Nat64.fromIntWrap(oneMin)); 

    count += 1;
    Debug.print("count " # debug_show count);

    await payArtistsSub();
  };



  // public shared(msg) func updateTraxAccount(account: Text) : async(){
  //   assert(Principal.toText(msg.caller) == TRAX_ACCOUNT);
  //   TRAX_ACCOUNT := account;
  // };





// #region - SUBSCRIPTIONS

  // in the event that a transaction fails and the function 
  public shared({caller}) func _payArtistsSub() : async(){
    if (not U.isAdmin(caller)) {
      throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    };
    await payArtistsSub();
  };






  private func payArtistsSub() : async (){ // balance check

    let priceICP: Float = await getExchangeRate("ICP");

    for((key, value) in Map.entries(subMap)){
          
          let artistID : ArtistID = key;
          let subInfo: SubInfo =  value;
            for ((k, v) in Map.entries(subInfo)){

              let fanID : FanID = k;
              let timestamp : Timestamp = v.0;
              let priceOfSub : SubPrice = v.1;
              let period : SubType = v.2;
              let ticker : Ticker = v.3;
              
          if(Time.now() > timestamp){
            let formattedAmount: Nat64 = Nat64.fromIntWrap(Float.toInt((priceOfSub / priceICP) * 100000000));
            
            // let check =  await checkBalance(fanID, formattedAmount);
            // if(check == false){
            //   let unsubbed = await unsubscribe(artistID, fanID);
            // };

            Debug.print("period: " # debug_show period);
            var nextPayment : Int = 0;
            let amount : Nat64 = await platformDeduction(fanID, formattedAmount);

            switch(await transfer(fanID, artistID, amount)){
              case(#ok(res)){
                switch(Map.get(subMap, phash, artistID)){
                  case(?innerMap){
                    switch(Map.get(innerMap, phash, fanID)){   
                      case(?currVals){
                        if (period == #monthly){    nextPayment := twoMins;    };
                        if (period == #yearly) {    nextPayment := fourMins;   };
                        
                        var update = Map.replace(innerMap, phash, fanID, ((timestamp + nextPayment), priceOfSub, period, ticker));
                      }; 
                      case null {   Debug.print("Couldnt find or access FanID in subMap");    };
                    };
                  };
                  case null {   Debug.print("Couldnt find or access ArtistID in subMap");    };
                };
                
                await updateArtistTotalSubRevenue(artistID, ticker, amount);
                await addToSubTxMap(artistID, fanID, timestamp, amount, ticker);
              }; 
              case(#err(msg)){  
                await updateLatePaymentMap(artistID, fanID);
                Debug.print("ERROR at payArtistSub, this fan has been flagged as a late payer: " # debug_show msg);
              };
            };
          };
        };
      };
  };

  



  public shared(msg) func subscribe(artist: ArtistID, fan: FanID, priceOfSub: Float, ticker: Ticker, period: SubType): async Bool{

    let fanSubscribed = await isFanSubscribed(artist, fan);
    if(fanSubscribed == true) {
      throw Error.reject("FAN IS ALREADY A SUBSCRIBER!");
    };
    let priceICP = await getExchangeRate(ticker);
    Debug.print("price ICP: "# debug_show priceICP);

    Debug.print("SubType" # debug_show period);
    

      let formattedAmount: Nat64 = Nat64.fromIntWrap(Float.toInt((priceOfSub / priceICP) * 100000000));
      // let check =  await checkBalance(fan, formattedAmount);
      // assert(check == true);

      var amountICP = await platformDeduction(fan, formattedAmount);
      switch(await transfer(fan, artist, amountICP)){
          case(#ok(res)){
            await addToSubMap(artist, fan, priceOfSub, period, ticker);
            await addToSubTxMap(artist, fan, Time.now(), amountICP, ticker);
            true;
          }; 
          case(#err(msg)){
            throw Error.reject("Unexpected error: " # debug_show msg);
            false;
          };
      };
  };




  private func addToSubMap(artist: ArtistID, fan: FanID, priceOfSub: Float, period: SubType, ticker: Ticker) : async (){
    let timeNow = Time.now();
    var nextPayment: Int = 0;
    if (period == #monthly){    nextPayment := twoMins;    };
    if (period == #yearly) {    nextPayment := fourMins;   };

    switch(Map.get(subMap, phash, artist)){
      case(?innerMap){
        var b = Map.put(innerMap, phash, fan, (timeNow + nextPayment, priceOfSub, period, ticker));
        Debug.print("Fan subscribed, next payment is at: " # debug_show (timeNow + nextPayment));
      }; 
      case null {
        var x : SubInfo = Map.new<FanID, (Timestamp, Float, SubType, Ticker)>(phash);

        var d = Map.put(x, phash, fan, (timeNow + nextPayment, priceOfSub, period, ticker));
        Debug.print("Fan subscribed to new artist, next payment is at:" # debug_show (timeNow + nextPayment));
        
        var e = Map.put(subMap, phash, artist, x);
      };
    };
  };





  private func updateArtistTotalSubRevenue(artist: ArtistID, ticker: Ticker, amount: Nat64) : async (){
    switch(Map.get(artistTotalSubRevenue, phash, artist)){
      case(?innerMap){   
        switch(Map.get(innerMap, thash, ticker)){
          case(?currVal){
            var update = Map.replace(innerMap, thash, ticker, currVal + amount);   
          }; 
          case null {
            var a = Map.put(innerMap, thash, ticker, amount);
          };
        };
      };
      case null {   
        var x : SubRevenue = Map.new<Ticker, Nat64>(thash);
        var b = Map.put(x, thash, ticker, amount);
        var c = Map.put(artistTotalSubRevenue, phash, artist, x); 
      };
    };
  };





  private func updateLatePaymentMap(artist: ArtistID, fan: FanID) : async () {
    switch(Map.get(latePaymentMap, phash, fan)){
      case(?innerMap){
        switch(Map.get(innerMap, phash, artist)){
          case(?currVal){
            if(currVal >= 5){
              let success = await unsubscribe(fan, artist);
            }else{
              let update = Map.replace(innerMap, phash, artist, currVal + 1);
            };
          };
          case null {
            var a = Map.put(innerMap, phash, artist, 1);
          }
        };
      };

      case null {
        var x : FanToStrikes = Map.new<FanID, Strikes>(phash);
        var b = Map.put(x, phash, fan, 1);
        var c = Map.put(latePaymentMap, phash, artist, x);
      };
    };
  };

  public func checkLatePaymentStrikes(fan: FanID, artist: ArtistID) : async Nat{
    switch(Map.get(latePaymentMap, phash, fan)){
      case (?innerMap){
        switch(Map.get(innerMap, phash, artist)){
          case(?currVal){
            return currVal;
          };
          case null {
          return 0
          };
        };
      };
      case null {
        return 0
      };
    };
  };

  // public func getAllLatePayment(fan: FanID, artist: ArtistID) : async Nat{
  //   switch(latePaymentMap.get(fan)){
  //     case (?innerMap){
  //       switch(innerMap.get(artist)){
  //         case(?currVal){
  //           return currVal;
  //         };
  //         case null {
  //         return 0
  //         };
  //       };
  //     };
  //     case null {
  //       return 0
  //     };
  //   };
  // };




  private func addToSubTxMap(artist: ArtistID, fan: FanID, timestamp: Timestamp, amount: Nat64, ticker: Ticker) : async (){
    let idFan: Text = Principal.toText(fan);
    let stamp : Text = Int.toText(timestamp);
    let key : Text = stamp # idFan;
    Debug.print("hash text: " # debug_show key);

    switch(Map.get(subTxMap, phash, artist)){
      case(?fanToTxData){
        switch(Map.get(fanToTxData, phash, fan)){
          case(?txData){
            var a = Map.put(txData, ihash, timestamp, (amount, ticker));
          };
          case null {
            var y : TxData = Map.new<Timestamp, (Nat64, Ticker)>(ihash);
            var b = Map.put(y, ihash, timestamp, (amount, ticker));
            var c = Map.put(fanToTxData, phash, fan, y);
          };
        }
      }; 
      case null {
        var y : TxData = Map.new<Timestamp, (Nat64, Ticker)>(ihash);
        var x : FanToTxData = Map.new<FanID, TxData>(phash);

        var d = Map.put(y, ihash, timestamp, (amount, ticker));
        var e = Map.put(x, phash, fan, y);
        var f = Map.put(subTxMap, phash, artist, x);
      };
    };
  };





  public func getSubTxMapArtist(artist: ArtistID) : async [(FanID, Timestamp, Nat64, Ticker)]{
    var res = Buffer.Buffer<(FanID, Timestamp, Nat64, Ticker)>(2);

      switch(Map.get(subTxMap, phash, artist)){
        case(?fanToTxData){
            for(key in Map.keys(fanToTxData)){
                var fanId : FanID = key;
                switch(Map.get(fanToTxData, phash, fanId)){
                    case(?txData){
                        for((k, v) in Map.entries(txData)){
                            var timestamp: Timestamp = k;
                            var amount: Nat64 = v.0;
                            var ticker: Ticker = v.1;
                            res.add(fanId, timestamp, amount, ticker);
                        }
                    };
                    case null { }
                }
            };          
        };case null { };
      };
      return Buffer.toArray(res);
  };





  public func getSubTxMapFan(fan: ArtistID) : async [(ArtistID, Timestamp, Nat64, Ticker)]{
    var res = Buffer.Buffer<(ArtistID, Timestamp, Nat64, Ticker)>(2);

        for(key in Map.keys(subTxMap)){
          let artistId : ArtistID = key;
          switch(Map.get(subTxMap, phash, artistId)){
            case(?fanToTxData){
    
              for(idFan in Map.keys(fanToTxData)){
                var fanId: FanID = idFan;
                if(fanId == fan){
                    switch(Map.get(fanToTxData, phash, fan)){
                        case(?txData){
                            for((k, v) in Map.entries(txData)){
                                var timestamp: Timestamp = k;
                                var amount: Nat64 = v.0;
                                var ticker: Ticker = v.1;
                                res.add(artistId, timestamp, amount, ticker);
                            };
                        };
                        case null { }
                    };
                  }
              }
            };case null { };
          };
        };
    return Buffer.toArray(res);
  };




  public func isFanSubscribed(artist: ArtistID, fan: FanID) : async Bool{
    switch(Map.get(subMap, phash, artist)){
      case(?innerMap){
        switch(Map.get(innerMap, phash, fan)){
          case(?exists){
            true
          };
          case null false
        };
      };
      case null false;
    };
  };




  public func unsubscribe(artist: ArtistID, fan: FanID) : async Bool{
    switch(Map.get(subMap, phash, artist)){
      case(?innerMap){
        Map.delete(innerMap, phash, fan);
        Debug.print("Unsubscribed");
        true
      }; case null false;
    };
  };




  public func getArtistTotalSubRevenue(artist: ArtistID, ticker:Ticker) : async ?Nat64{    
    switch(Map.get(artistTotalSubRevenue, phash, artist)){
      case(?innerMap){
        Map.get(innerMap, thash, ticker);
      };
      case null null;
    }   
  };




  public func getNumOfSubs(artist: ArtistID) : async Nat32 {
    var numOfSubs : Nat32 = 0;
    switch(Map.get(subMap, phash, artist)){
      case(?innerMap){
        for(fans in Map.keys(innerMap)){
          numOfSubs := numOfSubs + 1;
        };
        numOfSubs;
      }; case null {
        numOfSubs;
      }
    }
  };


// #endregion




// #region XRC canister call
public func getExchangeRate(symbol : Text) : async Float {

    let request : XRC.GetExchangeRateRequest = {
      base_asset = {
        symbol = symbol;
        class_ = #Cryptocurrency;
      };
      quote_asset = {
        symbol = "USDT";
        class_ = #Cryptocurrency;
      };
      // Get the current rate.
      timestamp = null;
    };

    
    Cycles.add(10_000_000_000); // Every XRC call needs 10B cycles.
    let response = await XRC.get_exchange_rate(request);
    // Print out the response to get a detailed view.
    Debug.print(debug_show(response));
    // Return 0.0 if there is an error for the sake of simplicity.
    switch(response) {
      case (#Ok(rate_response)) {
        let float_rate = Float.fromInt(Nat64.toNat(rate_response.rate));
        let float_divisor = Float.fromInt(Nat32.toNat(10**rate_response.metadata.decimals));
        return float_rate / float_divisor;
      };
      case _ {
        return 0.0;
      };
    }
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



  private func checkBalance(fan: FanID, amount: Nat64) : async Bool {
      let bal = await accountBalance(fan);
      if(bal.e8s >= amount){
          return true;
      }else{
          throw Error.reject("Insufficient Balance: " # debug_show bal.e8s); 
          return false;
      }
  };

// #endregion







// #region - TRANSFER FUNCTIONS  

  private func platformDeduction(fan: FanID, amount : Nat64) : async Nat64 {
    let traxAccount: Principal = Principal.fromText(Env.traxAccount);
    let fee = await getDeductedAmount(amount, 0.10);
    // Debug.print("deducted amount: " # debug_show fee);
    
    switch(await transfer(fan, traxAccount, fee)){
      case(#ok(res)){
        Debug.print("Fee of: " # debug_show fee # "paid to trax account: " # debug_show traxAccount # " in block " # debug_show res);
      };case(#err(msg)){
        throw Error.reject("Unexpected error: " # debug_show msg);
      }
    };

    let amountAfterDeduction = await getRemainingAfterDeduction(amount, 0.10);
    return amountAfterDeduction;
  };


  func transfer(from: Principal, to: Principal, amount: Nat64): async Result.Result<Nat64, Text>{
    // Debug.print(Nat.fromText(Principal.toText(from)));

    let now = Time.now();
    let res = await Ledger.transfer({
          memo = txNo; 
          from_subaccount = ?Account.principalToSubaccount(from);
          to = Account.accountIdentifier(to, Account.defaultSubaccount());
          amount = { e8s = amount };
          fee = { e8s = Nat64.fromNat(icp_fee) };
          created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
        });

        Debug.print("res: "# debug_show res);
        
        switch (res) {
          case (#Ok(blockIndex)) {
            txNo += 1;
            Debug.print("Paid recipient: " # debug_show to # " in block " # debug_show blockIndex);
            return #ok(blockIndex);
          };
          case (#Err(#InsufficientFunds { balance })) {

            return #err("Insufficient balance of " # debug_show balance # " from account:" # debug_show from # "")
            
          };
          // case (#Err(#TxDuplicate {duplicate_of})) {
          //   await transfer(from, to, amount);
          // };
          case (#Err(other)) {
            return #err("Unexpected error: " # debug_show other);
          };
        };
  };
// #endregion








// #region Utils







  public query func canisterAccount() : async Account.AccountIdentifier {
    myAccountId();
  };

  public func accountBalance (account: Principal) : async Ledger.Tokens{
      var specifiedAccount = Account.accountIdentifier(account, Account.defaultSubaccount());
      await Ledger.account_balance({ account = specifiedAccount });
  };


  public func canisterBalance() : async Ledger.Tokens {
    await Ledger.account_balance({ account = myAccountId() });
  };

  private func myAccountId() : Account.AccountIdentifier {
    Account.accountIdentifier(Principal.fromActor(Subscriptions), Account.defaultSubaccount());
  };

  // func principalKey(s : Principal) : Trie.Key<Principal> {
  //       { key = s; hash = Principal.hash(s) };
  // };

  // func textKey(s : Text) : Trie.Key<Text> {
  //       { key = s; hash = Text.hash(s) };
  // };

  let errInvalidToken =
    #err({
       message = ?"This token is not yet supported. Currently, this canister supports ICP.";
       kind = #InvalidToken;
  });

  public query func get_account_identifier (args : T.GetAccountIdentifierArgs) : async T.GetAccountIdentifierResult {
    let token = args.token;
    let principal = args.principal;
    let canisterId = Principal.fromActor(Subscriptions);
    switch (token.symbol) {
      case "ICP" {
        let subaccount = U.getDefaultAccount({principal; canisterId;});
        let hexEncoded = Hex.encode(
          Blob.toArray(subaccount)
        );
        let result : AccountIdentifier = #text(hexEncoded);
        #ok({accountIdentifier = result});
      };
      case _ {
        errInvalidToken;
      };
    };
  };

  public func accountIdentifierToBlob (accountIdentifier : AccountIdentifier) : async T.AccountIdentifierToBlobResult {
    U.accountIdentifierToBlob({
      accountIdentifier;
      canisterId = ?Principal.fromActor(Subscriptions);
    });
  };
// #endregion

}
