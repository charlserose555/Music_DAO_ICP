import { Principal } from "@dfinity/principal";
import { FileExtension, ContentInfo } from '../declarations/dyn_canisters_backend/dyn_canisters_backend.did';


// interface FileReaderInfo {
//     name: string;
//     type: string;
//     size: number;
//     blob: Blob;
//     width: number;
//     file: number;
//     height: number;
//   }

let file;

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
  
 export const getFileExtension = (type)  => {
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


const handleChange = (event) => {
    setErrros([]);
    setReady(false);
    // @ts-ignore
    const file = event.target.files[0];
    // Make new FileReader
    const reader = new FileReader();
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
      const fileInfo = { // FILE READER INFO
        name: file.name,
        type: file.type,
        size: file.size,
        blob: blob,
        file: file,
        width: file.width,
        height: file.height
      };

      console.log(file);
    //   setFileData(file.name + ' | ' + Math.round(file.size / 1000) + ' kB');
      console.log(file.name + ' | ' + Math.round(file.size / 1000) + ' kB');
    //   setFile(fileInfo);
    //   setReady(true);
    };
};


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
    return blob;
}





 const processAndUploadChunk = async ( blob, byteStart, fileId, chunk, fileSize,) => {
    const blobSlice = blob.slice(
      byteStart,
      Math.min(Number(fileSize), byteStart + MAX_CHUNK_SIZE),
      blob.type
    );
   
    const bsf = await blobSlice.arrayBuffer();
    const ba = await BackendActor.getBackendActor();
    // console.log(fileId);
    // console.log(chunk);
    // console.log(fileSize);
    // console.log(encodeArrayBuffer(bsf));
    return ba.putFileChunks(fileId, BigInt(chunk), BigInt(fileSize), encodeArrayBuffer(bsf));
  }


  const handleUpload = async (event) => {
    event.preventDefault();
    const fileExtension = getFileExtension(file.type);
    console.log(fileExtension);
    const errors = [];
    if (file === null || file === undefined || fileExtension === null) {
      errors.push("File not valid!");
    }
    if (file.size > 10550000) {
      errors.push("File size shouldn't be bigger than 10mb");
    }

    if (errors.length > 0) {
      setErrros(errors);
      return;
    }
    
    const t0 = performance.now();
    console.log('upload started...');
    setUploading(true);
    const fileInfo  = { // ContentInfo type
      name: Math.random().toString(36).substring(2),
      createdAt: BigInt(Number(Date.now() * 1000)),
      size: BigInt(file.size),
      chunkCount: BigInt(Number(Math.ceil(file.size / MAX_CHUNK_SIZE))),
      // @ts-ignore
      extension: fileExtension,
    };
    const ba = await BackendActor.getBackendActor();
    setValue(10);
    // const authenticated = await authClient.isAuthenticated();
    // console.log(authenticated);
    const fileId = (await ba.putFileInfo(fileInfo))[0];
    // console.log(fileId);
    setValue(40);
    const blob = file.blob;
    const putChunkPromises = [];
    let chunk = 1;
    for (let byteStart = 0; byteStart < blob.size; byteStart += MAX_CHUNK_SIZE, chunk++ ) {
      putChunkPromises.push(
        processAndUploadChunk(blob, byteStart, fileId, chunk, file.size)
      );
    }

    await Promise.all(putChunkPromises);
    await ba.updateStatus();
    setValue(100);
    setUploading(false);
    setReady(false);
    updateDeps();
    setFileData('Drag and drop a file or select add File');
    const t1 = performance.now();
    console.log("Upload took " + (t1 - t0) / 1000 + " seconds.")
    
  }





export const encodeArrayBuffer = (file) => Array.from(new Uint8Array(file));