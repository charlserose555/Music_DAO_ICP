import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

import IC "../ic.types";

module {

  public class WalletUtils() {

    private let ic : IC.Self = actor "aaaaa-aa";

    public func transferCycles(canisterId : Principal, amount : Nat) : async () {
      Cycles.add(amount);
      await ic.deposit_cycles({canister_id = canisterId});
    };

    public func transferFreezingThresholdCycles(canisterId : Principal) : async () {
      // TODO: determine effective threshold - get freezing_threshold_in_cycles via ic.canister_status()
      // use freezing_threshold_in_cycles - https://github.com/dfinity/interface-spec/pull/18/files

      // We have to retain some cycles to be able to ultimately delete the canister
      let balance : Nat = Cycles.balance();
      let cycles : Nat = balance - 100_000_000_000;

      if (cycles > 0) {
        Cycles.add(cycles);
        await ic.deposit_cycles({canister_id = canisterId});
      };
    };

    public func cyclesBalance() : Nat {
      return Cycles.balance();
    };

  };

};