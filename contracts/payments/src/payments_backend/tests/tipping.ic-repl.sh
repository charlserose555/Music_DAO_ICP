#!/usr/bin/ic-repl -r http://localhost:54482
import ledger = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
import tipping = "be2us-64aaa-aaaaa-qaabq-cai";
identity testing "./testing.pem";
identity default "./default.pem";

call ledger.account_balance(record { account = account(default) });
let defaultBalance = _.e8s;
call ledger.account_balance(record { account = account(testing) });
let testingBalance = _.e8s;
call ledger.account_balance(record { account = account(tipping) });
let tippingBalance = _.e8s;

function transfer(to, amount, memo) {
  call ledger.transfer(
    record {
      to = account(to);
      fee = record { e8s = 10_000 };
      memo = memo;
      amount = record { e8s = amount };
    },
  );
};

transfer(tipping, 1000000, 0);
let blockIndex = _.Ok;

call tipping.getTipDataArtist(testing);
let tips = _.size();

call tipping.sendTip(blockIndex, testing, 100_000, "ICP");

call ledger.account_balance(record { account = account(default) });
assert stringify(_.e8s) == stringify(sub(defaultBalance, 1010000));

call ledger.account_balance(record { account = account(testing) });
assert stringify(_.e8s) == stringify(add(testingBalance, 71000));

call ledger.account_balance(record { account = account(tipping) });
assert stringify(_.e8s) == stringify(add(tippingBalance, 900000));

call tipping.getTipDataArtist(testing);
assert stringify(add(tips, 1)) == stringify(_.size());