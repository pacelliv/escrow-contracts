// Sources flattened with hardhat v2.17.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File @openzeppelin/contracts/utils/Address.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}


// File src/libraries/EscrowTypes.sol

// SPDX-License-Idenfitier: MIT
pragma solidity ^0.8.21;

library EscrowTypes {
    enum State {
        CREATED,
        CONFIRMED,
        DISPUTED,
        RESOLVED
    }
}


// File src/interfaces/IERC20Escrow.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;


interface IERC20Escrow {
    /// @notice Confirm the receipt from the grantee.
    /// @dev Can only be called by the grantor.
    function confirmReceipt() external;

    /// @notice Withdraw the locked tokens in the Escrow contract.
    /// @dev Can only be called by the grantor after expiration of the Escrow.
    function withdraw() external;

    /// @notice Starts a dispute in case of dissatisfaction from one of the transactional parties.
    /// @dev Can only be called by the grantor or grantee.
    /// @dev Can only be called if the Escrow has not expired.
    function startDispute() external;

    /// @notice Resolves a dispute.
    /// @param grantorRefund Amount of token that the grantor will be refunded. This value goes from 0 to 100.
    /// @dev Can only be called by the arbiter.
    /// @dev Can only be called if the Escrow is in a `DISPUTED` state.
    function resolveDispute(uint256 grantorRefund) external;

    function getDuration() external view returns (uint256);

    function getGrantor() external view returns (address);

    function getGrantee() external view returns (address);

    function getArbiter() external view returns (address);

    function getToken() external view returns (IERC20);

    function getArbiterFee() external view returns (uint256);

    function getPayment() external view returns (uint256);

    function getState() external view returns (EscrowTypes.State);

    function getMaxFee() external pure returns (uint256);
}


// File src/libraries/Errors.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

library Errors {
    // ================================ FACTORY ERRORS ================================ //

    error EscrowFactory__AddressesMismatch();
    error EscrowFactory__ValuesMismatch();
    error EscrowFactory__CallFailed();

    // ================================ ESCROW ERRORS ================================ //

    error Escrow__RepeatedParticipant();
    error Escrow__MustDeployWithTokenBalance();
    error Escrow__EscrowNotExpired(uint256 currentTimestamp, uint256 duration);
    error Escrow__EscrowExpired();
    error Escrow__CallFailed();
    error Escrow__ZeroDuration();
    error Escrow__AddressZero();
    error Escrow__ZeroAmount();
    error Escrow__InsufficientBalance(uint256 grantorTokenBalance, uint256 payment);
    error Escrow__IncorrectRefunds();
    error Escrow__Unauthorized();
    error Escrow__InWrongState(EscrowTypes.State expectedState, EscrowTypes.State currentState);
    error Escrow__FeeExceedMax(uint256 arbiterFee, uint256 maxFee);
}


// File src/libraries/Events.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

library Events {
    // ================================ FACTORY EVENTS ================================ //

    /// @notice Emitted after the creating of a new NativeEscrow.
    /// @param escrow Topic with the address of the new NativeEscrow.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of grantee.
    /// @param arbiter Non-indexed parameter with the address of the arbiter.
    /// @param arbiterFee Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param payment Non-indexed parameter with the payment locked in the escrow contract.
    /// @param duration Non-indexed parameter with the duration of the escrow.
    event NewNativeEscrow(
        address indexed escrow,
        address indexed grantor,
        address indexed grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment,
        uint256 duration
    );

    /// @notice Emitted after the creating of a new ERC20Escrow.
    /// @param escrow Topic with the address of the new ERC20Escrow.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of grantee.
    /// @param arbiter Non-indexed parameter with the address of the arbiter.
    /// @param token Non-indexed parameter with the address of the token used as payment.
    /// @param arbiterFee Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param payment Non-indexed parameter with the payment locked in the escrow contract.
    /// @param duration Non-indexed parameter with the duration of the escrow.
    event NewERC20Escrow(
        address indexed escrow,
        address indexed grantor,
        address indexed grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment,
        uint256 duration
    );

    // ================================ ESCROW EVENTS ================================ //

    /// @notice Emitted after the receipt is confirmed by the grantor.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of the grantee.
    /// @param payment Non-indexed parameter with the payment sent to the grantee.
    event ReceiptConfirmed(address indexed grantor, address indexed grantee, uint256 payment);

    /// @notice Emitted after a dispute was started.
    /// @param disputer Topic with the address of the instantiator of the dispute.
    event Dispute(address disputer);

    /// @notice Emitted after the grantor withdraws the payment from the Escrow contract.
    /// @param payment Non-indexed paramater with the amount of tokens withdrew.
    event Withdraw(uint256 payment);

    /// @notice Emitted after a dispute is resolved.
    /// @param arbiter Topic with the address of the arbiter.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of the grantee.
    /// @param arbiterAward Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param grantorRefund Non-ndexed parameter with the amount of tokens refunded to the grantor.
    /// @param granteeAward Non-indexed parameter with the amount of tokens awarded to the grantee.
    event Resolved(
        address indexed arbiter,
        address indexed grantor,
        address indexed grantee,
        uint256 arbiterAward,
        uint256 grantorRefund,
        uint256 granteeAward
    );
}


// File src/ERC20Escrow.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;






/// @title ERC20Escrow
/// @notice Escrow contract for transactions between grantor, grantee and arbiter.
/// @notice Payment is in the form of ERC20 tokens.
/// @dev Designed based on the audited Escrow contract from the CodeHawks Escrow Contract - Competition.
/// @dev Findings from the final report were implemented in this design.
/// References:
/// - Audited contract: https://github.com/Cyfrin/2023-07-escrow/blob/main/src/Escrow.sol
/// - Final report: https://www.codehawks.com/report/cljyfxlc40003jq082s0wemya
contract ERC20Escrow is IERC20Escrow {
    using SafeERC20 for IERC20;

    /// @dev Maximum fee to pay to the arbiter.
    uint256 private constant _MAX_FEE = 12;

    /// @dev Used for calculations.
    uint256 private constant PRECISION = 100;

    /// @dev Duration of the escrow in seconds.
    uint256 private immutable _duration;

    /// @dev Account that transfer ownership of the payment.
    address private immutable _grantor;

    /// @dev Recipient of the payment.
    address private immutable _grantee;

    /// @dev Account that resolves disputes.
    address private immutable _arbiter;

    /// @dev Address of the ERC20 token used as payment.
    IERC20 private immutable _token;

    /// @dev Percentage deducted from the payment to pay to the arbiter.
    uint256 private immutable _arbiterFee;

    /// @dev Amount of tokens to used as payment.
    uint256 private immutable _payment;

    /// @dev State of the escrow.
    EscrowTypes.State private _currentState;

    /// @dev Reverts if the expected state is not equal to the current state.
    modifier onlyState(EscrowTypes.State expectedState) {
        if (expectedState != _currentState) {
            revert Errors.Escrow__InWrongState(expectedState, _currentState);
        }
        _;
    }

    // ================================ CONSTRUCTOR ================================ //

    /// @dev Sets the values for the state variables: `duration`, `grantor`, `grantee`, `arbiter`,
    /// `token`, `arbiterFee` and `payment`.
    /// @dev The payment must be transferred to this contract prior to its deployment with CREATE2.
    constructor(
        uint256 duration,
        address grantor,
        address grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment
    ) {
        if (duration == 0) {
            revert Errors.Escrow__ZeroDuration();
        }
        if (arbiterFee == 0 || payment == 0) {
            revert Errors.Escrow__ZeroAmount();
        }
        if (grantee == address(0) || arbiter == address(0)) {
            revert Errors.Escrow__AddressZero();
        }
        if (arbiterFee > _MAX_FEE) {
            revert Errors.Escrow__FeeExceedMax(arbiterFee, _MAX_FEE);
        }
        if (grantor == arbiter || grantor == grantee || grantee == arbiter) {
            revert Errors.Escrow__RepeatedParticipant();
        }
        if (IERC20(token).balanceOf(address(this)) < payment) {
            revert Errors.Escrow__MustDeployWithTokenBalance();
        }
        _duration = block.timestamp + duration;
        _grantor = grantor;
        _grantee = grantee;
        _arbiter = arbiter;
        _token = IERC20(token);
        _arbiterFee = arbiterFee;
        _payment = payment;
    }

    /// @inheritdoc IERC20Escrow
    function withdraw() external onlyState(EscrowTypes.State.CREATED) {
        if (!_checkCaller(msg.sender, _grantor)) {
            revert Errors.Escrow__Unauthorized();
        }
        if (block.timestamp < _duration) {
            revert Errors.Escrow__EscrowNotExpired(block.timestamp, _duration);
        }
        _currentState = EscrowTypes.State.RESOLVED;
        emit Events.Withdraw(_payment);
        IERC20(_token).safeTransfer(_grantor, _payment);
    }

    // ================================ CORE ESCROW FUNCTIONS ================================ //

    /// @inheritdoc IERC20Escrow
    function confirmReceipt() external onlyState(EscrowTypes.State.CREATED) {
        _expired();
        if (!_checkCaller(msg.sender, _grantor)) {
            revert Errors.Escrow__Unauthorized();
        }
        _currentState = EscrowTypes.State.CONFIRMED;
        emit Events.ReceiptConfirmed(_grantor, _grantee, _payment);
        IERC20(_token).safeTransfer(_grantee, _payment);
    }

    /// @inheritdoc IERC20Escrow
    function startDispute() external onlyState(EscrowTypes.State.CREATED) {
        _expired();
        if (!_checkCaller(msg.sender, _grantor) && !_checkCaller(msg.sender, _grantee)) {
            revert Errors.Escrow__Unauthorized();
        }
        _currentState = EscrowTypes.State.DISPUTED;
        emit Events.Dispute(msg.sender);
    }

    /// @inheritdoc IERC20Escrow
    function resolveDispute(uint256 grantorRefund) external onlyState(EscrowTypes.State.DISPUTED) {
        if (!_checkCaller(msg.sender, _arbiter)) {
            revert Errors.Escrow__Unauthorized();
        }

        _currentState = EscrowTypes.State.RESOLVED;

        uint256 arbiterPayment = (_payment * _arbiterFee) / PRECISION;
        IERC20(_token).safeTransfer(_arbiter, arbiterPayment);
        uint256 remainderBalance = _payment - arbiterPayment;

        uint256 grantorAmount;
        if (grantorRefund > 0) {
            grantorAmount = (remainderBalance * grantorRefund) / PRECISION;
            IERC20(_token).safeTransfer(_grantor, grantorAmount);
        }

        if (remainderBalance > 0) {
            IERC20(_token).safeTransfer(_grantee, remainderBalance - grantorAmount);
        }

        emit Events.Resolved(
            _arbiter,
            _grantor,
            _grantee,
            arbiterPayment,
            grantorAmount,
            remainderBalance - grantorAmount
        );
    }

    // ================================ GETTER FUNCTIONS ================================ //

    function getDuration() external view returns (uint256) {
        return _duration;
    }

    function getGrantor() external view returns (address) {
        return _grantor;
    }

    function getGrantee() external view returns (address) {
        return _grantee;
    }

    function getArbiter() external view returns (address) {
        return _arbiter;
    }

    function getToken() external view returns (IERC20) {
        return _token;
    }

    function getArbiterFee() external view returns (uint256) {
        return _arbiterFee;
    }

    function getPayment() external view returns (uint256) {
        return _payment;
    }

    function getState() external view returns (EscrowTypes.State) {
        return _currentState;
    }

    function getBalance() external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getMaxFee() external pure returns (uint256) {
        return _MAX_FEE;
    }

    // ================================ INTERNAL FUNCTIONS ================================ //

    /// @dev Reverts if the current block timestamp is greater than the `_duration` of the Escrow.
    function _expired() internal view {
        if (block.timestamp > _duration) {
            revert Errors.Escrow__EscrowExpired();
        }
    }

    /// @dev Check if the `caller` is equal to `expectedCaller`.
    /// @return Return `true` is `caller` equal to `expectedCaller`, return `false` otherwise.
    function _checkCaller(address caller, address expectedCaller) internal pure returns (bool) {
        return caller == expectedCaller;
    }
}
