use aiken/transaction.{Mint, ScriptContext}
use aiken/transaction/value
use assist/addresses
use assist/find
use assist/minting
use assist/payout
use assist/prefixes
use assist/signing
use assist/values
use mint_contract/types.{BurnTokens, CIP68Datum, MintRedeemer, MintTokens}

// This allows a hot key to mint 1 reference and 1 nft for a cip 68 token or
// the hot key may be either the reference or nft.
validator(
  // this key controls everything
  hot_key: ByteArray,
  cip68_hash_data: Data,
  stake_hash_data: Data,
  // this allows many policy ids
  _random_string: ByteArray,
) {
  fn params(redeemer: MintRedeemer, context: ScriptContext) -> Bool {
    // this transaction
    let tx = context.transaction
    // the minted value from the tx
    let mint =
      tx.mint
        |> value.from_minted_value()
        |> value.flatten()
    // mint only
    when context.purpose is {
      // mint 1 ref and 1 nft
      Mint(own_currency_symbol) ->
        when redeemer is {
          MintTokens -> {
            // cip68 address know at compile time
            expect cip68_hash: ByteArray = cip68_hash_data
            expect stake_hash: ByteArray = stake_hash_data
            // staking at this address
            let cip68_addr =
              addresses.create_script_address(cip68_hash, stake_hash)
            // get first input info from the tx in lexographical order
            let first_index = find.first_input_index(tx.inputs)
            let first_tx_hash = find.first_input_txid(tx.inputs)
            // use the reference prefix
            let ref_tkn =
              values.unique_token_name(
                first_tx_hash,
                first_index,
                prefixes.prefix_100,
              )
            // use the nft prefix
            let nft_tkn =
              values.unique_token_name(
                first_tx_hash,
                first_index,
                prefixes.prefix_222,
              )
            // this should prevent utxos without cip68 datum to go to the cip68 storage contract
            // This Forces An Inline Datum!
            expect _: CIP68Datum =
              find.output_datum_by_addr(tx.outputs, cip68_addr)
            // The hot key has to sign the tx to mint 1 ref and 1 nft. There
            // is destination validation for the cip68 token but not for the 
            // nft. This should allow a lot of flexability.
            and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // prevent roll over double nft attack
              first_index < 256,
              // must mint 1 reference token
              minting.exact(mint, own_currency_symbol, ref_tkn, 1),
              // the nft can go anywhere; ref must go to metadatum contract
              // must mint 1 non-fungible token
              minting.exact(mint, own_currency_symbol, nft_tkn, 1),
              // reference token must go to cip contract
              payout.at_least(
                cip68_addr,
                value.from_asset(own_currency_symbol, ref_tkn, 1),
                tx.outputs,
              ),
            }
          }
          // burn the ref or the nft or both at the same time
          BurnTokens -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // this allows optional burning of either or both
              or {
                // burn only 1 ref token
                minting.by_prefix(
                  mint,
                  own_currency_symbol,
                  prefixes.prefix_100,
                  -1,
                ),
                // burn only 1 nft
                minting.by_prefix(
                  mint,
                  own_currency_symbol,
                  prefixes.prefix_222,
                  -1,
                ),
              },
            }
        }
      // Mint Only
      _ -> False
    }
  }
}
