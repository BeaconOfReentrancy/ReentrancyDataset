// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply. 1.
 *  - Ability for holders to burn (destroy) their tokens. DO IT PUSSY.
 *  - No access control mechanism (for minting/pausing) and hence no governance. FEMBOY SHIT.
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 * 
 * 
 * 
░██╗░░░░░░░██╗░█████╗░███╗░░██╗███╗░░██╗░█████╗░░█████╗░██████╗░███████╗░█████╗░███╗░░░███╗██████╗░██╗███████╗░░░███╗░░░███╗███████╗
░██║░░██╗░░██║██╔══██╗████╗░██║████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗░████║██╔══██╗██║██╔════╝░░░████╗░████║██╔════╝
░╚██╗████╗██╔╝███████║██╔██╗██║██╔██╗██║███████║██║░░╚═╝██████╔╝█████╗░░███████║██╔████╔██║██████╔╝██║█████╗░░░░░██╔████╔██║█████╗░░
░░████╔═████║░██╔══██║██║╚████║██║╚████║██╔══██║██║░░██╗██╔══██╗██╔══╝░░██╔══██║██║╚██╔╝██║██╔═══╝░██║██╔══╝░░░░░██║╚██╔╝██║██╔══╝░░
░░╚██╔╝░╚██╔╝░██║░░██║██║░╚███║██║░╚███║██║░░██║╚█████╔╝██║░░██║███████╗██║░░██║██║░╚═╝░██║██║░░░░░██║███████╗██╗██║░╚═╝░██║███████╗
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚══╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝
 *
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}