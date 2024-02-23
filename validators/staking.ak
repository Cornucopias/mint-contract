use aiken/transaction.{Publish, ScriptContext, Transaction, WithdrawFrom}
use aiken/transaction/certificate.{Certificate, CredentialDelegation}
use aiken/transaction/credential.{Inline, ScriptCredential}
use assist/find
use assist/signing
use mint_contract/types.{Delegate, StakingRedeemer, Withdraw}

validator(
  // The hot key controls the staking
  hot_key: ByteArray,
) {
  fn params(redeemer: StakingRedeemer, context: ScriptContext) -> Bool {
    let tx: Transaction = context.transaction
    when context.purpose is {
      // handle all withdrawals
      WithdrawFrom(stake_credential) -> {
        // if no reward is found error
        let reward: Int =
          find.stake_reward_by_sc(tx.withdrawals, stake_credential)
        when redeemer is {
          // can withdraw the reward to anywhere
          Withdraw -> and {
              // no withdraw zero validations
              reward > 0,
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key),
            }
          // anything else fails
          _ -> False
        }
      }
      // handle all delegation certs
      Publish(certificate) ->
        when redeemer is {
          // only delegate to secific pool
          Delegate(delegate_data) -> {
            let new_delegation: Certificate =
              CredentialDelegation {
                delegator: Inline(ScriptCredential(delegate_data.stake_cred)),
                delegatee: delegate_data.pool_id,
              }
            //
            //
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
