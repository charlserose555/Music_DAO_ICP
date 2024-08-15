#!/usr/bin/ic-repl -r http://localhost:54482
import ledger = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
import ppv = "be2us-64aaa-aaaaa-qaabq-cai";
identity testing "./testing.pem";
identity default "./default.pem";

call ledger.account_balance(record { account = account(default) });
let defaultBalance = _.e8s;
call ledger.account_balance(record { account = account(testing) });
let testingBalance = _.e8s;
call ledger.account_balance(record { account = account(ppv) });
let ppvBalance = _.e8s;

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

transfer(testing, 2000000, 0);
transfer(ppv, 1000000, 0);
let blockIndex = _.Ok;

let content = record {
  publisher = testing;
  publisherPercentage = 0.5;
  price = 10000.0;
  participants = vec {
    record {
      participantID = testing;
      participantPercentage = 0.5;
    }
  };
  contentType = "The first ppv content";
};
let updatedContent = record {
  publisher = testing;
  publisherPercentage = 0.3;
  price = 9000.0;
  participants = vec {
    record {
      participantID = testing;
      participantPercentage = 0.7;
    }
  };
  contentType = "Updated PPV content";
};

identity testing;
call ppv.addPPVContent("testing-content", content);
call ppv.getContent("testing-content");
assert _?.contentType == content.contentType;
assert _?.price == content.price;
assert _?.publisher == content.publisher;

call ppv.updatePPVContent("testing-content", updatedContent);
call ppv.getContent("testing-content");
assert _?.contentType == updatedContent.contentType;
assert _?.price == updatedContent.price;
assert _?.publisher == updatedContent.publisher;

call ppv.removeContent("testing-content");

call ppv.addPPVContent("testing-content", content);
identity default;
call ppv.purchaseContent(blockIndex, "testing-content", "PPV", 100000);