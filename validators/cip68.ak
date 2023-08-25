use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/value.{Value}
use assist/count
use assist/find
use assist/payout
use assist/signing
use mint_contract/types.{CIP68Datum, CIP68Redeemer, RemoveMeta, UpdateMeta}

/// This adds or subtracts some amount of lovelace from a value. Adding is when
/// the direction is zero, anything else is subtraction.
///
fn add_or_subtract(self: Value, lovelace: Int, direction: Int) -> Value {
  let lovelace_value = value.from_lovelace(lovelace)
  // set a direction to add or remove the minimum lovelace
  when direction is {
    // addition
    0 -> value.merge(self, lovelace_value)
    // subtract
    _ -> value.merge(self, value.negate(lovelace_value))
  }
}

test zero_value() {
  let val = value.from_lovelace(100)
  add_or_subtract(val, 0, 1) == add_or_subtract(val, 0, 0)
}

test add_value() {
  let val = value.from_lovelace(100)
  let result = value.from_lovelace(200)
  add_or_subtract(val, 100, 0) == result
}

test sub_value() {
  let val = value.from_lovelace(100)
  let result = value.zero()
  add_or_subtract(val, 100, 1) == result
}

validator(hot_key: ByteArray) {
  fn params(
    _datum: CIP68Datum,
    redeemer: CIP68Redeemer,
    context: ScriptContext,
  ) -> Bool {
    // the transaction being validated
    let tx = context.transaction
    // SPEND ONLY
    when context.purpose is {
      Spend(output_reference) -> {
        // this is the input being validated
        let validating_input = find.input_by_ref(tx.inputs, output_reference)
        // this script address
        let script_addr = validating_input.output.address
        when redeemer is {
          // removes the utxo entirely from the contract
          RemoveMeta -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // single script input
              count.inputs_by_addr(tx.inputs, script_addr, 1),
              // no script output
              count.outputs_by_addr(tx.outputs, script_addr, 0),
            }
          // updates the metadata and change min ada
          UpdateMeta { lovelace, direction } -> {
            // set a direction to add or remove the minimum lovelace
            let cont_value =
              add_or_subtract(
                validating_input.output.value,
                lovelace,
                direction,
              )
            and {
              // make sure value is continuing
              payout.exact(script_addr, cont_value, tx.outputs),
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // single script input
              count.inputs_by_addr(tx.inputs, script_addr, 1),
              // single script output
              count.outputs_by_addr(tx.outputs, script_addr, 1),
            }
          }
        }
      }
      // Spend Only
      _ -> False
    }
  }
}
