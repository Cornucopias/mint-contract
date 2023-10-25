use aiken/transaction.{Mint, ScriptContext}
use aiken/transaction/credential
use aiken/transaction/value
use assist/find
use assist/minting
use assist/payout
use assist/prefixes
use assist/signing
use assist/values
use mint_contract/types.{BurnTokens, MintRedeemer, MintTokens}

validator(
  hot_key: ByteArray,
  cip68_hash_data: Data,
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
    // MINT ONLY
    when context.purpose is {
      // Mint 1 ref and 1 nft
      Mint(own_currency_symbol) ->
        when redeemer is {
          // The nft can go anywhere; ref must go to metadatum contract
          MintTokens -> {
            // cip68 address know at compile time
            expect cip68_hash: ByteArray = cip68_hash_data
            // no staking at this address
            let cip68_addr = credential.from_script(cip68_hash)
            // get first tx info
            let first_index = find.first_input_index(tx.inputs)
            let first_tx_hash = find.first_input_txid(tx.inputs)
            // use the ref prefix
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
            and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // prevent roll over double nft attack
              first_index < 256,
              // must mint 1 reference token
              minting.exact(mint, own_currency_symbol, ref_tkn, 1),
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
          // can burn the ref or the nft or both at the same time
          BurnTokens -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
              // the or allows the optionional burning
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
