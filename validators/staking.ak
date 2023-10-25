use aiken/transaction.{Publish, ScriptContext, WithdrawFrom}
use aiken/transaction/certificate.{CredentialDelegation}
use aiken/transaction/credential.{Inline, ScriptCredential}
use assist/find
use assist/signing
use mint_contract/types.{Delegate, StakingRedeemer, Withdraw}

// The hot key controls the staking
validator(hot_key: ByteArray) {
  fn params(redeemer: StakingRedeemer, context: ScriptContext) -> Bool {
    let tx = context.transaction
    when context.purpose is {
      // handle all withdrawals
      WithdrawFrom(stake_credential) -> {
        // if no reward is found error
        let reward = find.stake_reward_by_sc(tx.withdrawals, stake_credential)
        when redeemer is {
          // can only withdraw
          Withdraw -> and {
              // no withdraw zero validations
              reward > 0,
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
            }
          _ -> False
        }
      }
      // handle all delegation certs
      Publish(certificate) ->
        when redeemer is {
          // only delegate to secific pool
          Delegate(delegate_data) -> {
            let new_delegation =
              CredentialDelegation {
                delegator: Inline(ScriptCredential(delegate_data.stake_cred)),
                delegatee: delegate_data.pool_id,
              }
            and {
              // The only cert is for new delegation
              certificate == new_delegation,
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
            }
          }
          // deregistration fails and anything else but changing delegation
          _ -> False
        }
      // anything else fails
      _ -> False
    }
  }
}
