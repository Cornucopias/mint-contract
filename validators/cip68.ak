use aiken/list
use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/value
use assist/count
use assist/find
use assist/payout
use assist/signing
use mint_contract/types.{CIP68Datum, CIP68Redeemer, RemoveMeta, UpdateMeta}

validator(hot_key: ByteArray) {
  fn params(
    _datum: CIP68Datum,
    redeemer: CIP68Redeemer,
    context: ScriptContext,
  ) -> Bool {
    // the transaction being validated
    let tx = context.transaction
    when context.purpose is {
      Spend(output_reference) -> {
        let validating_input = find.input_by_ref(tx.inputs, output_reference)
        let script_addr = validating_input.output.address
        when redeemer is {
          // removes the utxo entirely from the contract
          RemoveMeta ->
            list.and(
              [
                // no destination validation
                // cornucopias must sign it
                signing.verify_sig(tx, hot_key),
                // single script input
                count.inputs_by_addr(tx.inputs, script_addr, 1),
                // no script output
                count.outputs_by_addr(tx.outputs, script_addr, 0),
              ],
            )
          // updates the metadata and change min ada
          UpdateMeta { lovelace, direction } -> {
            let validating_value = validating_input.output.value
            let increase_value = value.from_lovelace(lovelace)
            // set a direction to add or remove the minimum lovelace
            let cont_value =
              when direction is {
                // addition
                0 -> value.add(validating_value, increase_value)
                // subtract
                _ -> value.add(validating_value, value.negate(increase_value))
              }
            list.and(
              [
                // cornucopias must sign it
                signing.verify_sig(tx, hot_key),
                // single script input
                count.inputs_by_addr(tx.inputs, script_addr, 1),
                // single script output
                count.outputs_by_addr(tx.outputs, script_addr, 1),
                // make sure value is continuing
                payout.exact(script_addr, cont_value, tx.outputs),
              ],
            )
          }
        }
      }
      // Spending Only
      _ -> False
    }
  }
}
