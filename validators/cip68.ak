use aiken/transaction.{Input, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{Value}
use assist/count
use assist/find
use assist/payout
use assist/signing
use assist/types/cip68.{CIP68}
use assist/types/hashes.{PublicKeyHash}
use mint_contract/types.{CIP68Redeemer, RemoveMeta, UpdateMeta}

validator(
  // The hot key controls the metadatum
  hot_key: PublicKeyHash,
) {
  fn params(
    _datum: CIP68,
    redeemer: CIP68Redeemer,
    context: ScriptContext,
  ) -> Bool {
    // SPEND ONLY
    when context.purpose is {
      Spend(output_reference) -> {
        // the transaction being validated
        let tx: Transaction = context.transaction
        // this is the input being validated
        let this_input: Input = find.input_by_ref(tx.inputs, output_reference)
        // this script address
        let this_addr: Address = this_input.output.address
        when redeemer is {
          // removes the utxo entirely from the contract
          // this doesn't check for burn or destination for more of an open ended approach
          RemoveMeta -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key)?,
              // single script input
              count.inputs_by_addr(tx.inputs, this_addr, 1)?,
              // no script output
              count.outputs_by_addr(tx.outputs, this_addr, 0)?,
            }
          // updates the metadata and change min ada
          UpdateMeta { lovelace } -> {
            // set a direction to add or remove the minimum lovelace
            let that_value: Value =
              value.add(
                this_input.output.value,
                value.ada_policy_id,
                value.ada_asset_name,
                lovelace,
              )
            // This should prevent utxos without cip68 datum to go to the cip68 storage contract
            // This Forces An Inline Datum!
            expect _: CIP68 = find.output_datum_by_addr(tx.outputs, this_addr)
            //
            //
            and {
              // make sure value is continuing
              payout.exact(this_addr, that_value, tx.outputs)?,
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key)?,
              // single script input
              count.inputs_by_addr(tx.inputs, this_addr, 1)?,
              // single script output
              count.outputs_by_addr(tx.outputs, this_addr, 1)?,
            }
          }
        }
      }
      // Spend Only
      _ -> False
    }
  }
}
