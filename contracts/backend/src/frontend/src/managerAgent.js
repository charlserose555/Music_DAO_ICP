// import { Actor, HttpAgent, ActorSubclass } from '@dfinity/agent';
// import { AuthClient } from "@dfinity/auth-client";
// import { _SERVICE } from "./declarations/backend/backend.did";
// import { createActor, canisterId } from "./declarations/backend";

// export const ManagerActor {
//   var authClient;
//   export async function setAuthClient(ac) {
//     authClient = ac;
//   }
//   export async function getBackendActor(): Promise<ActorSubclass<_SERVICE>> {
//     if (!authClient) {
//       authClient = await AuthClient.create();
//     }

//     const identity = authClient.getIdentity();
//     const backendActor = createActor(canisterId as string, {
//       agentOptions: {
//         identity, 
//       }
//     });
  
//     return backendActor;
//   }
// };