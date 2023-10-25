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
    // SPEND ONLY
    when context.purpose is {
      Spend(output_reference) -> {
        // the transaction being validated
        let tx = context.transaction
        // this is the input being validated
        let this_input = find.input_by_ref(tx.inputs, output_reference)
        // this script address
        let this_addr = this_input.output.address
        when redeemer is {
          // removes the utxo entirely from the contract
          // this doesn't check for burn or destination for more of an open ended approach
          RemoveMeta -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // single script input
              count.inputs_by_addr(tx.inputs, this_addr, 1),
              // no script output
              count.outputs_by_addr(tx.outputs, this_addr, 0),
            }
          // updates the metadata and change min ada
          UpdateMeta { lovelace } -> {
            // this validating value
            let this_value = this_input.output.value
            // set a direction to add or remove the minimum lovelace
            let cont_value =
              value.add(
                this_value,
                value.ada_policy_id,
                value.ada_asset_name,
                lovelace,
              )
            // This should prevent utxos without cip68 datum to go to the cip68 storage contract
            expect _: CIP68Datum =
              find.output_datum_by_addr(tx.outputs, this_addr)
            and {
              // make sure value is continuing
              payout.exact(this_addr, cont_value, tx.outputs),
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // single script input
              count.inputs_by_addr(tx.inputs, this_addr, 1),
              // single script output
              count.outputs_by_addr(tx.outputs, this_addr, 1),
            }
          }
        }
      }
      // Spend Only
      _ -> False
    }
  }
}
