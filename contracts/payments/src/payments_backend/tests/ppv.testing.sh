#!/bin/sh
SMART_CONTRACT_LOCATION="../../../"

echo "Jump to smart-contracts folder"
cd $SMART_CONTRACT_LOCATION

echo "Start/Restart dfx"
dfx stop
dfx start --background --clean

dfx identity new minter
dfx identity use minter
export MINT_ACC=$(dfx ledger account-id)

# Switch back to default identity
dfx identity use default
export LEDGER_ACC=$(dfx ledger account-id)

echo "Set MINT_ACC, and LEDGER_ACC"
echo "MINT_ACC '$MINT_ACC'"
echo "LEDGER_ACC '$LEDGER_ACC'"

echo "Build ledger"
rm ledger.did
cp ledger.private.did ledger.did
dfx deploy ledger --argument '(record {minting_account = "'${MINT_ACC}'"; initial_values = vec { record { "'${LEDGER_ACC}'"; record { e8s=100_000_000_000_000 } }; }; send_whitelist = vec {}})'
rm ledger.did
cp ledger.public.did ledger.did
#dfx generate ledger

echo "Deploy ppv"
dfx deploy ppv

echo "Create a testing user, and send tokens to him"
dfx identity new testing
dfx identity use testing
export TESTING_ACC=$(dfx ledger account-id)
export TESTING_PRINCIPAL=$(dfx identity get-principal)
export LEDGER_PRINCIPAL=$(dfx canister id ledger)
echo "TESTING_ACC '$TESTING_ACC'"
echo "TESTIG_PRINCIPAL '$TESTING_PRINCIPAL'"
echo "LEDGER_PRINCIPAL '$LEDGER_PRINCIPAL'"
export PPV_PRINCIPAL=$(dfx canister id ppv)
export PPV_CANISTER_ACC=$(dfx ledger account-id --of-principal ${PPV_PRINCIPAL})
echo "PPV_PRINCIPAL '${PPV_PRINCIPAL}'"
echo "PPV_CANISTER_ACC '${PPV_CANISTER_ACC}'"

dfx identity use default
dfx ledger transfer --ledger-canister-id ${LEDGER_PRINCIPAL} --amount 2 --memo 0 ${TESTING_ACC}
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${TESTING_ACC}

dfx ledger transfer --ledger-canister-id ${LEDGER_PRINCIPAL} --amount 1 --memo 0 ${PPV_CANISTER_ACC}
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${PPV_CANISTER_ACC}

echo "1. Add PPV Content"
echo "1.1. Successfully add PPV content"
dfx canister call ppv addPPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "1.2. Error in adding PPV content if caller is not a publisher"
dfx identity use default
dfx canister call ppv addPPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

dfx identity use testing
echo "1.3. Error in adding PPV content if price is not exceeding zero, and totalPercentage is not matched to 1"
dfx canister call ppv addPPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.9: float64; price = 0.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "1.4. Error in adding PPV content if content ID has already been taken"
dfx canister call ppv addPPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "2. Update PPV Content"
echo "2.1. Successfully update PPV content"
dfx canister call ppv updatePPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "2.2. Error in updating PPV content if content ID does not match any existing record"
dfx canister call ppv updatePPVContent '("error-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "2.3. Error in updating PPV content if caller is not a publisher"
dfx identity use default
dfx canister call ppv updatePPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 10000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

echo "3. Remove PPV Content"
echo "3.1. Error in removing content if content ID does not match any existing record"
dfx identity use testing
dfx canister call ppv removeContent '("testing-content")'

echo "3.2. Error in removing content if caller is not a publisher"
dfx identity use default
dfx canister call ppv removeContent '("first-content")'

echo "3.3. Successfully remove content"
dfx identity use testing
dfx canister call ppv removeContent '("first-content")'

echo "4. Purchase PPV Content"
echo "Add content for testing"
dfx canister call ppv addPPVContent '("first-content", record { publisher = principal "'${TESTING_PRINCIPAL}'"; publisherPercentage = 0.5: float64; price = 100000.0; participants = vec { record { participantID = principal "'${TESTING_PRINCIPAL}'"; participantPercentage = 0.5; }}; contentType = "The first ppv content"; })'

dfx identity use default
dfx canister call ppv purchaseContent '(2: nat64, "first-content", "PPV", 1_000_000: nat64)'