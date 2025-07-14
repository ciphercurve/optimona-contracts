// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IndieTreat
/// @notice A smart contract for tracking purchases across different stores
/// @dev Each store has its own purchase dictionary and counter
contract IndieTreat {
    /// @notice Structure to store purchase information
    struct Purchase {
        string productName;
        string username;
        uint256 userId;
        uint256 timestamp;
        uint256 amount;
        address wallet;
    }

    /// @notice Structure to store store information including purchases and counter
    struct Store {
        mapping(uint256 => Purchase) purchases;
        uint256 purchaseCount;
    }

    /// @notice Mapping from store ID to store information
    mapping(uint256 => Store) public stores;

    /// @notice Event emitted when a new purchase is made
    event PurchaseMade(
        uint256 indexed storeId,
        uint256 indexed purchaseId,
        string productName,
        string username,
        uint256 userId,
        uint256 timestamp,
        uint256 amount,
        address wallet
    );

    /// @notice Purchase a product from a store
    /// @param storeId The unique identifier for the store
    /// @param productName The name of the product being purchased
    /// @param username The username of the purchaser
    /// @param userId The unique identifier of the user
    /// @param wallet The wallet address to receive the ETH payment
    function purchase(
        uint256 storeId,
        string memory productName,
        string memory username,
        uint256 userId,
        address payable wallet
    ) external payable {
        require(wallet != address(0), "Invalid wallet address");
        require(msg.value > 0, "Must send ETH with purchase");

        // Get the current purchase count for this store
        uint256 currentPurchaseId = stores[storeId].purchaseCount;

        // Create the purchase object
        Purchase memory newPurchase = Purchase({
            productName: productName,
            username: username,
            userId: userId,
            timestamp: block.timestamp,
            amount: msg.value,
            wallet: wallet
        });

        // Insert the purchase into the store's dictionary
        stores[storeId].purchases[currentPurchaseId] = newPurchase;

        // Increment the counter (from 0 to 1 for first purchase, then 1 to 2, etc.)
        stores[storeId].purchaseCount = currentPurchaseId + 1;

        // Forward the ETH to the specified wallet
        (bool success, ) = wallet.call{value: msg.value}("");
        require(success, "Failed to forward ETH to wallet");

        // Emit the purchase event
        emit PurchaseMade(
            storeId,
            currentPurchaseId,
            productName,
            username,
            userId,
            block.timestamp,
            msg.value,
            wallet
        );
    }

    /// @notice Get purchase information for a specific store and purchase ID
    /// @param storeId The store ID
    /// @param purchaseId The purchase ID within that store
    /// @return productName The name of the product
    /// @return username The username of the purchaser
    /// @return userId The user ID
    /// @return timestamp When the purchase was made
    /// @return amount The amount of ETH sent with the purchase
    /// @return wallet The wallet address that received the payment
    function getPurchase(
        uint256 storeId,
        uint256 purchaseId
    )
        external
        view
        returns (
            string memory productName,
            string memory username,
            uint256 userId,
            uint256 timestamp,
            uint256 amount,
            address wallet
        )
    {
        require(
            purchaseId < stores[storeId].purchaseCount,
            "Purchase does not exist"
        );

        Purchase memory purchaseData = stores[storeId].purchases[purchaseId];
        return (
            purchaseData.productName,
            purchaseData.username,
            purchaseData.userId,
            purchaseData.timestamp,
            purchaseData.amount,
            purchaseData.wallet
        );
    }

    /// @notice Get the total number of purchases for a specific store
    /// @param storeId The store ID
    /// @return The total number of purchases for the store
    function getStorePurchaseCount(
        uint256 storeId
    ) external view returns (uint256) {
        return stores[storeId].purchaseCount;
    }

    /// @notice Check if a store exists (has at least one purchase)
    /// @param storeId The store ID
    /// @return True if the store has at least one purchase, false otherwise
    function storeExists(uint256 storeId) external view returns (bool) {
        return stores[storeId].purchaseCount > 0;
    }

    /// @notice Fallback function to reject direct ETH transfers
    receive() external payable {
        revert("Direct ETH transfers not allowed. Use purchase function.");
    }

    /// @notice Fallback function to reject direct ETH transfers
    fallback() external payable {
        revert("Direct ETH transfers not allowed. Use purchase function.");
    }
}
