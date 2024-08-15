import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Result "mo:base/Result";

module Types{

  public type AccountIdentifier = {
    #text : Text;
    #principal : Principal;
    #blob : Blob;
  };

  // #region accountIdentifierToBlob
  public type AccountIdentifierToBlobArgs = {
    accountIdentifier : AccountIdentifier;
    canisterId : ?Principal;
  };
  public type AccountIdentifierToBlobResult = Result.Result<AccountIdentifierToBlobSuccess, AccountIdentifierToBlobErr>;
  public type AccountIdentifierToBlobSuccess = Blob;
  public type AccountIdentifierToBlobErr = {
    message : ?Text;
    kind : {
      #InvalidAccountIdentifier;
      #Other;
    };
  };
  // #endregion

// #region accountIdentifierToText
  public type AccountIdentifierToTextArgs = {
    accountIdentifier : AccountIdentifier;
    canisterId : ?Principal;
  };
  public type AccountIdentifierToTextResult = Result.Result<AccountIdentifierToTextSuccess, AccountIdentifierToTextErr>;
  public type AccountIdentifierToTextSuccess = Text;
  public type AccountIdentifierToTextErr = {
    message : ?Text;
    kind : {
      #InvalidAccountIdentifier;
      #Other;
    };
  };
// #endregion

// #region get_caller_identifier
  public type GetAccountIdentifierArgs = {
    token : Token;
    principal : Principal;
  };
  public type GetAccountIdentifierResult = Result.Result<GetAccountIdentifierSuccess, GetAccountIdentifierErr>;
  public type GetAccountIdentifierSuccess = {
    accountIdentifier : AccountIdentifier;
  };
  public type GetAccountIdentifierErr = {
    message : ?Text;
    kind : {
      #InvalidToken;
      #Other;
    };
  };
// #endregion

  public type Token =           { symbol : Text; };
  public type ArtistID          = Principal;
  public type FanID            =  Principal;
  public type ContentID         = Text;
  public type ICPTs             = { e8s : Nat64 };
  public type AdminID           = Principal;
  public type AccountId         = Blob;
  public type AccountIdText     = Text;
  public type Percentage        = Float;
  public type Ticker                    = Text;
  public type Timestamp                 = Int;
  public type SubPrice                  = Float;
  public type TransactionID     = Text;


  public type StatusRequest = {
        cycles: ?Bool;
        memory_size: ?Bool;
        heap_memory_size: ?Bool;
        version: ?Bool;
        icp_balance:?Bool;
        ckbtc_balance: ?Bool;
        trax_balance: ?Bool;
  };

  public type StatusResponse = {
        cycles: ?Nat;
        memory_size: ?Nat;
        heap_memory_size: ?Nat;
        version: ?Nat;
        icp_balance: ?Tokens;
        ckbtc_balance: ?Nat;
        trax_balance: ?Nat;
  }; 


  public type Account = {
    owner : Principal;
    subaccount : ?SubAccount;
  };
  public type Invoice = {
    to : Account;
    amount : Nat;
  };

  public type AccessType = ?{ 
    #ppv;
    #subscriber;
  };

  public type SubscriptionType = { 
    #monthly;
    #yearly;
  };

  type TransferRequest = {
        info: Text;
        from: Principal;
        to: Principal;
        amount: ICPTs;
    };

  // public type Particiants = Map.HashMap<ParticipantID, Percentage>(1, Principal.equal, Principal.hash);
  public type Content = {
    publisher: ArtistID;
    publisherPercentage:  Percentage;
    price: Float; // usd price
    participants: [Participants];
    contentType: ContentType;
    // participants: ?[(Percentage, ParticipantID)];
    // accessType: AccessType;
  };

  public type TippingParticipants = [Participants];


  public type ContentType = Text;

  public type Participants = {
    participantID: ArtistID;
    participantPercentage: Percentage;
  };
  
  public type ContentStatus = ?{ 
    #unlocked;
    #locked;
  };

  // HTTP OUTPUT TYPES 
  public type HttpHeader = {
        name : Text;
        value : Text;
    };

    public type HttpMethod = {
        #get;
        #post;
        #head;
    };

    public type TransformContext = {
        function : shared query TransformArgs -> async CanisterHttpResponsePayload;
        context : Blob;
    };

    public type CanisterHttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [HttpHeader];
        body : ?[Nat8];
        method : HttpMethod;
        transform : ?TransformContext;
    };

    public type CanisterHttpResponsePayload = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
    };

    public type TransformArgs = {
        response : CanisterHttpResponsePayload;
        context : Blob;
    };

    public type IC = actor {
        http_request : Types.CanisterHttpRequestArgs -> async Types.CanisterHttpResponsePayload;
    };




// HTTP REQUEST INTERFACE TYPES
type HeaderField = (Text, Text);

type S_Token = {};

  public type StreamingCallbackHttpResponse = {
    body : Blob;
    token : S_Token;
  };

  public type StreamingStrategy = {
    #Callback : {
      callback : shared S_Token -> async StreamingCallbackHttpResponse;
      token : S_Token;
    };
  };

public type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
  };

  public type HttpResponse = {
    status_code : Nat16;
    headers : [HeaderField];
    body : Blob;
    streaming_strategy : ?StreamingStrategy;
  };



    // **********************
    // LEDGER INTERFACE TYPES
    // **********************
    public type SubAccount = Blob;
    public type SubaccountNat8Arr   = [Nat8];
    public type Memo = Nat64;
    public type BlockIndex = Nat64;



    public type Tokens = {
     e8s : Nat64;
    };

    public type TimeStamp = {
      timestamp_nanos: Nat64;
    };

    public type BlobAccountIdentifier = Blob;

    public type TransferArgs = {
      to : [Nat8];
      fee : Tokens;
      memo : Nat64;
      from_subaccount : ?[Nat8];
      created_at_time : ?TimeStamp;
      amount : Tokens;
    };


    public type BinaryAccountBalanceArgs = {
      account : [Nat8];
    };

    public type TransferError_1 = {
      #TxTooOld : { allowed_window_nanos : Nat64 };
      #BadFee : { expected_fee : Tokens };
      #TxDuplicate : { duplicate_of : Nat64 };
      #TxCreatedInFuture;
      #InsufficientFunds : { balance : Tokens };
    };

    public type Result_1 = {
      #Ok : Nat64;
      #Err : TransferError_1;
    };

    












  public type GetBlocksArgs = {
    start : Nat64;
    length : Nat64;
  };


  public type QueryBlocksResponse = {
    certificate : ?[Nat8];
    blocks : [CandidBlock];
    chain_length : Nat64;
    first_block_index : Nat64;
    archived_blocks : [ArchivedBlocksRange];
  };


  public type ArchivedBlocksRange = {
    callback : shared query GetBlocksArgs -> async {
        #Ok : BlockRange;
        #Err : GetBlocksError;
      };
    start : Nat64;
    length : Nat64;
  };

  public type GetBlocksError = {
    #BadFirstBlockIndex : {
      requested_index : Nat64;
      first_valid_index : Nat64;
    };
    #Other : { error_message : Text; error_code : Nat64 };
  };

  public type CandidBlock = {
    transaction : CandidTransaction;
    timestamp : TimeStamp;
    parent_hash : ?[Nat8];
  };

  public type CandidTransaction = {
    memo : Nat64;
    icrc1_memo : ?[Nat8];
    operation : ?CandidOperation;
    created_at_time : TimeStamp;
  };

  public type CandidOperation = {
    #Approve : {
      fee : Tokens;
      from : [Nat8];
      allowance_e8s : Int;
      expires_at : ?TimeStamp;
      spender : [Nat8];
    };
    #Burn : { from : [Nat8]; amount : Tokens };
    #Mint : { to : [Nat8]; amount : Tokens };
    #Transfer : { to : [Nat8]; fee : Tokens; from : [Nat8]; amount : Tokens };
    #TransferFrom : {
      to : [Nat8];
      fee : Tokens;
      from : [Nat8];
      amount : Tokens;
      spender : [Nat8];
    };
  };

  public type BlockRange = {
    blocks : [CandidBlock];
  };

  type QueryArchiveError = {
    // [GetBlocksArgs.from] argument was smaller than the first block
    // served by the canister that received the request.
    #BadFirstBlockIndex : {
        requested_index : BlockIndex;
        first_valid_index : BlockIndex;
    };

    // Reserved for future use.
    #Other : {
        error_code : Nat64;
        error_message : Text;
    };
  };

  public type Block = {
    parent_hash : ?Blob;
    transaction : Transaction;
    timestamp : TimeStamp;
  };


  type Operation = {
    #Mint : {
        to : BlobAccountIdentifier;
        amount : Tokens;
    };
    #Burn : {
        from : BlobAccountIdentifier;
        amount : Tokens;
    };
    #Transfer : {
        from : BlobAccountIdentifier;
        to : BlobAccountIdentifier;
        amount : Tokens;
        fee : Tokens;
    };
  };

  type Transaction = {
    memo : Memo;
    operation : ?Operation;
    created_at_time : TimeStamp;
  };





  // **********************
  // **** XRC TYPES *****
  // **********************


  public type Asset = { class_ : AssetClass; symbol : Text };
  public type AssetClass = { #Cryptocurrency; #FiatCurrency };
  public type ExchangeRate = {
    metadata : ExchangeRateMetadata;
    rate : Nat64;
    timestamp : Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type ExchangeRateError = {
    #AnonymousPrincipalNotAllowed;
    #CryptoQuoteAssetNotFound;
    #FailedToAcceptCycles;
    #ForexBaseAssetNotFound;
    #CryptoBaseAssetNotFound;
    #StablecoinRateTooFewRates;
    #ForexAssetsNotFound;
    #InconsistentRatesReceived;
    #RateLimited;
    #StablecoinRateZeroRate;
    #Other : { code : Nat32; description : Text };
    #ForexInvalidTimestamp;
    #NotEnoughCycles;
    #ForexQuoteAssetNotFound;
    #StablecoinRateNotFound;
    #Pending;
  };
  public type ExchangeRateMetadata = {
    decimals : Nat32;
    forex_timestamp : ?Nat64;
    quote_asset_num_received_rates : Nat64;
    base_asset_num_received_rates : Nat64;
    base_asset_num_queried_sources : Nat64;
    standard_deviation : Nat64;
    quote_asset_num_queried_sources : Nat64;
  };
  public type GetExchangeRateRequest = {
    timestamp : ?Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type GetExchangeRateResult = {
    #Ok : ExchangeRate;
    #Err : ExchangeRateError;
  };





}
