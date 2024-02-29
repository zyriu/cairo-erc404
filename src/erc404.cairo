// SPDX-License-Identifier: Apache-2.0
// ERC404 Contract for Cairo v2.5.0 (erc404/erc404.cairo)

#[starknet::component]
mod ERC404Component {
    use alexandria_storage::list::{List, ListTrait};
    use erc404::interface;
    use integer::BoundedU256;
    use openzeppelin::account;
    use openzeppelin::introspection::dual_src5::{DualCaseSRC5, DualCaseSRC5Trait};
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::{
        erc721, erc721::dual721_receiver::{DualCaseERC721Receiver, DualCaseERC721ReceiverTrait}
    };
    use starknet::{ContractAddress, contract_address_const, get_caller_address};

    #[storage]
    struct Storage {
        ERC404_allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        ERC404_balances: LegacyMap<ContractAddress, u256>,
        ERC404_base_token_uri: Array<felt252>,
        ERC404_get_approved: LegacyMap<u256, ContractAddress>,
        ERC404_is_approved_for_all: LegacyMap<(ContractAddress, ContractAddress), bool>,
        ERC404_minted: u256,
        ERC404_name: felt252,
        ERC404_owned: LegacyMap<(ContractAddress, u32), u256>,
        ERC404_owned_index: LegacyMap<u256, u32>,
        ERC404_owned_length: LegacyMap<ContractAddress, u32>,
        ERC404_owner_of: LegacyMap<u256, ContractAddress>,
        ERC404_stored_erc721_ids: List<u256>,
        ERC404_symbol: felt252,
        ERC404_total_supply: u256,
        ERC404_units: u256,
        ERC404_whitelist: LegacyMap<ContractAddress, bool>,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ERC404_ApprovalForAll: ApprovalForAll,
        ERC404_Approval: Approval,
        ERC404_Transfer: Transfer,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    /// Emitted when `owner` enables or disables (`approved`) `operator` to manage
    /// all of its assets.
    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool,
    }

    /// Emitted when `owner` enables `approved` to manage `amountOrId` token(s).
    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        amount_or_id: u256,
    }

    /// Emitted when `amountOrId` token(s) is transferred from `from` to `to`.
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amount_or_id: u256,
    }

    mod Errors {
        const ALREADY_EXISTS: felt252 = 'Already exists';
        const INVALID_OPERATOR: felt252 = 'Invalid operator';
        const INVALID_RECIPIENT: felt252 = 'Invalid recipient';
        const INVALID_SENDER: felt252 = 'Invalid sender';
        const INVALID_TOKEN_ID: felt252 = 'Invalid token id';
        const NOT_FOUND: felt252 = 'Not found';
        const SAFE_TRANSFER_FAILED: felt252 = 'Safe transfer failed';
        const UNSAFE_RECIPIENT: felt252 = 'Unsafe recipient';
        const UNAUTHORIZED: felt252 = 'Unauthorized caller';
    }

    #[embeddable_as(ERC404Impl)]
    impl ERC404<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC404<ComponentState<TContractState>> {
        /// Returns the remaining number of tokens that `spender` is
        /// allowed to spend on behalf of `owner` through `transfer_from`.
        /// This is zero by default.
        /// This value changes when `approve` or `transfer_from` are called.
        fn allowance(
            self: @ComponentState<TContractState>, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.ERC404_allowances.read((owner, spender))
        }

        /// Change or reaffirm the approved address for an NFT.
        ///
        /// Requirements:
        ///
        /// - The caller is either an approved operator or the `token_id` owner.
        /// - `to` cannot be the token owner.
        /// - `token_id` exists.
        ///
        /// Emits an `Approval` event.
        fn approve(ref self: ComponentState<TContractState>, to: ContractAddress, amount_or_id: u256) {
            let caller = get_caller_address();
            if (amount_or_id <= self.ERC404_minted.read() && amount_or_id > 0) {
                let id = amount_or_id;
                let owner = self.ERC404_owner_of.read(id);
                assert(
                    caller == owner || self.ERC404_is_approved_for_all.read((owner, caller)),
                    Errors::UNAUTHORIZED
                );
                self.ERC404_get_approved.write(id, to);
                self.emit(Approval { owner, approved: to, amount_or_id: id });
            } else {
                let amount = amount_or_id;
                self.ERC404_allowances.write((caller, to), amount);
                self.emit(Approval { owner: caller, approved: to, amount_or_id: amount });
            }
        }

        /// Returns the number of tokens owned by `account`.
        fn balance_of(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::NOT_FOUND);
            self.ERC404_balances.read(account)
        }

        /// Returns the number of tokens owned by `account`.
        fn erc20_balance_of(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }

        /// Returns the value of tokens in existence.
        fn erc20_total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_total_supply.read()
        }

        /// Returns the number of NFTs banked in the queue.
        fn erc721_tokens_banked_in_queue(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_stored_erc721_ids.read().len().into()
        }

        /// Returns the number of NFTs owned by `account`.
        fn erc721_balance_of(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            self.ERC404_owned_length.read(account).into()
        }

        /// Returns the current amount of minted NFTs.
        fn erc721_total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_minted.read()
        }

        /// Returns the address approved for `token_id`.
        ///
        /// Requirements:
        ///
        /// - `token_id` exists.
        fn get_approved(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            assert(
                token_id > 0 && token_id <= self.ERC404_minted.read(),
                Errors::INVALID_TOKEN_ID
            );
            self.ERC404_get_approved.read(token_id)
        }

        /// Query if `operator` is an authorized operator for `owner`.
        fn is_approved_for_all(
            self: @ComponentState<TContractState>, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.ERC404_is_approved_for_all.read((owner, operator))
        }

        /// Returns the list of NFTs owned by `owner`.
        fn owned(self: @ComponentState<TContractState>, owner: ContractAddress) -> Array<u256> {
            let mut owned = ArrayTrait::<u256>::new();
            let mut k = 0;
            let length = self.ERC404_owned_length.read(owner).into();
            while k < length {
                owned.append(self.ERC404_owned.read((owner, k)));
                k += 1;
            };
            owned
        }

        /// Returns the owner address of `token_id`.
        ///
        /// Requirements:
        ///
        /// - `token_id` exists.
        fn owner_of(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            let owner = self.ERC404_owner_of.read(token_id);
            assert(
                token_id > 0 && token_id <= self.ERC404_minted.read(),
                Errors::INVALID_TOKEN_ID
            );
            owner
        }

        /// Transfers ownership of `amount_or_id` from `from` if `to` is either an account or `IERC721Receiver`.
        ///
        /// `data` is additional data, it has no specified format and it is sent in call to `to`.
        ///
        /// Requirements:
        ///
        /// - Caller is either approved or the `token_id` owner.
        /// - `to` is not the zero address.
        /// - `from` is not the zero address.
        /// - `to` is either an account contract or supports the `IERC721Receiver` interface.
        ///
        /// Emits a `Transfer` event.
        fn safe_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            amount_or_id: u256,
            data: Span<felt252>
        ) {
            self.transfer_from(from, to, amount_or_id);
            assert(
                InternalImpl::<TContractState>::_check_on_erc721_received(from, to, amount_or_id, data),
                Errors::SAFE_TRANSFER_FAILED
            );
        }

        /// Enable or disable approval for `operator` to manage all of the
        /// caller's assets.
        ///
        /// Requirements:
        ///
        /// - `operator` cannot be the caller.
        ///
        /// Emits an `ApprovalForAll` event.
        fn set_approval_for_all(ref self: ComponentState<TContractState>, operator: ContractAddress, approved: bool) {
            assert(operator.is_non_zero(), Errors::INVALID_OPERATOR);
            let caller = get_caller_address();
            self.ERC404_is_approved_for_all.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        /// Returns the value of tokens in existence.
        fn total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_total_supply.read()
        }

        /// Transfers ownership of `amount_or_id` from `from` to `to`.
        ///
        /// Requirements:
        ///
        /// - Caller is either approved or the `token_id` owner.
        /// - `to` is not the zero address.
        /// - `from` is not the zero address.
        /// - `token_id` exists.
        ///
        /// Emits a `Transfer` event.
        fn transfer_from(
            ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, amount_or_id: u256
        ) {
            self.transferFrom(from, to, amount_or_id);
        }

        /// Returns the whitelist status of `address`.
        fn whitelist(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            self.ERC404_whitelist.read(address)
        }
    }

    #[embeddable_as(ERC404MetadataImpl)]
    impl ERC404Metadata<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC404Metadata<ComponentState<TContractState>> {
        /// Returns the contract decimals.
        fn decimals(self: @ComponentState<TContractState>) -> u256 {
            18
        }

        /// Returns the contract name.
        fn name(self: @ComponentState<TContractState>) -> felt252 {
            self.ERC404_name.read()
        }

        /// Returns the contract symbol.
        fn symbol(self: @ComponentState<TContractState>) -> felt252 {
            self.ERC404_symbol.read()
        }

        /// Returns the contract units.
        fn units(self: @ComponentState<TContractState>) -> u256 {
            1_000_000_000_000_000_000
        }
    }

    /// Adds camelCase support for `IERC404`.
    #[embeddable_as(ERC404CamelOnlyImpl)]
    impl ERC404CamelOnly<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC404CamelOnly<ComponentState<TContractState>> {
        /// Returns the number of tokens owned by `account`.
        fn balanceOf(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::NOT_FOUND);
            self.ERC404_balances.read(account)
        }        

        /// Returns the number of tokens owned by `account`.
        fn erc20BalanceOf(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            self.balanceOf(account)
        }

        /// Returns the value of tokens in existence.
        fn erc20TotalSupply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_total_supply.read()
        }

        /// Returns the number of NFTs banked in the queue.
        fn erc721TokensBankedInQueue(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_stored_erc721_ids.read().len().into()
        }

        /// Returns the number of NFTs owned by `account`.
        fn erc721BalanceOf(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            self.ERC404_owned_length.read(account).into()
        }

        /// Returns the current amount of minted NFTs.
        fn erc721TotalSupply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_minted.read()
        }

        /// Returns the address approved for `token_id`.
        ///
        /// Requirements:
        ///
        /// - `token_id` exists.
        fn getApproved(self: @ComponentState<TContractState>, tokenId: u256) -> ContractAddress {
            self.ERC404_get_approved.read(tokenId)
        }

        /// Query if `operator` is an authorized operator for `owner`.
        fn isApprovedForAll(
            self: @ComponentState<TContractState>, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.ERC404_is_approved_for_all.read((owner, operator))
        }

        /// Returns the owner address of `token_id`.
        ///
        /// Requirements:
        ///
        /// - `token_id` exists.
        fn ownerOf(self: @ComponentState<TContractState>, tokenId: u256) -> ContractAddress {
            let owner = self.ERC404_owner_of.read(tokenId);
            assert(tokenId > 0 && tokenId <= self.ERC404_minted.read() && owner.is_non_zero(), Errors::NOT_FOUND);
            owner
        }

        /// Transfers ownership of `amount_or_id` from `from` if `to` is either an account or `IERC721Receiver`.
        ///
        /// `data` is additional data, it has no specified format and it is sent in call to `to`.
        ///
        /// Requirements:
        ///
        /// - Caller is either approved or the `token_id` owner.
        /// - `to` is not the zero address.
        /// - `from` is not the zero address.
        /// - `to` is either an account contract or supports the `IERC721Receiver` interface.
        ///
        /// Emits a `Transfer` event.
        fn safeTransferFrom(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            amountOrId: u256,
            data: Span<felt252>
        ) {
            self.transferFrom(from, to, amountOrId);
            assert(
                InternalImpl::<TContractState>::_check_on_erc721_received(from, to, amountOrId, data),
                Errors::SAFE_TRANSFER_FAILED
            );
        }

        /// Enable or disable approval for `operator` to manage all of the
        /// caller's assets.
        ///
        /// Requirements:
        ///
        /// - `operator` cannot be the caller.
        ///
        /// Emits an `ApprovalForAll` event.
        fn setApprovalForAll(ref self: ComponentState<TContractState>, operator: ContractAddress, approved: bool) {
            assert(operator.is_non_zero(), Errors::INVALID_OPERATOR);
            let caller = get_caller_address();
            self.ERC404_is_approved_for_all.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        /// Returns the value of tokens in existence.
        fn totalSupply(self: @ComponentState<TContractState>) -> u256 {
            self.ERC404_total_supply.read()
        }

        /// Transfers ownership of `amountOrId` from `from` to `to`.
        ///
        /// Requirements:
        ///
        /// - Caller is either approved or the `id` owner.
        /// - `to` is not the zero address.
        /// - `from` is not the zero address.
        /// - `amountOrId` exists.
        ///
        /// Emits a `Transfer` event.
        fn transferFrom(
            ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, amountOrId: u256
        ) {
            assert(from.is_non_zero(), Errors::INVALID_SENDER);
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);

            let caller = get_caller_address();
            if (amountOrId <= self.ERC404_minted.read()) {
                let id = amountOrId;
                assert(from == self.ERC404_owner_of.read(id), Errors::UNAUTHORIZED);
                assert(
                    caller == from
                        || self.ERC404_is_approved_for_all.read((from, caller))
                        || caller == self.ERC404_get_approved.read(id),
                    Errors::UNAUTHORIZED
                );

                InternalImpl::_transferERC20(ref self, from, to, self.units());
                InternalImpl::_transferERC721(ref self, from, to, id);
            } else {
                let amount = amountOrId;
                let allowed = self.ERC404_allowances.read((from, caller));
                if (allowed != BoundedU256::max()) {
                    self.ERC404_allowances.write((from, caller), allowed - amount);
                }

                InternalImpl::_transferERC20WithERC721(ref self, from, to, amount);
            }
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {
        /// Initializes the contract by setting the token name and symbol.
        /// This should only be used inside the contract's constructor.
        fn initializer(ref self: ComponentState<TContractState>, name: felt252, symbol: felt252) {
            self.ERC404_name.write(name);
            self.ERC404_symbol.write(symbol);

            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(erc721::interface::IERC721_ID);
            src5_component.register_interface(erc721::interface::IERC721_METADATA_ID);
        }

        /// Checks if `to` either is an account contract or has registered support
        /// for the `IERC721Receiver` interface through SRC5. The transaction will
        /// fail if both cases are false.
        fn _check_on_erc721_received(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) -> bool {
            if (DualCaseSRC5 { contract_address: to }
                .supports_interface(erc721::interface::IERC721_RECEIVER_ID)) {
                DualCaseERC721Receiver { contract_address: to }
                    .on_erc721_received(
                        get_caller_address(), from, token_id, data
                    ) == erc721::interface::IERC721_RECEIVER_ID
            } else {
                DualCaseSRC5 { contract_address: to }
                    .supports_interface(account::interface::ISRC6_ID)
            }
        }

        /// Retrieve NFT from the queue, mint if queue is empty.
        fn _retrieveOrMintERC721(ref self: ComponentState<TContractState>, to: ContractAddress) {
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);
            let mut id = 0;

            if (self.ERC404_stored_erc721_ids.read().is_empty()) {
                let minted = self.ERC404_minted.read() + 1;
                id = minted;
                self.ERC404_minted.write(minted);
            } else {
                let mut list = self.ERC404_stored_erc721_ids.read();
                id = list.pop_front().unwrap().unwrap();
            }

            let erc721Owner = self.ERC404_owner_of.read(id);
            assert(erc721Owner.is_zero(), Errors::ALREADY_EXISTS);
            InternalImpl::_transferERC721(ref self, erc721Owner, to, id);
        }

        /// Enable or disable whitelist for `target`.
        fn _set_whitelist(ref self: ComponentState<TContractState>, target: ContractAddress, state: bool) {
            self.ERC404_whitelist.write(target, state);
        }

        fn _transferERC20(
            ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, amount: u256
        ) {
            if (from.is_zero()) {
                self.ERC404_total_supply.write(self.ERC404_total_supply.read() + amount);
            } else {
                self.ERC404_balances.write(from, self.ERC404_balances.read(from) - amount);
            }

            self.ERC404_balances.write(to, self.ERC404_balances.read(to) + amount);
            self.emit(Transfer { from, to, amount_or_id: amount });
        }

        fn _transferERC721(
            ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, id: u256
        ) {
            if (from.is_non_zero()) {
                self.ERC404_get_approved.write(id, contract_address_const::<0>());
                let length = self.ERC404_owned_length.read(from) - 1;
                let updatedId = self.ERC404_owned.read((from, length));
                if (updatedId != id) {
                    let updatedIndex = self.ERC404_owned_index.read(id);
                    self.ERC404_owned.write((from, updatedIndex), updatedId);
                    self.ERC404_owned_index.write(updatedId, updatedIndex);
                }
                self.ERC404_owned_length.write(from, length);
            }

            if (to.is_non_zero()) {
                let length = self.ERC404_owned_length.read(to);
                self.ERC404_owned.write((to, length), id);
                self.ERC404_owned_index.write(id, length);
                self.ERC404_owned_length.write(to, length + 1);
                self.ERC404_owner_of.write(id, to);
            } else {
                self.ERC404_owner_of.write(id, contract_address_const::<0>());
            }

            self.emit(Transfer { from, to, amount_or_id: id });
        }

        fn _transferERC20WithERC721(
            ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, amount: u256
        ) {
            let erc20BalanceOfSenderBefore = self.erc20BalanceOf(from);
            let erc20BalanceOfReceiverBefore = self.erc20BalanceOf(to);
            InternalImpl::_transferERC20(ref self, from, to, amount);

            let units = self.units();

            let isFromWhitelisted = self.ERC404_whitelist.read(from);
            let isToWhitelisted = self.ERC404_whitelist.read(to);
            if (isFromWhitelisted && !isToWhitelisted) {
                let tokensToRetrieveOrMint = (self.ERC404_balances.read(to) / units)
                    - (erc20BalanceOfReceiverBefore / units);
                let mut k = 0;
                while k < tokensToRetrieveOrMint {
                    InternalImpl::<TContractState>::_retrieveOrMintERC721(ref self, to);
                    k += 1;
                }
            } else if (!isFromWhitelisted && isToWhitelisted) {
                let tokensToWithdrawAndStore = (erc20BalanceOfSenderBefore / units)
                    - (self.ERC404_balances.read(from) / units);
                let mut k = 0;
                while k < tokensToWithdrawAndStore {
                    InternalImpl::_withdrawAndStoreERC721(ref self, from);
                    k += 1;
                }
            } else if (!isFromWhitelisted && !isToWhitelisted) {
                let nftsToTransfer = amount / units;
                let mut k = 0;
                while k < nftsToTransfer {
                    let id = self.ERC404_owned.read((from, self.ERC404_owned_length.read(from) - 1));
                    InternalImpl::_transferERC721(ref self, from, to, id);
                    k += 1;
                };

                let fractionalAmount = amount % units;
                if ((erc20BalanceOfSenderBefore - fractionalAmount)
                    / units < erc20BalanceOfSenderBefore
                    / units) {
                    InternalImpl::_withdrawAndStoreERC721(ref self, from);
                }

                if ((erc20BalanceOfReceiverBefore + fractionalAmount)
                    / units > erc20BalanceOfReceiverBefore
                    / units) {
                    InternalImpl::<TContractState>::_retrieveOrMintERC721(ref self, to);
                }
            }
        }

        /// Store NFT into queue.
        fn _withdrawAndStoreERC721(ref self: ComponentState<TContractState>, from: ContractAddress) {
            assert(from.is_non_zero(), Errors::INVALID_SENDER);

            let id = self.ERC404_owned.read((from, self.ERC404_owned_length.read(from) - 1));
            InternalImpl::_transferERC721(ref self, from, contract_address_const::<0>(), id);

            let mut list = self.ERC404_stored_erc721_ids.read();
            list.append(id).expect('syscallresult error');
        }
    }
}
