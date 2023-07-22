module overmind::birthday_bot {
    use aptos_std::table::Table;
    use std::signer;

    use aptos_framework::account;
    use std::vector;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_std::table;
    use aptos_framework::timestamp;

    //
    // Errors
    //
    const ERROR_DISTRIBUTION_STORE_EXIST: u64 = 0;
    const ERROR_DISTRIBUTION_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_LENGTHS_NOT_EQUAL: u64 = 2;
    const ERROR_BIRTHDAY_GIFT_DOES_NOT_EXIST: u64 = 3;
    const ERROR_BIRTHDAY_TIMESTAMP_SECONDS_HAS_NOT_PASSED: u64 = 4;

    //
    // Data structures
    //
    struct BirthdayGift has drop, store {
        amount: u64,
        birthday_timestamp_seconds: u64,
    }

    struct DistributionStore has key {
        birthday_gifts: Table<address, BirthdayGift>,
        signer_capability: account::SignerCapability,
    }

    //
    // Assert functions
    //
    public fun assert_distribution_store_exists(
        account_address: address,
    ) {
        // DONE: assert that `DistributionStore` exists
        assert!(exists<DistributionStore>(account_address), ERROR_DISTRIBUTION_STORE_DOES_NOT_EXIST)
    }

    public fun assert_distribution_store_does_not_exist(
        account_address: address,
    ) {
        // DONE: assert that `DistributionStore` does not exist
        assert!(!exists<DistributionStore>(account_address), ERROR_DISTRIBUTION_STORE_EXIST)
    }

    public fun assert_lengths_are_equal(
        addresses: vector<address>,
        amounts: vector<u64>,
        timestamps: vector<u64>
    ) {
        // DONE: assert that the lengths of `addresses`, `amounts`, and `timestamps` are all equal
        let amount_len = vector::length(&amounts);
        assert!(vector::length(&addresses) == amount_len &&
            amount_len == vector::length(&timestamps), ERROR_LENGTHS_NOT_EQUAL)
    }

    public fun assert_birthday_gift_exists(
        distribution_address: address,
        address: address,
    ) acquires DistributionStore {
        // DONE: assert that `birthday_gifts` exists
        let store = borrow_global<DistributionStore>(distribution_address);
        assert!(table::contains<address, BirthdayGift>(
            &store.birthday_gifts, address),
            ERROR_BIRTHDAY_GIFT_DOES_NOT_EXIST
        )
    }

    public fun assert_birthday_timestamp_seconds_has_passed(
        distribution_address: address,
        address: address,
    ) acquires DistributionStore {
        // DONE: assert that the current timestamp is greater than or equal to `birthday_timestamp_seconds`
        let store = borrow_global<DistributionStore>(distribution_address);
        let address_timestamp = table::borrow<address, BirthdayGift>(
            &store.birthday_gifts,
            address
        ).birthday_timestamp_seconds;
        assert!(timestamp::now_seconds() >= address_timestamp, ERROR_BIRTHDAY_TIMESTAMP_SECONDS_HAS_NOT_PASSED)
    }

    //
    // Entry functions
    //
    /**
    * Initializes birthday gift distribution contract
    * @param account - account signer executing the function
    * @param addresses - list of addresses that can claim their birthday gifts
    * @param amounts  - list of amounts for birthday gifts
    * @param birthday_timestamps - list of birthday timestamps in seconds (only claimable after this timestamp has passed)
    **/
    public entry fun initialize_distribution(
        account: &signer,
        addresses: vector<address>,
        amounts: vector<u64>,
        birthday_timestamps: vector<u64>
    ) {
        // DONE: check `DistributionStore` does not exist
        let account_address = signer::address_of(account);
        assert_distribution_store_does_not_exist(account_address);

        // DONE: check all lengths of `addresses`, `amounts`, and `birthday_timestamps` are equal
        assert_lengths_are_equal(addresses, amounts, birthday_timestamps);

        // DONE: create resource account
        let (resource_account, signer_capability) = account::create_resource_account(account, vector[]);

        // DONE: register Aptos coin to resource account
        coin::register<AptosCoin>(&resource_account);

        // DONE: loop through the lists and push items to birthday_gifts table
        let birthday_gifts = table::new<address, BirthdayGift>();
        let i = 0;
        let total_amount = 0u64;
        vector::for_each(addresses, |recipient_address| {
            let amount = *vector::borrow(&amounts, i);
            total_amount = total_amount + amount;
            let birthday_timestamp_seconds = *vector::borrow(&birthday_timestamps, i);
            table::add(&mut birthday_gifts, recipient_address, BirthdayGift {
                amount,
                birthday_timestamp_seconds
            });
            i = i + 1;
        });

        // DONE: transfer the sum of all items in `amounts` from initiator to resource account
        let resource_account_address = signer::address_of(&resource_account);
        coin::transfer<AptosCoin>(account, resource_account_address, total_amount);

        // DONE: move_to resource `DistributionStore` to account signer
        move_to(account, DistributionStore {
            birthday_gifts,
            signer_capability
        });
    }

    /**
    * Add birthday gift to `DistributionStore.birthday_gifts`
    * @param account - account signer executing the function
    * @param address - address that can claim the birthday gift
    * @param amount  - amount for the birthday gift
    * @param birthday_timestamp_seconds - birthday timestamp in seconds (only claimable after this timestamp has passed)
    **/
    public entry fun add_birthday_gift(
        account: &signer,
        address: address,
        amount: u64,
        birthday_timestamp_seconds: u64
    ) acquires DistributionStore {
        // DONE: check that the distribution store exists
        let account_address = signer::address_of(account);
        assert_distribution_store_exists(account_address);

        let store = borrow_global_mut<DistributionStore>(account_address);
        let resource_account_address = account::get_signer_capability_address(&store.signer_capability);
        // DONE: set new birthday gift to new `amount` and `birthday_timestamp_seconds` (birthday_gift already exists, sum `amounts` and override the `birthday_timestamp_seconds`
        table::upsert(&mut store.birthday_gifts, address, BirthdayGift {
            amount,
            birthday_timestamp_seconds
        });

        // DONE: transfer the `amount` from initiator to resource account
        coin::transfer<AptosCoin>(account, resource_account_address, amount);
    }

    /**
    * Remove birthday gift from `DistributionStore.birthday_gifts`
    * @param account - account signer executing the function
    * @param address - `birthday_gifts` address
    **/
    public entry fun remove_birthday_gift(
        account: &signer,
        address: address,
    ) acquires DistributionStore {
        // DONE: check that the distribution store exists
        let distribution_store_address = signer::address_of(account);
        assert_distribution_store_exists(distribution_store_address);

        // DONE: if `birthday_gifts` exists, remove `birthday_gift` from table and transfer `amount` from resource account to initiator
        assert_birthday_gift_exists(distribution_store_address, address);
        let store = borrow_global_mut<DistributionStore>(distribution_store_address);

        let resource_signer = account::create_signer_with_capability(&store.signer_capability);
        let gift = table::remove(&mut store.birthday_gifts, address);
        let recipient_address = distribution_store_address;
        coin::transfer<AptosCoin>(&resource_signer, recipient_address, gift.amount);
    }

    /**
    * Claim birthday gift from `DistributionStore.birthday_gifts`
    * @param account - account signer executing the function
    * @param distribution_address - distribution contract address
    **/
    public entry fun claim_birthday_gift(
        account: &signer,
        distribution_address: address,
    ) acquires DistributionStore {
        // DONE: check that the distribution store exists
        assert_distribution_store_exists(distribution_address);

        // DONE: check that the `birthday_gift` exists
        let recipient_address = signer::address_of(account);
        assert_birthday_gift_exists(distribution_address, recipient_address);

        // DONE: check that the `birthday_timestamp_seconds` has passed
        assert_birthday_timestamp_seconds_has_passed(distribution_address, recipient_address);

        // DONE: remove `birthday_gift` from table and transfer `amount` from resource account to initiator
        let store = borrow_global_mut<DistributionStore>(distribution_address);
        let resource_signer = account::create_signer_with_capability(&store.signer_capability);
        let gift = table::borrow_mut( &mut store.birthday_gifts, recipient_address);
        coin::transfer<AptosCoin>(&resource_signer, recipient_address, gift.amount);
        table::remove(&mut store.birthday_gifts, recipient_address);
    }

}
