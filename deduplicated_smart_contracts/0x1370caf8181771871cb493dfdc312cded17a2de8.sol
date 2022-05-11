// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GSVEBeacon is Ownable{
    
    mapping(address => address) private _deployedAddress;
    mapping(address => address) private _addressGasToken;
    mapping(address => uint256) private _supportedGasTokens;
    
    constructor (address _wchi, address _wgst2, address _wgst1) public {
        //chi, gst2 and gst1
        _supportedGasTokens[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = 30053;
        _supportedGasTokens[0x0000000000b3F879cb30FE243b4Dfee438691c04] = 30870;
        _supportedGasTokens[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = 20046;

        //wchi, wgst2 and wgst1
        _supportedGasTokens[_wchi] = 30053;
        _supportedGasTokens[_wgst2] = 30870;
        _supportedGasTokens[_wgst1] = 20046;
    }
    
    /**
    * @dev return the location of a users deployed wrapper
    */
    function getDeployedAddress(address creator) public view returns(address){
        return _deployedAddress[creator];
    }

    /**
    * @dev return the gas token used by a safe
    */
    function getAddressGastoken(address safe) public view returns(address){
        return _addressGasToken[safe];
    }

    /**
    * @dev return the savings a gas token gives
    */
    function getAddressGasTokenSaving(address gastoken) public view returns(uint256){
        return _supportedGasTokens[gastoken];
    }
    
    /**
    * @dev return the address and savings for a given safe proxy
    */
    function getGasTokenAndSaving(address safe) public view returns(address, uint256){
        return (getAddressGastoken(safe), getAddressGasTokenSaving(safe));
    }

    /**
    * @dev allows the creator of a safe to change the gas token used by the safe
    */
    function setAddressGasToken(address safe, address gasToken) public{
        require(_deployedAddress[msg.sender] == safe, "GSVE: Sender is not the safe creator");
        if (gasToken != address(0)){
            require(_supportedGasTokens[gasToken] > 0, "GSVE: Invalid Gas Token");
        }
        _addressGasToken[safe] = gasToken;
        emit UpdatedGasToken(safe, gasToken);
    }

    /**
    * @dev sets the initial gas token of a given safe proxy
    */
    function initSafe(address owner, address safe) public onlyOwner{
        require(_deployedAddress[owner] == address(0), "GSVE: address already init'd");
        _deployedAddress[owner] = safe;
        _addressGasToken[safe] = address(0);
        emit UpdatedGasToken(safe, address(0));
    }

    event UpdatedGasToken(address safe, address gasToken);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}