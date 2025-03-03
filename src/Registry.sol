// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Registry Contract for Merchant Management
 * @author @dannweeeee
 * @notice This contract manages merchant records
 */
contract Registry {
    /// @notice Struct to store merchant information
    struct Merchant {
        string uen;
        string entity_name;
        string owner_name;
        address wallet_address;
    }

    // Mappings to store and retrieve merchant data
    mapping(string => Merchant) private merchantsByUEN;
    mapping(address => string[]) private uensByWalletAddress;

    // Array to store all UENs
    string[] private allUENs;

    address public admin;

    // Events for logging Merchant Add, Update and Delete
    event MerchantAdded(string uen, string entity_name, string owner_name, address wallet_address);
    event MerchantUpdated(string uen, string entity_name, string owner_name, address wallet_address);
    event MerchantDeleted(string uen);

    /**
     * @notice Modifier to restrict certain function access to admin only
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @notice Constructor to set the admin as the contract deployer
     */
    constructor() {
        admin = msg.sender;
    }

    /////////////////////////
    /////// FUNCTIONS ///////
    /////////////////////////

    /**
     * @notice Function to add a new merchant. Only Admin can add to the contract
     * @param _uen Unique Entity Number of the merchant
     * @param _entity_name Name of the merchant entity
     * @param _owner_name Name of the merchant owner
     * @param _wallet_address Wallet address of the merchant
     */
    function addMerchant(
        string memory _uen,
        string memory _entity_name,
        string memory _owner_name,
        address _wallet_address
    ) public onlyAdmin {
        require(bytes(merchantsByUEN[_uen].uen).length == 0, "Merchant with this UEN already exists");
        require(bytes(_uen).length > 0, "UEN cannot be empty");
        require(bytes(_entity_name).length > 0, "Entity name cannot be empty");

        Merchant memory newMerchant = Merchant(_uen, _entity_name, _owner_name, _wallet_address);
        merchantsByUEN[_uen] = newMerchant;
        uensByWalletAddress[_wallet_address].push(_uen);
        allUENs.push(_uen);

        emit MerchantAdded(_uen, _entity_name, _owner_name, _wallet_address);
    }

    /**
     * @notice Function for admin to add a new merchant with minimal information
     * @param _uen Unique Entity Number of the merchant
     * @param _entity_name Name of the merchant entity
     */
    function addMerchantInBulk(string memory _uen, string memory _entity_name) public onlyAdmin {
        require(bytes(merchantsByUEN[_uen].uen).length == 0, "Merchant with this UEN already exists");

        Merchant memory newMerchant = Merchant(_uen, _entity_name, "", address(0));
        merchantsByUEN[_uen] = newMerchant;
        allUENs.push(_uen);

        emit MerchantAdded(_uen, _entity_name, "", address(0));
    }

    /**
     * @notice Function to update an existing merchant's information
     * @param _uen Unique Entity Number of the merchant to update
     * @param _entity_name New entity name (optional)
     * @param _owner_name New owner name (optional)
     * @param _wallet_address New wallet address (optional)
     */
    function updateMerchant(
        string memory _uen,
        string memory _entity_name,
        string memory _owner_name,
        address _wallet_address
    ) public onlyAdmin {
        require(bytes(merchantsByUEN[_uen].uen).length > 0, "Merchant with this UEN does not exist");

        Merchant storage merchant = merchantsByUEN[_uen];

        if (bytes(_entity_name).length > 0) {
            merchant.entity_name = _entity_name;
        }

        if (bytes(_owner_name).length > 0) {
            merchant.owner_name = _owner_name;
        }

        if (_wallet_address != address(0) && _wallet_address != merchant.wallet_address) {
            // Remove UEN from old wallet address
            if (merchant.wallet_address != address(0)) {
                removeUENFromWalletAddress(merchant.wallet_address, _uen);
            }
            // Add UEN to new wallet address
            uensByWalletAddress[_wallet_address].push(_uen);
            merchant.wallet_address = _wallet_address;
        }
        emit MerchantUpdated(_uen, merchant.entity_name, merchant.owner_name, merchant.wallet_address);
    }

    /**
     * @notice Function for admin to delete a merchant
     * @param _uen Unique Entity Number of the merchant to delete
     */
    function deleteMerchant(string memory _uen) public onlyAdmin {
        require(bytes(merchantsByUEN[_uen].uen).length > 0, "Merchant with this UEN does not exist");

        address walletAddress = merchantsByUEN[_uen].wallet_address;

        // Remove from uensByWalletAddress mapping if wallet address exists
        if (walletAddress != address(0)) {
            removeUENFromWalletAddress(walletAddress, _uen);
        }

        // Remove from merchantsByUEN mapping
        delete merchantsByUEN[_uen];

        // Remove from allUENs array
        for (uint256 i = 0; i < allUENs.length; i++) {
            if (keccak256(bytes(allUENs[i])) == keccak256(bytes(_uen))) {
                allUENs[i] = allUENs[allUENs.length - 1];
                allUENs.pop();
                break;
            }
        }

        emit MerchantDeleted(_uen);
    }

    /////////////////////////
    //////// HELPERS ////////
    /////////////////////////

    function removeUENFromWalletAddress(address _wallet_address, string memory _uen) private {
        string[] storage uens = uensByWalletAddress[_wallet_address];
        for (uint256 i = 0; i < uens.length; i++) {
            if (keccak256(bytes(uens[i])) == keccak256(bytes(_uen))) {
                uens[i] = uens[uens.length - 1];
                uens.pop();
                break;
            }
        }
    }

    /////////////////////////
    //////// GETTERS ////////
    /////////////////////////

    /**
     * @notice Function to retrieve merchant information by UEN
     * @param _uen Unique Entity Number of the merchant
     * @return Merchant struct containing merchant information
     */
    function getMerchantByUEN(string memory _uen) public view returns (Merchant memory) {
        require(bytes(merchantsByUEN[_uen].uen).length > 0, "Merchant with this UEN does not exist");
        return merchantsByUEN[_uen];
    }

    /**
     * @notice Function to retrieve merchant information by wallet address
     * @param _wallet_address Wallet address of the merchant(s)
     * @return An array of Merchant structs containing merchant information
     */
    function getMerchantsByWalletAddress(address _wallet_address) public view returns (Merchant[] memory) {
        string[] memory uens = uensByWalletAddress[_wallet_address];
        require(uens.length > 0, "No merchants associated with this wallet address");

        Merchant[] memory merchants = new Merchant[](uens.length);
        for (uint256 i = 0; i < uens.length; i++) {
            merchants[i] = merchantsByUEN[uens[i]];
        }
        return merchants;
    }

    /**
     * @notice Function to retrieve all merchant records
     * @return An array of Merchant structs containing all merchant information
     */
    function getAllMerchants() public view returns (Merchant[] memory) {
        Merchant[] memory allMerchants = new Merchant[](allUENs.length);
        for (uint256 i = 0; i < allUENs.length; i++) {
            allMerchants[i] = merchantsByUEN[allUENs[i]];
        }
        return allMerchants;
    }
}
