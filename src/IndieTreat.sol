// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title IndieTreat (ERC20 + Permit checkout)
/// @notice Tracks purchases per store and forwards an ERC20 payment to the seller.
///         Supports classic approve-then-purchase and one-tx purchase via EIP-2612 permit.
contract IndieTreat {
    using SafeERC20 for IERC20;

    /// @notice ERC20 token used for payments (e.g., Optimona token)
    IERC20 public immutable paymentToken;

    /// @notice Same token cast as IERC20Permit (must support EIP-2612)
    IERC20Permit public immutable permitToken;

    /// @notice Purchase record
    struct Purchase {
        string productName;
        string username;
        uint256 userId;
        uint256 timestamp;
        uint256 amount; // smallest units
        address wallet; // seller/recipient
    }

    /// @notice Per-store state
    struct Store {
        mapping(uint256 => Purchase) purchases;
        uint256 purchaseCount;
    }

    mapping(uint256 => Store) public stores;

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

    /// @param _paymentToken The ERC20 token address used for payments
    constructor(IERC20 _paymentToken) {
        require(address(_paymentToken) != address(0), "token=0");
        paymentToken = _paymentToken;
        // This cast is safe if the token implements EIP-2612 (your OMN does).
        permitToken = IERC20Permit(address(_paymentToken));
    }

    /// @notice Classic path: requires prior allowance (approve) by the buyer.
    function purchase(
        uint256 storeId,
        string calldata productName,
        string calldata username,
        uint256 userId,
        uint256 amount,
        address wallet
    ) external {
        _purchase(storeId, productName, username, userId, amount, wallet);
    }

    /// @notice One-tx path: off-chain signed approval via EIP-2612 permit, then purchase.
    /// @dev Frontend obtains (v,r,s,deadline) by EIP-712 `signTypedData` on the token’s Permit.
    function purchaseWithPermit(
        uint256 storeId,
        string calldata productName,
        string calldata username,
        uint256 userId,
        uint256 amount,
        address wallet,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(wallet != address(0), "wallet=0");
        require(amount > 0, "amount=0");

        // 1) Approve this contract to spend `amount` via EIP-2612 (no gas by the user; signature only).
        //    Reverts if signature/domain/nonce/deadline invalid.
        permitToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // 2) (Paranoia) Ensure allowance is now sufficient before recording or transferring.
        //    This also supports cases where user had a larger pre-existing allowance.
        require(
            paymentToken.allowance(msg.sender, address(this)) >= amount,
            "permit/allowance"
        );

        // 3) Complete purchase flow (records + transfer + event)
        _purchase(storeId, productName, username, userId, amount, wallet);
    }

    /// @notice Internal shared logic for both paths
    function _purchase(
        uint256 storeId,
        string calldata productName,
        string calldata username,
        uint256 userId,
        uint256 amount,
        address wallet
    ) internal {
        require(wallet != address(0), "wallet=0");
        require(amount > 0, "amount=0");

        uint256 currentPurchaseId = stores[storeId].purchaseCount;

        stores[storeId].purchases[currentPurchaseId] = Purchase({
            productName: productName,
            username: username,
            userId: userId,
            timestamp: block.timestamp,
            amount: amount,
            wallet: wallet
        });

        stores[storeId].purchaseCount = currentPurchaseId + 1;

        // Pull tokens from buyer and forward to seller
        paymentToken.safeTransferFrom(msg.sender, wallet, amount);

        emit PurchaseMade(
            storeId,
            currentPurchaseId,
            productName,
            username,
            userId,
            block.timestamp,
            amount,
            wallet
        );
    }

    /// @notice Get purchase information for a specific store and purchase ID
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
        require(purchaseId < stores[storeId].purchaseCount, "no-purchase");
        Purchase storage p = stores[storeId].purchases[purchaseId];
        return (
            p.productName,
            p.username,
            p.userId,
            p.timestamp,
            p.amount,
            p.wallet
        );
    }

    /// @notice Get total purchases for a store
    function getStorePurchaseCount(
        uint256 storeId
    ) external view returns (uint256) {
        return stores[storeId].purchaseCount;
    }

    /// @notice Convenience: does a store exist (has ≥1 purchase)?
    function storeExists(uint256 storeId) external view returns (bool) {
        return stores[storeId].purchaseCount > 0;
    }

    /// @notice Reject native ETH (ERC20-only checkout)
    receive() external payable {
        revert("ETH not accepted");
    }
    fallback() external payable {
        revert("ETH not accepted");
    }
}
