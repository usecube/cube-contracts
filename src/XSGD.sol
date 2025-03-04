// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title XSGD Token
 * @author @dannweeeee
 * @dev Implementation of the XSGD Token
 */
contract XSGD is ERC20, Ownable, Pausable {
    // Mapping to track if an address is blacklisted
    mapping(address => bool) private _blacklisted;

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event AddressBlacklisted(address indexed account);
    event AddressUnblacklisted(address indexed account);

    constructor(string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Pause token transfers
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mint new tokens
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(!_blacklisted[to], "Recipient is blacklisted");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burn tokens from the caller's balance
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public {
        require(!_blacklisted[msg.sender], "Sender is blacklisted");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Burn tokens from a specific address
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public onlyOwner {
        require(!_blacklisted[account], "Account is blacklisted");
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }

    /**
     * @dev Blacklist an address
     * @param account Address to blacklist
     */
    function blacklist(address account) public onlyOwner {
        require(account != address(0), "Cannot blacklist zero address");
        _blacklisted[account] = true;
        emit AddressBlacklisted(account);
    }

    /**
     * @dev Remove an address from blacklist
     * @param account Address to unblacklist
     */
    function unblacklist(address account) public onlyOwner {
        _blacklisted[account] = false;
        emit AddressUnblacklisted(account);
    }

    /**
     * @dev Check if an address is blacklisted
     * @param account Address to check
     * @return bool True if the address is blacklisted
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Override transfer function to include blacklist check
     */
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        require(!_blacklisted[msg.sender], "Sender is blacklisted");
        require(!_blacklisted[to], "Recipient is blacklisted");
        return super.transfer(to, amount);
    }

    /**
     * @dev Override transferFrom function to include blacklist check
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(!_blacklisted[from], "Sender is blacklisted");
        require(!_blacklisted[to], "Recipient is blacklisted");
        return super.transferFrom(from, to, amount);
    }
}
