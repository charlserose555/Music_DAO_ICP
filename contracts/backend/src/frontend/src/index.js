import { Actor, HttpAgent } from '@dfinity/agent';
import { canisterId, dyn_canisters_backend } from '../../declarations/dyn_canisters_backend';
import { idlFactory as fanBucketIDL } from '../../declarations/fan_bucket/fan_bucket.did.js';
import { idlFactory as artistBucketIDL} from '../../declarations/artist_account_bucket/artist_account_bucket.did.js'
import { idlFactory as artistContentBucketIDL} from '../../declarations/artist_content_bucket/artist_content_bucket.did.js'
import { Principal } from '@dfinity/principal'; 
// import PlugConnect from '@psychedelic/plug-connect';
import {useUploadVideo} from './video';
// import {getFileExtension, getReverseFileExtension } from "./video2";
const MAX_CHUNK_SIZE = 1024 * 500; // 500kb
const REWARDS_CHECK_INTERVAL = 60000;
const hashtagRegExp = /(?:\s|^)#[A-Za-z0-9\-._]+(?:\s|$)/gim;

export const createBucketActor = async ({ idl, canisterId }) => {
  // console.log(idlFactory)
  const agent = new HttpAgent();

  // if (process.env.NODE_ENV !== 'production') {
    await agent.fetchRootKey();
  // }

  return Actor.createActor(idl, {
    agent,
    canisterId
  });
};

let bucket;
let registeredBuckets = [];


const getAllCanisters= () =>{

  console.log(registeredBuckets)
}




const createFanProfile = async () => {
  let username = document.getElementById('username');
  let displayName = document.getElementById('displayName');
  let userPrincipal = document.getElementById('principal');
  // let gender = document.getElementById('gender');
  let emailAddress = document.getElementById('email');
  let lastName = document.getElementById('lastName');
  let firstName = document.getElementById('firstName');

  let fanAccountData = {
    firstName: firstName.value,
        lastName: lastName.value,
        userPrincipal: Principal.fromText(userPrincipal.value),
        username: username.value,
        displayName: displayName.value,
        emailAddress: emailAddress.value,
  }
  try {
    bucket = await dyn_canisters_backend.createProfileFan(fanAccountData);
    console.log('New bucket:', bucket.toText());
    registeredBuckets.push(bucket.toString());
    let connected = document.querySelector("#connectCanID");
    connected.value = bucket;
    await initCanister(bucket, "fan");
  } catch (err) {
    console.error(err);
  }
};



const initCanister = async (bucket, type) => {
  // console.log(idlFactory)
  try {
    let actor;
    if(type === "artist"){
      actor = await createBucketActor({
        idl: artistBucketIDL,
        canisterId: bucket
      });
    }else{
      actor = await createBucketActor({
        idl: fanBucketIDL,
        canisterId: bucket
      });
    }
    
    let res = await actor.initCanister()
    console.log("init canister res: " + res);
  } catch (err) {
    console.error(err);
  }
};



const transferOwner = async() => {
  
  let newOwnerInput = document.querySelector("#newOwner");
  let currentOwnerInput = document.querySelector("#oldOwner");
  let currentOwner = Principal.fromText(currentOwnerInput.value);
  let newOwner = Principal.fromText(newOwnerInput.value);

  let canId = await dyn_canisters_backend.getCanisterFan(currentOwner);
  try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    await dyn_canisters_backend.transferOwnershipFan(currentOwner, newOwner);
    let res = await actor.transferOwnership(currentOwner, newOwner);
    console.log(res);

  } catch (err) {
    console.error(err);
  }
}






const getProfileInfo = async() =>{
  let userPrincipal = document.querySelector('#getInfoPrince')
  let canId = await dyn_canisters_backend.getCanisterFan(Principal.fromText(userPrincipal.value))
  console.log(canId.toString());

  // let connected = document.querySelector("#connectCanID");
  // console.log(connected.value);
  
  try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    let res = await actor.getProfileInfo(Principal.fromText(userPrincipal.value));
    var username = document.querySelector("#usernameP");
    var displayName = document.querySelector("#displayNameP");
    var principal = document.querySelector("#principalP");
    var firstName = document.querySelector("#firstNameP");
    var lastName = document.querySelector("#lastNameP");
    var email = document.querySelector("#emailP");
    console.log(res[0]);
    // console.log(res);

    username.value = res[0].username;
    displayName.value = res[0].displayName;
    principal.value = res[0].userPrincipal.toString();
    firstName.value = res[0].firstName;
    lastName.value = res[0].lastName;
    email.value = res[0].emailAddress;

  } catch (err) {
    console.error(err);
  }
}





const updateProfile = async () =>{
  let principal = document.querySelector('#getInfoPrince')
  let canId = await dyn_canisters_backend.getCanisterFan(Principal.fromText(principal.value))
  console.log(canId.toString());

  let username = document.getElementById('usernameP');
  let displayName = document.getElementById('displayNameP');
  let userPrincipal = document.getElementById('principalP');
  // let gender = document.getElementById('gender');
  let emailAddress = document.getElementById('emailP');
  let lastName = document.getElementById('lastNameP');
  let firstName = document.getElementById('firstNameP');

  let newFanAccountData = {
      firstName: firstName.value,
      lastName: lastName.value,
      userPrincipal: Principal.fromText(userPrincipal.value),
      username: username.value,
      displayName: displayName.value,
      emailAddress: emailAddress.value,
  }
try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    console.log(await actor.updateProfileInfo(newFanAccountData.userPrincipal, newFanAccountData));
  } catch (err) {
    console.error(err);
  }


}

















const createProfileArtist = async () => {
  let userPrincipal = document.getElementById('principalA');
  
  let artistAccountData = {
    createdAt: BigInt(Number(Date.now() * 1000)),
    userPrincipal: Principal.fromText(userPrincipal.value),
    
  }

  try {
    bucket = await dyn_canisters_backend.createProfileArtist(artistAccountData);
    console.log('New bucket:', bucket.toText());
    registeredBuckets.push(bucket.toString());
    let connected = document.querySelector("#connectCanID");
    connected.value = bucket;
    await initCanister(bucket, "artist");
  } catch (err) {
    console.error(err);
  };
};



const getProfileInfoArtist = async() =>{
  let userPrincipal = document.querySelector('#getInfoPrinceA')
  let canId = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(userPrincipal.value))
  console.log(canId.toString());

  // let connected = document.querySelector("#connectCanID");
  // console.log(connected.value);
  
  try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: canId.toString()
    });

    let res = await actor.getProfileInfo(Principal.fromText(userPrincipal.value));

    var username = document.querySelector("#usernamePA");
    var displayName = document.querySelector("#displayNamePA");
    var principal = document.querySelector("#principalPA");
    var firstName = document.querySelector("#firstNamePA");
    var lastName = document.querySelector("#lastNamePA");
    var email = document.querySelector("#emailPA");
    var country = document.querySelector("#countryPA");
    var dob = document.querySelector("#dateOfBirthPA");
    var bio = document.querySelector("#bioPA");
    console.log(res[0]);
    
    // console.log(res);

    username.value = res[0].username;
    displayName.value = res[0].displayName;
    principal.value = res[0].userPrincipal.toString();
    firstName.value = res[0].firstName;
    lastName.value = res[0].lastName;
    email.value = res[0].emailAddress;
    country.value = res[0].country;
    dob.value = Number(res[0].dateOfBirth);
    bio.value = res[0].bio;

  } catch (err) {
    console.error(err);
  }
}




const updateProfileArtist = async () =>{
  let principal = document.querySelector('#getInfoPrinceA');
  let canId = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(principal.value))
  console.log(canId.toString());

  var username = document.querySelector("#usernamePA");
    var displayName = document.querySelector("#displayNamePA");
    // var principal = document.querySelector("#principalPA");
    var firstName = document.querySelector("#firstNamePA");
    var lastName = document.querySelector("#lastNamePA");
    var email = document.querySelector("#emailPA");
    var country = document.querySelector("#countryPA");
    var dob = document.querySelector("#dateOfBirthPA");
    var bio = document.querySelector("#bioPA");

  let newArtistAccountData = {
      firstName: firstName.value,
      lastName: lastName.value,
      userPrincipal: Principal.fromText(principal.value),
      username: username.value,
      displayName: displayName.value,
      emailAddress: email.value,
      country: country.value,
      dateOfBirth: BigInt(dob.value),
      bio: bio.value 
  }
try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: canId.toString()
    });
    console.log(await actor.updateProfileInfo(newArtistAccountData.userPrincipal, newArtistAccountData));
  } catch (err) {
    console.error(err);
  }


}






const getThisPrincipal = async () =>{
  let connected = document.querySelector("#connectCanID")
  try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: connected.value
    });
    console.log("ACTOR: " + actor);
    
    let res = await actor.getPrincipalThis();
    console.log("RES: " + res)
    console.log("BUCKET: " + bucket)
  } catch (err) {
    console.error(err);
  }
}





const getMyCanisterID = async () =>{
  
  try{

    let input = document.querySelector("#canOwner")
    let owner = Principal.fromText(input.value);
    let res = await dyn_canisters_backend.getCanisterFan(owner);
    console.log(res.toString())

  }catch(error){
    console.log(error)
  }
  
}





const getOwnerOfCanisterId = async () =>{
  
  try{
    let input   = document.querySelector("#canID")
    let canID   = Principal.fromText(input.value)
    let res     = await dyn_canisters_backend.getOwnerOfFanCanister(canID)
    console.log(res.toString());
  }catch(error){
    console.log(error);
  };
};






const getMyCanisterIDArtist = async () =>{
  
  try{
    let input = document.querySelector("#canOwnerArtist");
    let owner = Principal.fromText(input.value);
    let res = await dyn_canisters_backend.getCanisterArtist(owner);
    console.log(res.toString())

  }catch(error){
    console.log(error)
  }
}





const getOwnerOfCanisterIdArtist = async () =>{
  
  try{
    let input   = document.querySelector("#canIDA")
    let canID   = Principal.fromText(input.value)
    let res     = await dyn_canisters_backend.getOwnerOfArtistCanister(canID)
    console.log(res.toString());
  }catch(error){
    console.log(error);
  };
};



// const upload = async()=>{
//   // const videoFile = document.getElementById('video-upload');
//   const userId = document.getElementById('id-artist-upload');
//   const canisterId = await dyn_canisters_backend.getCanisterArtist(userId.value);

  
//   const caption = document.getElementsById('caption-content');
//     if (!videoFile || !caption) {
//       return;
//     }
//     // useUploadVideo.setFile(videoFile);
//     // useUploadVideo.setCaption(caption);
//     // useUploadVideo.setReady(true);
//     handleUpload()
//     useUploadVideo(userId, videoFile, true)
//     // setUploading(true);
// }
const getFileExtension = (type)  => {
  switch(type) {
    case 'image/jpeg':
      return { 'jpeg' : null };
    case 'image/gif':
      return { 'gif' : null };
    case 'image/jpg':
      return { 'jpg' : null };
    case 'image/png':
      return { 'png' : null };          
    case 'image/svg':
      return { 'svg' : null };          
    case 'video/avi':
      return { 'avi' : null };                            
    case 'video/aac':
      return { 'aac' : null };
    case 'video/mp4':
      return { 'mp4' : null };        
    case 'audio/wav':
      return { 'wav' : null };                         
    case 'audio/mp3':
      return { 'mp3' : null };
    default :
    return null;
  }
};

const getReverseFileExtension = (type) => {
  switch(Object.keys(type)[0]) {
    case 'jpeg':
      return  'image/jpeg';
    case 'gif':
      return  'image/gif'; 
    case 'jpg':
      return  'image/jpg';       
    case 'png':
      return  'image/png';
    case 'svg':
      return  'image/svg';
    case 'avi':
      return  'video/avi';
    case 'mp4':
      return  'video/mp4';
    case 'aac':
      return  'video/aac';
    case 'wav':
      return  'audio/wav';
    case 'mp3':
      return  'audio/mp3';                                                                                                              
    default :
    return "";
  }
};

var fileType;


const upload = async () => {
  // const videoFile = document.getElementById('video-upload');
  // const file = handleFileChange(videoFile)
  // event.preventDefault();
  console.log(fileType)
  const fileExtension = getFileExtension(fileType.type);
  console.log(fileExtension);
  const errors = [];
  if (fileType === null || fileType === undefined || fileExtension === null) {
    errors.push("File not valid!");
  }
  if (fileType.size > 10550000) {
    errors.push("File size shouldn't be bigger than 10mb");
  }

  // if (errors.length > 0) {
  //   setErrros(errors);
  //   return;
  // }
  
  const t0 = performance.now();
  console.log('upload started...');
  // setUploading(true);

  const userId = document.getElementById('id-artist-upload');
  console.log(typeof userId.value);
  const canisterId = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(userId.value));
  console.log("artist-account-bucket canisterID: " + canisterId);
  

  var randomContentID = Math.random().toString(36).substring(2);
  const fileInfo  = { // ContentInit type
    name: fileType.name,
    createdAt: BigInt(Number(Date.now() * 1000)),
    size: BigInt(fileType.size),
    description: "Something",
    tags: ["hiphop",  "dance", "grime"],
    chunkCount: BigInt(Number(Math.ceil(fileType.size / MAX_CHUNK_SIZE))),
    extension: fileExtension,
    userId: Principal.fromText(userId.value),
    contentId: randomContentID,
  };

  // const thumbnail = {
  //   contentId: randomContentID,
  //   userId: Principal.fromText(userId.value),
  //   name: fileType.name + " thumbnail",
  //     chunkCount: BigInt(Number(Math.ceil(fileType.size / MAX_CHUNK_SIZE))),
  //     extension: fileExtension,
  //     size: Nat;
  //     file: '',
    
  //   size: 
  // }
  console.log(fileInfo)

  

  const actor = await createBucketActor({
    idl: artistBucketIDL,
    canisterId: canisterId.toString()
  });

  let allContentCanisters = await actor.getAllContentCanisters();
  console.log("allContentCanisters: ", allContentCanisters)
  // console.log("ACTOR: " + actor);

  // const ba = await BackendActor.getBackendActor();
  // setValue(10);
  // const authenticated = await authClient.isAuthenticated();
  // console.log(authenticated);

  const createRes = await actor.createContent(fileInfo);
  console.log("Create Res[0][1]:  " + createRes[0][1]);
  console.log("Create Res[0][0]:  " + createRes[0][0]);
  // storageCanisterID = createRes[1];
  // console.log(fileId);
  // setValue(40);
  const blob = fileType.blob;
  console.log(blob)
  const putChunkPromises = [];
  let chunk = 1;
  for (let byteStart = 0; byteStart < fileType.size; byteStart += MAX_CHUNK_SIZE, chunk++ ) {
    putChunkPromises.push(
      processAndUploadChunk(blob, byteStart, createRes[0][0], chunk, fileType.size, createRes[0][1])
    );
  }

  await Promise.all(putChunkPromises);
  // await ba.updateStatus();
  // setValue(100);
  // setUploading(false);
  // setReady(false);
  // updateDeps();
  // setFileData('Drag and drop a file or select add File');
  const t1 = performance.now();
  console.log("processAndUploadChunk finish!!")
  console.log("Upload took " + (t1 - t0) / 1000 + " seconds.")
}

const encodeArrayBuffer = (file) => Array.from(new Uint8Array(file));

const processAndUploadChunk = async ( blob, byteStart, fileId, chunk, fileSize, canisterId) => {
  const blobSlice = blob.slice(
    byteStart,
    Math.min(Number(fileSize), byteStart + MAX_CHUNK_SIZE),
    blob.type
  );
 
  const bsf = await blobSlice.arrayBuffer();
  // const ba = await BackendActor.getBackendActor();

  const actor = await createBucketActor({
    idl: artistContentBucketIDL,
    canisterId: canisterId.toString()
  });
  // console.log("ACTOR: " + actor);
  console.log("chunk: " + chunk);
  // console.log(fileId);
  // console.log(chunk);
  // console.log(fileSize);
  // console.log(encodeArrayBuffer(bsf));
  // console.log("processAndUploadChunk finish!!")
  return actor.putContentChunk(fileId, BigInt(chunk), encodeArrayBuffer(bsf));
}




const b64toBlob = (b64Data, contentType='', sliceSize=512) => {
      
  const byteCharacters = window.atob(b64Data);
  const byteArrays = [];

  for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
    const slice = byteCharacters.slice(offset, offset + sliceSize);

    const byteNumbers = new Array(slice.length);
    for (let i = 0; i < slice.length; i++) {
      byteNumbers[i] = slice.charCodeAt(i);
    }

    const byteArray = new Uint8Array(byteNumbers);
    byteArrays.push(byteArray);
  }
  const blob = new Blob(byteArrays, { type: contentType } );
  const url = URL.createObjectURL(blob);

  let img = document.getElementById('image-download');

  img.height = 100;
  img.width = 100;

  img.onload = function() {
    URL.revokeObjectURL(img.src);     // clean-up memory
    document.body.appendChild(img);   // add image to DOM
  }
  img.src = url; 

  console.log(blob)

  return blob;
}




const handleFileChange = (event) => {
    // setErrros([]);
    // setReady(false);
    // @ts-ignore
    console.log("HERERE : " + event.target.files[0]);
    const file = event.target.files[0];
    // Make new FileReader
    var reader = new FileReader();
    // Convert the file to base64 text
    reader.readAsDataURL(file);
    reader.onloadend = () => {
      if (reader.result === null) {
        throw new Error('file empty...');
      }
      let encoded = reader.result.toString().replace(/^data:(.*,)?/, '');
      if ((encoded.length % 4) > 0) {
        encoded += '='.repeat(4 - (encoded.length % 4));
      }
      const blob = b64toBlob(encoded, file.type);
      console.log(blob);
      
      fileType = { // FILE READER INFO
        name: file.name,
        type: file.type,
        size: file.size,
        blob: blob,
        file: file,
        width: file.width,
        height: file.height
      };

      console.log(file);
      console.log(file.name + ' | ' + Math.round(file.size / 1000) + ' kB');


      // return fileInfo

      
    //   setFileData(file.name + ' | ' + Math.round(file.size / 1000) + ' kB');
      
    //   setFile(fileInfo);
    //   setReady(true);
    };
};


const downloadFile = async () =>{
  var userPrincipal = document.getElementById('download-principal');
  var contentId = document.getElementById('download-content-id');
  // var canIdContent = document.getElementById('download-canister-id');
  console.log(contentId.value);

  let artistAccountCanister = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(userPrincipal.value));

  console.log(artistAccountCanister.toString());

  const accountBucket = await createBucketActor({
    idl: artistBucketIDL,
    canisterId: artistAccountCanister.toString()
  });

  console.log("artistAccountCanister: "+artistAccountCanister.toString())

  var artistContentCanister = await accountBucket.getCanisterOfContent(contentId.value);
  
  
  console.log("artistContentCanister: ", artistContentCanister.toString())

  const contentBucket = await createBucketActor({
    idl: artistContentBucketIDL,
    canisterId: artistContentCanister.toString()
  });

  var allContentCanistersAndIDs = await accountBucket.getEntriesOfCanisterToContent();
  for(let i = 0; i < allContentCanistersAndIDs.length; i++){
    console.log("allContentCanistersAndIDs: ", allContentCanistersAndIDs[i].toString());
  }
  console.log("allContentCanistersAndIDs: ", allContentCanistersAndIDs)


  var contentData = await contentBucket.getContentInfo(Principal.fromText(userPrincipal.value), contentId.value);
  console.log(contentData);
  console.log(contentData[0].extension);

  // var contentChunks = await contentBucket.getContentChunk(contentId, contentData.chunkCount);

  var chunks = [];
    for (let i = 1; i <= Number(contentData[0].chunkCount); i++) {
      const chunk = await contentBucket.getContentChunk(contentId.value, BigInt(i));
      if (chunk[0]) {
        chunks.push(new Uint8Array(chunk[0]).buffer);
      }
    }
    
  console.log(chunks);
  const blob = new Blob(chunks, { type: getReverseFileExtension(contentData[0].extension)} );
  const url = URL.createObjectURL(blob);
  console.log(blob)
  console.log(url);

  // console.log(getReverseFileExtension(contentData[0].extension).slice(0, 5));

  // if(getReverseFileExtension(contentData[0].extension) == "video/mp4"){
  //   let vid = document.getElementById('video-download');
  //   vid.src = usableUrl.toString();

  // }else if(getReverseFileExtension(contentData[0].extension).slice(0, 5) == "image"){
  //   let img = document.getElementById('image-download');
  //   img.src = usableUrl.toString();
  // }

  let img = document.getElementById('image-download');
          
            // img.src = URL.createObjectURL(blob);
            img.height = 100;
            img.width = 100;
            // img.onload = function() {
            //     URL.revokeObjectURL(this.src);
            //   } 

  var downloadLink = document.createElement("a");
        downloadLink.download = contentData[0].name;
        if (window.webkitURL != null) {
          downloadLink.href = window.webkitURL.createObjectURL(blob);
      } else {
          downloadLink.href = window.URL.createObjectURL(blob);
          downloadLink.onclick = document.body.removeChild(event.target);
          downloadLink.style.display = "none";
          document.body.appendChild(downloadLink);
      }
      downloadLink.click();

  // img = new Image();

  img.onload = function() {
    URL.revokeObjectURL(img.src);     // clean-up memory
    document.body.appendChild(img);   // add image to DOM
  }
  img.src = url; 




  // console.log(blob)
  // console.log(url.toString());
  
  // let usableUrl = url.slice(5)
  // console.log(usableUrl)
  // if(getReverseFileExtension(contentData[0].extension) == "video/mp4"){
  //   let vid = document.getElementById('video-download');
  //   vid.src = usableUrl.toString();

  // }else if(getReverseFileExtension(contentData[0].extension) == "image/png"){
  //   let img = document.getElementById('image-download');
  //   img.src = usableUrl.toString();
  // }
 






}


const init = () => {

  const btnInit = document.querySelector('button#create');
  btnInit.addEventListener('click', createFanProfile);

  const btnGetProfile = document.querySelector('#getProfile');
  btnGetProfile.addEventListener('click', getProfileInfo);
  
  const transferOwnership = document.querySelector('button#transferOwnership');
  transferOwnership.addEventListener('click', transferOwner);

  const update = document.querySelector('button#updateProfile');
  update.addEventListener('click', updateProfile);

  const getCanisterID = document.querySelector('button#getCanID');
  getCanisterID .addEventListener('click', getMyCanisterID);

  const getOwnerOfCanister = document.querySelector('button#getFanID');
  getOwnerOfCanister.addEventListener('click', getOwnerOfCanisterId);

  const getAllBuckets = document.querySelector('button#getAllBuckets');
  getAllBuckets.addEventListener('click', getAllCanisters);

  const getActorPrincipal = document.querySelector('button#getThisPrincipal');
  getActorPrincipal.addEventListener('click', getThisPrincipal);

  const uploadVideo = document.querySelector('button#postContent');
  uploadVideo.addEventListener('click', upload)

  const createArtistProfile = document.querySelector('button#createA');
  createArtistProfile.addEventListener('click', createProfileArtist);

  const updateArtistProfile = document.querySelector('button#updateProfileA');
  updateArtistProfile.addEventListener('click', updateProfileArtist);

  const getAProfile = document.querySelector('button#getProfileA');
  getAProfile.addEventListener('click', getProfileInfoArtist);

  const getCanIDArtist = document.querySelector('button#getCanIDArtist');
  getCanIDArtist.addEventListener('click', getMyCanisterIDArtist)

  const getArtistIDCAN = document.querySelector('button#getArtistID');
  getArtistIDCAN.addEventListener('click', getOwnerOfCanisterIdArtist)

  const fileUploadInput = document.querySelector('input#video-upload');
  fileUploadInput.addEventListener('change', (file)=>{
    handleFileChange(file);
  } );

  const downloadVideo = document.querySelector('button#downloadContent');
  downloadVideo.addEventListener('click', downloadFile);

  // const uploadContent
  
};

document.addEventListener('DOMContentLoaded', init);
