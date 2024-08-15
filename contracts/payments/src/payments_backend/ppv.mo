import Principal  "mo:base/Principal";
import Nat        "mo:base/Nat";
import Nat32      "mo:base/Nat32";
import Nat64      "mo:base/Nat64";
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
import Buffer     "mo:base/Buffer";
import Cycles     "mo:base/ExperimentalCycles";
import Env        "./utils/env";
import Map        "mo:stable-hash-map/Map";
import Prim       "mo:⛔";
import ICRC1T     "./ckbtcTypes";

actor class PPV() = this{
  type ContentID                 = T.ContentID;
  type Content                   = T.Content;
  type ArtistID                  = T.ArtistID;
  type FanID                     = T.FanID;
  type AdminID                   = T.AdminID;
  type AccountIdentifier         = T.AccountIdentifier;
  type Ticker                    = T.Ticker;
  type Timestamp                 = T.Timestamp;
  type SubAccount                = Blob;
  type Percentage                = T.Percentage;
  type TransactionID             = T.TransactionID;
  type Participants              = T.Participants;
  type BlockIndex                = Nat64;
  type GetExchangeRateRequest    = T.GetExchangeRateRequest;
  type GetExchangeRateResult     = T.GetExchangeRateResult;
  type TransferArgs              = T.TransferArgs;
  type BinaryAccountBalanceArgs  = T.BinaryAccountBalanceArgs;
  type Tokens                    = T.Tokens;
  type GetBlocksArgs             = T.GetBlocksArgs;
  type QueryBlocksResponse       = T.QueryBlocksResponse;
  type Result_1                  = T.Result_1;
  type Result                    = ICRC1T.Result;
  type ContentType               = T.ContentType;
  type TransferArg               = ICRC1T.TransferArg;
  type Account                   = T.Account;
  type GetBlocksRequest          = ICRC1T.GetBlocksRequest;
  type GetTransactionsResponse   = ICRC1T.GetTransactionsResponse;
  type StatusRequest            = T.StatusRequest;
  type StatusResponse            = T.StatusResponse;
  


  
  private type FanToTime         = Map.Map<FanID, (Timestamp, Nat, Ticker)>;
  private type ArtistToFan         = Map.Map<ArtistID, FanToTime>;
  
  let { n64hash; thash; phash; } = Map;

  let FEE : Nat64                = 10000;
  let FEE_CKBTC : Nat64          = 10;
  let FEE_TRAX : Nat64           = 100_000;
  var PLATFORM_FEE: Float        = 0.10;
  var VERSION: Nat               = 1;
  stable var txNo : Nat64        = 0;
  let top_up_amount              = 10_000_000_000_000;

  stable let contentMap          = Map.new<ContentID, Content>(thash); // ContentID -> Content data: publisherID, publisher %age, participantsID, participants %age, price. 
  stable let contentPaymentMap   = Map.new<ContentID, ArtistToFan>(thash); // true false conditional which verifies whether a fan has paid.
  stable let verifiedTxs         = Map.new<BlockIndex, FanID>(n64hash);
  stable let verifiedTxsCKBTC    = Map.new<BlockIndex, FanID>(n64hash);
  stable let verifiedTxsTRAX     = Map.new<BlockIndex, FanID>(n64hash);


  let Ledger = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor {
    query_blocks : shared query GetBlocksArgs -> async QueryBlocksResponse;
    transfer : shared TransferArgs -> async  Result_1;
    account_balance : shared query BinaryAccountBalanceArgs -> async Tokens;
  };

  let XRC = actor "uf6dk-hyaaa-aaaaq-qaaaq-cai" : actor {
    get_exchange_rate : shared GetExchangeRateRequest -> async GetExchangeRateResult;
  };

  let CkBTCLedger = actor "mxzaz-hqaaa-aaaar-qaada-cai" : actor {
    icrc1_transfer : shared TransferArg -> async Result;
    icrc1_balance_of : shared query Account -> async Nat;
    get_transactions : shared query GetBlocksRequest -> async GetTransactionsResponse;
  };

  let TRAXLedger = actor "emww2-4yaaa-aaaaq-aacbq-cai" : actor {
    icrc1_transfer : shared TransferArg -> async Result;
    icrc1_balance_of : shared query Account -> async Nat;
    get_transactions : shared query GetBlocksRequest -> async GetTransactionsResponse;
  };




// #region XRC canister call
public func getExchangeRate(symbol : Text) : async Float { // can drain cycles

    let request : GetExchangeRateRequest = {
    // let request : GetExchangeRateRequest = {
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

    
    Cycles.add<system>(10_000_000_000); // Every XRC call needs 10B cycles.
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







private func checkBalance(fan: FanID, amount: Nat64) : async Bool {
    let bal = await accountBalance(fan);
    if(bal.e8s >= amount){
        return true;
    }else{
        throw Error.reject("Insufficient Balance: " # debug_show bal.e8s); 
        return false;
    }
};



// #region - PAY-PER-VIEW 
  public shared({caller}) func purchaseContent(blockIndex: Nat64, id: ContentID, ticker: Text, amount: Nat64) : async (){
      let hasPaid = await fanHasPaid(id, caller);
      assert(hasPaid == false);

      var txFee: Nat64 = 0;
      var publisherID : ?ArtistID = null;
      var publisherPercentage : Percentage = 0;
      var participants: [Participants] = [];
      var amountToSend : Nat64 = 0;

      if(ticker == "ICP"){
        txFee := FEE;
        assert(await queryBlocksICP(caller, amount, blockIndex));
      }else if (ticker == "ckBTC"){
        txFee := FEE_CKBTC;
        assert(await queryBlocksCkBTC(caller, amount, blockIndex));
      }else if (ticker == "TRAX"){ 
        txFee := FEE_TRAX;
        assert(await queryBlocksTRAX(caller, amount, blockIndex));
      }else{
        throw Error.reject("@purchaseContent: ticker is invalid");
      };
      
      switch(Map.get(contentMap, thash, id)){
      case(?content){
          Debug.print("Price of content: " # debug_show content.price);
          amountToSend := await platformDeduction(amount - (txFee * 2), ticker); // 
          publisherID := ?content.publisher;
          publisherPercentage := content.publisherPercentage;
          participants := content.participants;
        };
        case null { throw Error.reject("Could not find content object"); }
      };
        switch(publisherID){  
          case (?artist) { 
            let publishersCut :  Nat64 = await getDeductedAmount((amountToSend - FEE), publisherPercentage);
            ignore Map.put(verifiedTxs, n64hash, blockIndex, caller);
            switch(await transfer(artist, publishersCut, ticker)){
              case(#ok(res)){ 
                await addToContentPaymentMap(id, artist, ticker, caller, Nat64.toNat(publishersCut));
                Debug.print("Paid artist: " # debug_show artist # " in block " # debug_show res);
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
                throw Error.reject("Unexpected error: " # debug_show msg);    
              };
            };
          }; case null { };
        };
        var count : Nat64 = 0;
        for(collabs in Iter.fromArray(participants)){
          count := count + 1;
          // amountToSend - (FEE * count)
          let participantsCut : Nat64 = await getDeductedAmount(amountToSend - (FEE * count), collabs.participantPercentage);
          switch(await transfer(collabs.participantID, participantsCut, ticker)){
              case(#ok(res)){ 
                await addToContentPaymentMap(id, collabs.participantID, ticker, caller, Nat64.toNat(participantsCut));
              
                Debug.print("Paid artist: " # debug_show collabs.participantID #" amount: "# debug_show participantsCut #  " in block " # debug_show res);
              }; case(#err(msg)){   throw Error.reject("Unexpected error: " # debug_show msg);    };
            };
        };
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

                          switch(Map.get(verifiedTxsCKBTC, n64hash, blockIndex)){
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



  private func addToContentPaymentMap(id: ContentID, artist: ArtistID, ticker: Ticker, fan: FanID, amount: Nat) : async(){
    let now = Time.now();
    switch(Map.get(contentPaymentMap, thash, id)){
      case(?innerMap){
        switch(Map.get(innerMap, phash, artist)){
          case(?hasInit){
              ignore Map.put(hasInit, phash, fan, (now, amount, ticker));
          };
          case null {
            var x : FanToTime = Map.new<FanID, (Timestamp, Nat, Ticker)>(phash);
            
            ignore Map.put(x, phash, fan, (now, amount, ticker));
            
            ignore Map.put(innerMap, phash, artist, x);
          };
        };
        
      }; case null {
        var z : FanToTime = Map.new<FanID, (Timestamp, Nat, Ticker)>(phash);
        var y : ArtistToFan = Map.new<ArtistID, FanToTime>(phash);
        ignore Map.put(z, phash, fan, (now, amount, ticker));
        ignore Map.put(y, phash, artist, z);
        ignore Map.put(contentPaymentMap, thash, id, y);
      }
    };
  };



  public shared({caller}) func addPPVContent(id: ContentID, content : Content): async () {
    Debug.print(Principal.toText(caller) );
    Debug.print(Principal.toText(content.publisher));
    // assert(caller == content.publisher or U.isAdmin(caller));

    var totalPercentage: Percentage = content.publisherPercentage;

    for(each in Iter.fromArray(content.participants)){
      totalPercentage += each.participantPercentage;
    };

    assert(content.price > 0 and totalPercentage == 1);

    switch(Map.get(contentMap, thash, id)){
      case(?exists){
        throw Error.reject("This content ID has been taken");
      }; case null {
        ignore Map.put(contentMap, thash, id, content);    
      }
    };
  };



  public shared({caller}) func updatePPVContent (id: ContentID, content: Content) :  async (){

    var totalPercentage: Percentage = content.publisherPercentage;

    for(each in Iter.fromArray(content.participants)){
      totalPercentage += each.participantPercentage;
    };

    assert(content.price > 0 and totalPercentage == 1);

    switch(Map.get(contentMap, thash, id)){
      case(?exists){

        assert(caller == exists.publisher or U.isAdmin(caller));
        ignore Map.replace(contentMap, thash, id, content);

      }; case null{
        throw Error.reject("Content ID does not match any existing record.");
      };
    };
  };



  public shared({caller}) func removeContent(id: ContentID): async () {    
    
    switch(Map.get(contentMap, thash, id)){
      case(?exists){

         assert(caller == exists.publisher or U.isAdmin(caller));

         Map.delete(contentMap, thash, id);   

      };
      case null {
        throw Error.reject("Content ID does not match any existing record.");
      };
    };
  };



  public query func fanHasPaid(id: ContentID, fan: FanID) : async Bool{ 
    switch(Map.get(contentMap, thash, id)){
      case(?exists){
        let artistId: ArtistID = exists.publisher;

        switch(Map.get(contentPaymentMap, thash, id)){
          case(?nestedMap){
            switch(Map.get(nestedMap, phash, artistId)){
              case(?innerMap){
                switch(Map.get(innerMap, phash, fan)){
                  case(?data){
                    if (data.0 > 0){   
                      true;
                    }else{
                      false;
                    }
                  };case null false;
                }
              };case null false;  
            };
          };case null false;
        };
      };
      case null false;
    };
  };


  public shared({caller}) func showEntriesOfContentMap () : async [(ContentID, Content)] {  

    // if (not U.isAdmin(caller)) {
    //   throw Error.reject("Unauthorized access. Caller is not an admin or publisher. " # Principal.toText(caller));
    // };  

    Iter.toArray(Map.entries(contentMap));   
  };



  public query func getContent(id: ContentID) : async ?(Content){  Map.get(contentMap, thash, id); };



  public query func getAllArtistContentIDs(artist: ArtistID) : async [ContentID] {

    var ids = Buffer.Buffer<ContentID>(2);

    for((key, value) in Map.entries(contentMap)){
      if(value.publisher == artist){
        var id = key;
        ids.add(id);
      } else {
        for(i in Iter.fromArray(value.participants)){
          if(artist == i.participantID){
            var partId = key;
            Debug.print("getAllArtistContentIDs id: " # debug_show partId);
            ids.add(partId);

          };
          Debug.print("getAllArtistContentIDs ids: " # debug_show Buffer.toArray(ids));
        };
      };
    };
    return Buffer.toArray(ids);
  };



  public func getAllContentPayments() : async [(ContentID, ArtistID, FanID, Timestamp, Nat, Ticker, ContentType)]{  

    var res = Buffer.Buffer<(ContentID, ArtistID, FanID, Timestamp, Nat, Ticker, ContentType)>(2);

    for((contentId, innerMap) in Map.entries(contentPaymentMap)){
      switch(await getContent(contentId)){
        case(?content){
          var contentType = content.contentType;

          for((artistId, fanId) in Map.entries(innerMap)){
          for((k,v) in Map.entries(fanId)){

          var fanId: FanID = k;
          var timestamp: Timestamp = v.0;
          var amount: Nat = v.1;
          var ticker: Ticker = v.2;
          res.add(contentId, artistId, fanId, timestamp, amount, ticker, contentType);
          }
        }
        };
        case(null){

        }
      };

      
    };
    return Buffer.toArray(res);
  };




  public func getAllArtistContentPayments(artist: ArtistID) : async [(ContentID, FanID, Timestamp, Nat, Ticker)]{  
    let contentIds =  await getAllArtistContentIDs(artist);

    var res = Buffer.Buffer<(ContentID, FanID, Timestamp, Nat, Ticker)>(2);

    for((key, value) in Map.entries(contentPaymentMap)){
      for(eachId in Iter.fromArray(contentIds)){
        if(key == eachId){
          for((a, b) in Map.entries(value)){
            if(a == artist){
              for((k,v) in Map.entries(b)){
                  var fanId: FanID = k;
                  var timestamp: Timestamp = v.0;
                  var amount: Nat = v.1;
                  var ticker: Ticker = v.2;
                  res.add(eachId, fanId, timestamp, amount, ticker);
                }
            }
          }
        };
      };
    };
    return Buffer.toArray(res);
  };


  public func getAllFanContentPayments(fan: FanID) : async [(ContentID, Timestamp, Nat, Ticker)]{ 
    
    var res = Buffer.Buffer<(ContentID, Timestamp, Nat, Ticker)>(2);

    for((key, value) in Map.entries(contentPaymentMap)){ 
      for((a, b) in Map.entries(value)){
        for((k, v) in Map.entries(b)){
          if(k == fan){
            var contentId: ContentID = key;
            var timestamp: Timestamp = v.0;
            var amount: Nat = v.1;
            var ticker: Ticker = v.2;
            res.add(contentId, timestamp, amount, ticker);
          }
        };
      }; 
    };
  return Buffer.toArray(res);
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

















// #region - SHARED FUNCTIONS  

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











// #region UTILS


  public shared({caller}) func drainCanisterBalance(amount: Nat64, to: Principal, ticker: Ticker) : async(Bool){
    if (not U.isAdmin(caller)) {
      throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    }else{
      switch(await transfer(to, amount, ticker)){
        case(#ok(res)){
          return true;
        };
        case(#err(msg)){
          throw Error.reject("Unexpected error: " # debug_show msg);
          return false;
        };
      }
    };
    
  };




  public shared({caller}) func changePlatformFee(fee: Float) : async(){
    if (not U.isAdmin(caller)) {
      throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    }else{
      PLATFORM_FEE := fee;
    };
  };


  public query func canisterAccount() : async Account.AccountIdentifier {
    myAccountId();
  };

  public func accountBalance (account: Principal) : async Tokens{
      var specifiedAccount = Account.accountIdentifier(account, Account.defaultSubaccount());
      await Ledger.account_balance({ account = Blob.toArray(specifiedAccount) });
  };


  public func icpBalanceOfCanister() : async Tokens {
    await Ledger.account_balance({ account = Blob.toArray(myAccountId()) });
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

  private func myAccountId() : Account.AccountIdentifier {
    Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
  };

let errInvalidToken =
    #err({
       message = ?"This token is not yet supported. Currently, this canister supports ICP.";
       kind = #InvalidToken;
  });

  public query func get_account_identifier (args : T.GetAccountIdentifierArgs) : async T.GetAccountIdentifierResult {
    let token = args.token;
    let principal = args.principal;
    let canisterId = Principal.fromActor(this);
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
      canisterId = ?Principal.fromActor(this);
    });
  };





  private func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept<system>(Nat.min(available, top_up_amount));
    { accepted = Nat64.fromNat(accepted) };
  };





  public func cyclesBalance() : async Nat {
    return Cycles.balance();
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