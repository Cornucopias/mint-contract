////
////

use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential, Script}
use cardano/certificate.{
  Certificate, DelegateBlockProduction, DelegateCredential, RegisterCredential,
  UnregisterCredential,
}
use cardano/transaction.{Transaction}
use cardano/tx as signing
use redeemers.{
  DelegateStake, RegisterStake, StakingRedeemer, UnRegisterStake, Withdraw,
}
use validation/find

validator contract(
  // The hot key controls the staking
  hot_key: VerificationKeyHash,
) {
  withdraw(
    redeemer: StakingRedeemer,
    credential: Credential,
    transaction: Transaction,
  ) {
    let Transaction { withdrawals, extra_signatories, .. } = transaction
    let reward: Int = find.stake_reward_by_sc(withdrawals, credential)
    expect Withdraw = redeemer
    and {
      // no withdraw zero validations
      (reward > 0)?,
      // hot key must sign it
      signing.verify_signature(extra_signatories, hot_key)?,
    }
  }

  publish(
    redeemer: StakingRedeemer,
    certificate: Certificate,
    transaction: Transaction,
  ) {
    let Transaction { extra_signatories, .. } = transaction
    when redeemer is {
      DelegateStake(delegate_data) -> {
        let new_delegation: Certificate =
          DelegateCredential {
            credential: Script(delegate_data.stake_cred),
            delegate: DelegateBlockProduction {
              stake_pool: delegate_data.pool_id,
            },
          }
        and {
          signing.verify_signature(extra_signatories, hot_key)?,
          // The only cert is for new delegation
          (certificate == new_delegation)?,
        }
      }
      RegisterStake(delegate_data) -> {
        let new_delegation: Certificate =
          RegisterCredential {
            credential: Script(delegate_data.stake_cred),
            deposit: Never,
          }
        (certificate == new_delegation)?
      }
      UnRegisterStake(delegate_data) -> {
        let new_delegation: Certificate =
          UnregisterCredential {
            credential: Script(delegate_data.stake_cred),
            refund: Never,
          }
        and {
          signing.verify_signature(extra_signatories, hot_key)?,
          // The only cert is for new delegation
          (certificate == new_delegation)?,
        }
      }
      // anything else fails
      _ -> False
    }
  }

  else(_) {
    fail
  }
}
