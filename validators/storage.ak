use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Address}
use cardano/assets.{Value}
use cardano/transaction.{Input, OutputReference, Transaction}
use cardano/tx as signing
use redeemers.{StorageRedeemer, RemoveMeta, UpdateMeta}
use types/cip68.{CIP68}
use validation/count
use validation/find
use validation/payout

validator contract(
  // The hot key controls the metadatum
  hot_key: VerificationKeyHash,
) {
  spend(
    maybe_datum: Option<Data>,
    redeemer: StorageRedeemer,
    output_reference: OutputReference,
    transaction: Transaction,
  ) {
    let Transaction { inputs, outputs, extra_signatories, .. } = transaction
    when maybe_datum is {
      Some(this_datum) ->
        if this_datum is CIP68 {
          // this is the input being validated
          let this_input: Input = find.input_by_ref(inputs, output_reference)
          let this_addr: Address = this_input.output.address
          when redeemer is {
            // removes the utxo entirely from the contract
            // this doesn't check for burn or destination for more of an open ended approach
            RemoveMeta -> and {
                // cornucopias must sign it
                signing.verify_signature(extra_signatories, hot_key)?,
                // single script input
                count.inputs_by_addr(inputs, this_addr, 1)?,
                // no script output
                count.outputs_by_addr(outputs, this_addr, 0)?,
              }
            // updates the metadata and change min ada
            UpdateMeta { lovelace } -> {
              // set a direction to add or remove the minimum lovelace
              let that_value: Value =
                assets.add(
                  this_input.output.value,
                  assets.ada_policy_id,
                  assets.ada_asset_name,
                  lovelace,
                )
              // This should prevent utxos without cip68 datum to go to the cip68 storage contract
              // This Forces An Inline Datum!
              expect _: CIP68 = find.output_datum_by_addr(outputs, this_addr)
              //
              //
              and {
                // make sure value is continuing
                payout.exact(this_addr, that_value, outputs)?,
                // cornucopias must sign it
                signing.verify_signature(extra_signatories, hot_key)?,
                // single script input
                count.inputs_by_addr(inputs, this_addr, 1)?,
                // single script output
                count.outputs_by_addr(outputs, this_addr, 1)?,
              }
            }
          }
        } else {
          // bad datum so hot key owns it
          signing.verify_signature(extra_signatories, hot_key)?
        }
      _ -> signing.verify_signature(extra_signatories, hot_key)?
    }
  }

  else(_) {
    fail
  }
}
