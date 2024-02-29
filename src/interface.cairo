// SPDX-License-Identifier: Apache-2.0
// ERC404 Contract for Cairo v2.5.0 (erc404/interface.cairo)

use starknet::ContractAddress;

#[starknet::interface]
trait IERC404<TState> {
    fn allowance(
        self: @TState, owner: ContractAddress, spender: ContractAddress
    ) -> u256;
    fn approve(ref self: TState, to: ContractAddress, amount_or_id: u256);
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn erc20_balance_of(self: @TState, account: ContractAddress) -> u256;
    fn erc20_total_supply(self: @TState) -> u256;
    fn erc721_tokens_banked_in_queue(self: @TState) -> u256;
    fn erc721_balance_of(self: @TState, account: ContractAddress) -> u256;
    fn erc721_total_supply(self: @TState) -> u256; 
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn owned(self: @TState, owner: ContractAddress) -> Array<u256>;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amount_or_id: u256,
        data: Span<felt252>
    );
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn total_supply(self: @TState) -> u256;
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, amount_or_id: u256);
    fn whitelist(self: @TState, address: ContractAddress) -> bool;
}

#[starknet::interface]
trait IERC404Metadata<TState> {
    fn decimals(self: @TState) -> u256;
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn units(self: @TState) -> u256;
}

#[starknet::interface]
trait IERC404CamelOnly<TState> {
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn erc20BalanceOf(self: @TState, account: ContractAddress) -> u256;
    fn erc20TotalSupply(self: @TState) -> u256;
    fn erc721TokensBankedInQueue(self: @TState) -> u256;
    fn erc721BalanceOf(self: @TState, account: ContractAddress) -> u256;
    fn erc721TotalSupply(self: @TState) -> u256; 
    fn ownerOf(self: @TState, tokenId: u256) -> ContractAddress;
    fn getApproved(self: @TState, tokenId: u256) -> ContractAddress;
    fn isApprovedForAll(self: @TState, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn safeTransferFrom(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        amountOrId: u256,
        data: Span<felt252>
    );
    fn setApprovalForAll(ref self: TState, operator: ContractAddress, approved: bool);
    fn totalSupply(self: @TState) -> u256;
    fn transferFrom(ref self: TState, from: ContractAddress, to: ContractAddress, amountOrId: u256);
}

#[starknet::interface]
trait ERC404ABI<TState> {
    // IERC404
    fn approve(ref self: TState, to: ContractAddress, amount_or_id: u256);
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amount_or_id: u256,
        data: Span<felt252>
    );
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, amount_or_id: u256);

    // IERC404Metadata
    fn decimals(self: @TState) -> u256;
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn units(self: @TState) -> u256;

    // IERC404CamelOnly
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn ownerOf(self: @TState, tokenId: u256) -> ContractAddress;
    fn getApproved(self: @TState, tokenId: u256) -> ContractAddress;
    fn isApprovedForAll(self: @TState, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn safeTransferFrom(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        amountOrId: u256,
        data: Span<felt252>
    );
    fn setApprovalForAll(ref self: TState, operator: ContractAddress, approved: bool);
    fn transferFrom(ref self: TState, from: ContractAddress, to: ContractAddress, amountOrId: u256);

    // ISRC5
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;

    // ISRC5Camel
    fn supportsInterface(self: @TState, interfaceId: felt252) -> bool;
}
