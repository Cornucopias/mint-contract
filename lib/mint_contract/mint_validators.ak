use aiken/bytearray
use aiken/list
use aiken/transaction/value.{AssetName, PolicyId}
use assist/prefixes

/// This checks if a specific policy id, token name, and amount exist inside
/// the flattened mint value. It is searching for an exact match. If found
/// then it returns True else False.
///
pub fn correct_mint(
  mint: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  tkn: AssetName,
  amt: Int,
) -> Bool {
  when mint is {
    [(policy, token_name, quantity), ..rest] ->
      if list.and([policy == pid, token_name == tkn, quantity == amt]) == True {
        True
      } else {
        correct_mint(rest, pid, tkn, amt)
      }
    // something wasn't found
    [] -> False
  }
}

test good_mint() {
  let mint = value.from_asset(#"acab", #"beef", 1) |> value.flatten()
  correct_mint(mint, #"acab", #"beef", 1) == True
}

test bad_mint() {
  let mint = value.from_asset(#"acab", #"beef", 1) |> value.flatten()
  correct_mint(mint, #"acab", #"face", 1) == False
}

test empty_mint() {
  let mint = value.zero() |> value.flatten
  correct_mint(mint, #"", #"", 0) == False
}

/// This checks if a specific policy id, prefix, and amount exist inside
/// the flattened mint value. Instead of searching for exact match, it
/// checks if the token name has the correct prefix. This works because
/// every token name will be unique.If found then it returns True else False.
///
pub fn correct_burn(
  mint: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  prefix: AssetName,
  amt: Int,
) -> Bool {
  when mint is {
    [(policy, token_name, quantity), ..rest] -> {
      // all cip68 prefixes have the same length
      let p = bytearray.take(token_name, 5)
      if list.and([policy == pid, prefix == p, quantity == amt]) == True {
        True
      } else {
        correct_burn(rest, pid, prefix, amt)
      }
    }
    // something wasn't found
    [] -> False
  }
}

test good_burn() {
  let mint =
    value.from_asset(#"acab", prefixes.prefix_222, -1) |> value.flatten()
  correct_burn(mint, #"acab", prefixes.prefix_222, -1) == True
}

test bad_burn() {
  let mint =
    value.from_asset(#"acab", prefixes.prefix_333, -1) |> value.flatten()
  correct_burn(mint, #"acab", prefixes.prefix_222, -1) == False
}

test empty_burn() {
  let mint = value.zero() |> value.flatten()
  correct_burn(mint, #"acab", prefixes.prefix_222, -1) == False
}
