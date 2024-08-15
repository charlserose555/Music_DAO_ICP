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
        cycles: ?Bool;
        memory_size: ?Bool;
        heap_memory_size: ?Bool;
        version: ?Bool;
        icp_balance: ?Bool;
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

   public type Tokens = {
        e8s : Nat64;
    };

}