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

echo "Deploy tipping"
dfx deploy tipping

echo "Create a testing user, and send tokens to him"
dfx identity new testing
dfx identity use testing
export TESTING_ACC=$(dfx ledger account-id)
export TESTING_PRINCIPAL=$(dfx identity get-principal)
export LEDGER_PRINCIPAL=$(dfx canister id ledger)
echo "TESTING_ACC '$TESTING_ACC'"
echo "TESTIG_PRINCIPAL '$TESTING_PRINCIPAL'"
echo "LEDGER_PRINCIPAL '$LEDGER_PRINCIPAL'"

dfx identity use default
dfx ledger transfer --ledger-canister-id ${LEDGER_PRINCIPAL} --amount 1 --memo 0 ${TESTING_ACC}
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${TESTING_ACC}

export TIPPING_PRINCIPAL=$(dfx canister id tipping)
export TIPPING_CANISTER_ACC=$(dfx ledger account-id --of-principal ${TIPPING_PRINCIPAL})
echo "TIPPING_PRINCIPAL '$TIPPING_PRINCIPAL'"
echo "TIPPING_CANISTER_ACC '$TIPPING_CANISTER_ACC'"

echo "Send tokens to tipping canister"
dfx ledger transfer --ledger-canister-id ${LEDGER_PRINCIPAL} --amount 1 --memo 0 ${TIPPING_CANISTER_ACC}

echo "Send tip to testing user"
dfx canister call tipping sendTip '(2: nat64, principal "'${TESTING_PRINCIPAL}'", 100_000: nat64, "ICP")'

echo "Confirm balance of default"
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${LEDGER_ACC}

echo "Confirm balance of tipping canister"
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${TIPPING_CANISTER_ACC}

echo "Confirm balance of testing user"
dfx ledger balance --ledger-canister-id ${LEDGER_PRINCIPAL} ${TESTING_ACC}

echo "Get all tipping transactions"
dfx canister call tipping getAllTippingTransactions

echo "Get tip data of artist"
dfx canister call tipping getTipDataArtist '(principal "'${TESTING_PRINCIPAL}'")'