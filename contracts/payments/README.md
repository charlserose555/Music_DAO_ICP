# payments


## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
cd  smart-contracts/payments 
dfx start --background --clean
```


```bash
# In dfx.json remove remote object and change 
"candid": "ledger.public.did" -> "candid": "ledger.private.did"
# like so:
"ledger": {
      "type": "custom",
      "wasm": "ledger.wasm",
      "candid": "ledger.private.did"
    },
```

```bash
# In a new terminal make sure you are using default identity for deployment of canisters
dfx identity use default 

# Deploys ledger canister first by running

dfx deploy ledger --argument '(record {minting_account = "'${MINT_ACC}'"; initial_values = vec { record { "'${LEDGER_ACC}'"; record { e8s=100_000_000_000 } }; }; send_whitelist = vec {}})'

# Then in dfx.json change it back to public 
"candid": "ledger.private.did" -> "candid": "ledger.public.did"
# and add the remote object back 
"ledger": {
      "type": "custom",
      "wasm": "ledger.wasm",
      "candid": "ledger.public.did",
      "remote": {
        "candid": "ledger.public.did",
        "id": {
          "ic": "ryjl3-tyaaa-aaaaa-aaaba-cai"
        }
      }
    },

```

```bash
# Then, in the same terminal you deployed the ledger canister run:
dfx deploy payments_backend # to deploy just the smart contract and candid ui 
dfx deploy # to deploy the smart contract, frontend code and generate the declarations folder (abi)
```

```bash
# Worth noting: when using the default identity you need to add a fee of 10_000 to ledger transfer args, but if you are using a minter identity you do not. 
# then interacting with the smart contract can be donw through candid ui or the terminal 
# 1. To transfer 1mil ICPs to the payments canister to be able to run the dummy scenario
 dfx canister id payments_backend
 dfx canister call payments_backend get_account_identifier '(record {"principal" = principal "[MARKET_ID]"; token = record {symbol = "ICP"}})'
 dfx canister call payments_backend accountIdentifierToBlob '(variant {text = "[MARKET_ACCOUNT]"})'
 dfx identity use minter
 dfx canister call ledger transfer '( record { memo = 0; amount = record { e8s = 100_000_000_000_000 }; fee = record { e8s = 0 }; to = blob "[MARKET_BLOB]" } )'
 dfx canister call ledger account_balance '( record { account = blob "[MARKET_BLOB]" } )'

# 2. To transfer thousand ICPs to the user connected through plug

 dfx ledger account-id --of-principal "[USER_PRINCIPAL]"
 dfx canister call payments_backend accountIdentifierToBlob '(variant {text = "[USER_ACCOUNT_ID]"})'
 dfx identity use minter
 dfx canister call ledger transfer '( record { memo = 0; amount = record { e8s = 100_000_000_000 }; fee = record { e8s = 0 }; to = blob "[USER_BLOB]" } )'
 dfx canister call ledger account_balance '( record { account = blob "[USER_BLOB]" } )'
```