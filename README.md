# XPASSToken
`XPASSToken` is an ERC20-compliant smart contract with extended features such as ownership management, account locking, and transfer control.

## Features

### ERC20 Standard Functions
- `totalSupply`: Returns the total supply of tokens.
- `balanceOf`: Checks the token balance of a specific address.
- `transfer`: Transfers tokens from the sender to another address.
- `transferFrom`: Transfers tokens from one address to another based on allowance.
- `approve`: Approves a spender to spend a specific amount on behalf of the token owner.
- `allowance`: Returns the remaining number of tokens that a spender is allowed to spend on behalf of the owner.
- `increaseAllowance`: Increases the approved allowance for a specified spender.
- `decreaseAllowance`: Decreases the approved allowance for a specified spender.

### Additional Custom Functions

#### Burnable Token Functionality
- `burn`: Allows the owner to burn a specified amount of tokens from the total supply, reducing the total supply permanently.

#### Ownership and Access Control
- `transferOwnership`: Transfers contract ownership to a new address.
- `onlyOwner` modifier: Restricts certain functions to the contract owner.

#### Transfer Control
- `enableTransfer`: Enables token transfers.
- `disableTransfer`: Disables token transfers, blocking non-admin addresses from sending tokens.
- `onlyWhenTransferAllowed` modifier: Ensures that transfers are only processed when they are enabled or performed by the admin.

#### Account Locking
- `lockAccount`: Locks a specific account by setting an amount that cannot be transferred out.
- `unlockAccount`: Unlocks a previously locked account, removing transfer restrictions.
- `onlyAllowedAmount` modifier: Ensures that a sender's transfer amount does not exceed their balance minus any locked tokens.

#### Admin Management
- `changeAdminAddr`: Changes the admin address, which has special permissions on transfer restrictions.
- `onlyValidDestination` modifier: Validates that token transfers are only sent to valid addresses, excluding specific critical addresses.
