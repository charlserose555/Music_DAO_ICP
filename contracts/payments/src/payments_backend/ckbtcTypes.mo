import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
// import Result "mo:base/Result";


module Types{
// **********************
  // **** ICRC1 TYPES *****
  // **********************
  public type SubAccount = Blob;
  public type Account = {
    owner : Principal;
    subaccount : ?SubAccount;
  };


  public type TransferArg = {
    to : Account;
    fee : ?Nat;
    memo : ?[Nat8];
    from_subaccount : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type Result = { #Ok : Nat; #Err : TransferError };

  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type GetBlocksRequest = { start : Nat; length : Nat };
  public type GetTransactionsResponse = {
    first_index : Nat;
    log_length : Nat;
    transactions : [Transaction];
    archived_transactions : [ArchivedRange_1];
  };
  public type Value = {
    #Int : Int;
    #Map : [(Text, Value)];
    #Nat : Nat;
    #Nat64 : Nat64;
    #Blob : [Nat8];
    #Text : Text;
    #Array : Vec;
  };
  public type ArchivedRange_1 = {
    callback : shared query GetBlocksRequest -> async {
        transactions : [Transaction];
      };
    start : Nat;
    length : Nat;
  };

  public type Transaction = {
    burn : ?Burn;
    kind : Text;
    mint : ?Mint;
    approve : ?Approve;
    timestamp : Nat64;
    transfer_from : ?TransferFrom;
    transfer : ?Transfer;
  };

  public type TransferFrom = {
    to : Account;
    fee : ?Nat;
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
    spender : Account;
  };


  public type Transfer = {
    to : Account;
    fee : ?Nat;
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type Burn = {
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type Mint = {
    to : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type Approve = {
    fee : ?Nat;
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    spender : Account;
  };
  
  public type Vec = [
    {
      #Int : Int;
      #Map : [(Text, Value)];
      #Nat : Nat;
      #Nat64 : Nat64;
      #Blob : [Nat8];
      #Text : Text;
      #Array : Vec;
    }
  ];

}