# Proof of Concept NS
Proof of Concept implementation (Non Segwit) demonstrating CoinVault Smart Vault Setup and Recovery/Termination

**This software is for demonstration purposes only. All rights reserved.**

# Setup

**Install Prerequisites:**

This release has been tested against Bitcoin Core v0.18.1
https://bitcoincore.org/en/releases/0.18.1/

Download the appropriate archive for your platform, compile and install **bitcoind** and **bitcoin-cli** (Add install location to PATH if necessary)

Clone **libbitcoin-explorer** repo, build and install as per instructions in their GitHub repo. (Add install location to PATH if necessary)
https://github.com/libbitcoin/libbitcoin-explorer

*Needed for signing P2SH transactions with Smart Contracts*

Install **jq** - https://stedolan.github.io/jq/download/

*Needed for interacting with JSON objects inside shell*

Note: Please make sure that all the above tools are available in your PATH

You can now run the **Shell Scripts** in this repo to simulate CoinVault setup and recovery. 

These scripts simulate a Depositor with two private keys (1 Hardware Wallet + 1 Hardware Token\*) and a Vault/Depository Provider with two private keys (1 Hardware Wallet + 1 Hardware Token\*) collaborating to secure the Depositor's Bitcoin using CoinVault protocol and the folloring 4 scripts demonstrate recovery in 4 most common scenarios using 4 of the 9 Options available for recovery in this flavor of CoinVault protocol. Many other flavors/configs are possible.

*\*Hardware Tokens are just like Hardware Wallets without any seed or recovery phrase.*

   - Vault_OPTION_1.sh - Demonstrates recovery when the Vault Provider has disappeared or has gone rogue and is not responding to withdrawl requests from the Deposotor. *Needed Factors: Depositor Private Key & Depositor Hardware Token*

  - Vault_OPTION_6.sh - (One Key Recovery) Demonstrates recovery when the Vault Provider has disappeared and the Depositor has lost his Hardware Token. *Needed Factors: Depositor Private Key* 

  - Vault_OPTION_8.sh - Demonstrates recovery when the Depositor has lost his Hardware Token or it is malfunctioning. (My Ledger Nano S malfunctioned last week) *Needed Factors: Depositor Private Key, Vault Private Key & Vault Hardware Token*

  - Vault_OPTION_3.sh - Demonstrates recovery when both Private Key & Hardware Token are lost by the Depositor. Ex. Disaster Recovery, Accidental Death, etc. *Needed Factors:  Vault Private Key & Vault Hardware Token*

More pathways can be simulated by tweaking these shell scripts.

PS: The code and docs in this repo use Vault and Depository interchangeably to refer to the co-signing entity participating in the protocl to protect the Depositor's Bitcoin.

# Reference:

1) CoinVault - Secure Cryptocurrency Depository.pdf (In this repo)
2) CoinVault - Secure Depository - Brief Technology Overview (Youtube) - https://bit.ly/3m3iu1D

# Contact: 
Praveen Baratam - praveen@coinvault.tech




