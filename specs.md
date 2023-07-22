## Quest Features

initialize_distribution( ):
* Assert state not yet initialized and given function inputs are correctly formed.
* Create resource account and add given BirthdayGifts and recipients into the DistributionStore.
* Register the resource account to use AptosCoin and move the DistributionStore to the admin who initialized the system.

add_birthday_gift( ):
* Assert DistributionStore is initialized
* For the recipient of the BirthdayGift:
  * If there are no existing gifts, add a new BirthdayGift in the table
  * If there is an existing entry in the table, update the original amount to the given amount.
* Sender transfers their AptosCoins equal to gift amount in the resource account.

remove_birthday_gift( ):
* Assert the DistributionStore is initialized and the recipient is listed in the table
* remove recipient's BirthdayGift from table.
* Transfer amount back to sender's account.

claim_birthday_gift( ):
* Assert the Store is initialized and the claimer has an entry in the store as a recipient.
* Check the time of claim is greater than the pre-scheduled timestamp.
* Remove the entry from the table.
* Transfer amount of BirthdayGift to the recipient.

