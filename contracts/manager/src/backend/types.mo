import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Result "mo:base/Result";
import IC "./ic.types";

module Types {

    public type UserId = Principal; 
    public type CanisterId = IC.canister_id;
    
    public type Timestamp = Int;
    
    public type ContentId = Text; // chosen by createVideo
    public type VideoId = Text; // chosen by createVideo
    public type ChunkId = Text; // VideoId # (toText(ChunkNum))
    
    public type ProfilePhoto = Blob; // encoded as a PNG file
    public type CoverPhoto = Blob;

    // public type Thumbnail = Blob; // encoded as a PNG file
    public type ChunkData = Blob; // encoded as ???

    public type FileExtension = {
      #jpeg;
      #jpg;
      #png;
      #gif;
      #svg;
      #mp3;
      #wav;
      #aac;
      #mp4;
      #avi;
    };


    public type ContentInit = {
      userId : UserId;
      name: Text;
      createdAt : Timestamp;
      description: Text;
      tags: [Text];
      chunkCount: Nat;
      extension: FileExtension;
      size: Nat;
      contentId: Text;
      // thumbnail: ?Thumbnail;
      // trailer: ?Trailer;
    };

    public type Thumbnail = {
      name: Text;
      extension: FileExtension;
      size: Nat;
      file: ?Blob;
    };
    public type Trailer = {
      name: Text;
      chunkCount: Nat;
      extension: FileExtension;
      size: Nat;
      file: ?Blob;
    };

    public type ContentData = {
      contentId : Text;
      userId : UserId;
      createdAt : Timestamp;
      uploadedAt : Timestamp;
      description: Text;
      tags: [Text];
      name: Text;
      chunkCount: Nat;
      extension: FileExtension;
      size: Nat;
    };


    public type FanAccountData = {
        userPrincipal: Principal;
        createdAt: Timestamp;
        // profilePhoto: ?ProfilePhoto;
    };

    public type UserType = {
        #fan;
        #artist;
    };

    public type ArtistAccountData = {
        createdAt: Timestamp;
        userPrincipal: Principal;
        // profilePhoto: ?ProfilePhoto;
        // coverPhoto: ?CoverPhoto;
    };


    public type StatusRequest = {
        cycles: Bool;
        memory_size: Bool;
        heap_memory_size: Bool;
        version: Bool;
    };

    public type StatusResponse = {
        cycles: ?Nat;
        memory_size: ?Nat;
        heap_memory_size: ?Nat;
        version: ?Nat;
    }; 


// - Cycle Manager types
    public type Cycles = Nat;

  /// For resources on choosing a good topup rule, check out https://www.notion.so/cycleops/Best-Practices-for-Top-up-Rules-e3e9458ec96f46129533f58016f66f6e
  public type TopupRule = {
    // Top-up when <= this cycle threshold.
    threshold : Cycles;

    // Method of determining amount of cycles to top-up with.
    method : {

      // Top-up with enough cycles to restore the specified balance.
      // i.e. `threshold`      = 10 | 10 | 10
      //      `toBalance`      = 20 | 20 | 20
      //      `balance`        = 8  | 10 | 12
      //      `cyclesToSend`   = 12 | 10 | 0
      #to_balance : Cycles;

      // Top-up to with a fixed amount of cycles.
      // i.e. `threshold`    = 10 | 10 | 10
      //      `topUpAmount`  = 5  | 5  | 5
      //      `balance`      = 8  | 10 | 12
      //      `cyclesToSend` = 5  | 5  | 0
      #by_amount : Cycles;
    };
  };
}