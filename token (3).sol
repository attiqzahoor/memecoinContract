// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Token.sol";

contract TokenMarketplace {
    address public owner;
    uint64 public baseTokenPriceWei = 1e13; // 10,000 gwei
    uint32 public priceAdjustmentFactorWei = 2e7;
    uint8 public feePercentage = 2;

    struct TokenInfo {
        string name;
        string symbol;
        address tokenAddress;
        address creator;
        uint128 currentBalance;
        uint64 currentPriceWei;
    }

    struct UserTokenInfo {
        uint128 amount;
        uint64 purchasePriceWei;
    }

    mapping(string => TokenInfo) private tokens;
    mapping(address => string[]) private tokensCreatedByUser;
    mapping(address => mapping(string => UserTokenInfo)) private userTokens;
    mapping(string => uint256) private tokenSaleProceeds;
    mapping(string => address[]) private tokenHolders;

    string[] private tokenList;

    event TokenCreated(string name, string symbol, address tokenAddress);
    event TokenBoughtFromContract(
        address indexed buyer,
        string tokenName,
        string amountEth,
        uint128 amountTokens
    );
    event TokenSoldToContract(
        address indexed seller,
        string tokenName,
        uint128 amountTokens,
        string amountEth
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier tokenExists(string memory _name) {
        require(tokens[_name].tokenAddress != address(0), "Token does not exist");
        _;
    }

    function createToken(string memory _name, string memory _symbol)
        public
        returns (address)
    {
        require(tokens[_name].tokenAddress == address(0), "Token exists");

        ERC20Token newToken = new ERC20Token(_name, _symbol);
        uint256 initialSupply = newToken.totalSupply();

        tokens[_name] = TokenInfo({
            name: _name,
            symbol: _symbol,
            tokenAddress: address(newToken),
            creator: msg.sender,
            currentBalance: uint128(initialSupply),
            currentPriceWei: baseTokenPriceWei
        });

        tokensCreatedByUser[msg.sender].push(_name);
        tokenList.push(_name);

        require(
            newToken.transfer(address(this), initialSupply),
            "Transfer failed"
        );

        emit TokenCreated(_name, _symbol, address(newToken));
        return address(newToken);
    }
    
    function calculateTokenPrice(string memory _name)
        public
        view
        tokenExists(_name)
        returns (uint64)
    {
        return tokens[_name].currentPriceWei;
    }

    function buyToken(string memory _name) public payable tokenExists(_name) {
        TokenInfo storage token = tokens[_name];
        uint64 tokenPriceWei = token.currentPriceWei;
        uint256 feeAmount = (msg.value * feePercentage) / 100;
        uint256 netAmount = msg.value - feeAmount;
        uint128 tokenAmount = uint128((netAmount * 1e18) / tokenPriceWei);

        require(
            tokenAmount > 0 && token.currentBalance >= tokenAmount,
            "Insufficient tokens or ETH"
        );

        UserTokenInfo storage userInfo = userTokens[msg.sender][_name];
        userInfo.amount += tokenAmount;
        userInfo.purchasePriceWei = tokenPriceWei;

        tokenSaleProceeds[_name] += netAmount;
        token.currentBalance -= tokenAmount;
        unchecked {
            token.currentPriceWei += priceAdjustmentFactorWei;
        }

        if (userInfo.amount == tokenAmount) {
            tokenHolders[_name].push(msg.sender);
        }

        ERC20Token(token.tokenAddress).transfer(msg.sender, tokenAmount);

        payable(owner).transfer(feeAmount);

        emit TokenBoughtFromContract(
            msg.sender,
            _name,
            formatEtherWithPrecision(msg.value),
            tokenAmount / 1e18
        );
    }

    function sellToken(string memory _name, uint128 _amount) public {
        TokenInfo storage token = tokens[_name];
        require(token.tokenAddress != address(0), "Token not exist");

        ERC20Token tokenContract = ERC20Token(token.tokenAddress);

        uint128 amountInBaseUnits = _amount * 1e18;
        UserTokenInfo storage userInfo = userTokens[msg.sender][_name];
        require(userInfo.amount >= amountInBaseUnits, "Not enough tokens");

        uint64 tokenPriceWei = token.currentPriceWei;
        uint256 weiAmount = (amountInBaseUnits * tokenPriceWei) / 1e18;
        uint256 feeAmount = (weiAmount * feePercentage) / 100;
        uint256 netAmount = weiAmount - feeAmount;
        require(tokenSaleProceeds[_name] >= netAmount, "Insufficient ETH");

        require(
            tokenContract.transfer(address(this), amountInBaseUnits),
            "Transfer failed"
        );

        userInfo.amount -= amountInBaseUnits;
        tokenSaleProceeds[_name] -= netAmount;
        token.currentBalance += amountInBaseUnits;
        unchecked {
            if (token.currentPriceWei > priceAdjustmentFactorWei)
                token.currentPriceWei -= priceAdjustmentFactorWei;
        }

        if (userInfo.amount == 0) {
            removeHolder(_name, msg.sender);
        }

        payable(msg.sender).transfer(netAmount);
        payable(owner).transfer(feeAmount);

        emit TokenSoldToContract(
            msg.sender,
            _name,
            _amount,
            formatEtherWithPrecision(weiAmount) 
        );
    }

    function checkUserTokenBalance(string memory _tokenName)
        public
        view
        tokenExists(_tokenName)
        returns (uint128)
    {
        return userTokens[msg.sender][_tokenName].amount / 1e18;
    }

    function listTokens() public view returns (string[] memory) {
        return tokenList;
    }

    function listAllTokens() public view returns (TokenInfo[] memory) {
        uint256 numTokens = tokenList.length;
        TokenInfo[] memory allTokens = new TokenInfo[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            string memory tokenName = tokenList[i];
            allTokens[i] = tokens[tokenName];
        }

        return allTokens;
    }

    function listTokensCreatedByUser()
        public
        view
        returns (TokenInfo[] memory)
    {
        string[] storage createdTokens = tokensCreatedByUser[msg.sender];
        TokenInfo[] memory tokenInfos = new TokenInfo[](createdTokens.length);

        for (uint256 i = 0; i < createdTokens.length; i++) {
            tokenInfos[i] = tokens[createdTokens[i]];
        }

        return tokenInfos;
    }

    function listTokenDetailsByName(string memory _name)
        public
        view
        tokenExists(_name)
        returns (TokenInfo memory)
    {
        return tokens[_name];
    }

    function listAllHolders(string memory _name)
        public
        view
        tokenExists(_name)
        returns (address[] memory, string[] memory)
    {
        uint256 numHolders = tokenHolders[_name].length;
        address[] memory holders = new address[](numHolders + 1);
        string[] memory percentages = new string[](numHolders + 1);

        uint256 contractBalance = tokens[_name].currentBalance;
        uint256 totalSupply = 1e27;

        for (uint256 i = 0; i < numHolders; i++) {
            address holder = tokenHolders[_name][i];
            uint128 holderBalance = userTokens[holder][_name].amount;
            percentages[i] = formatPercentage(
                (holderBalance * 100000000) / contractBalance
            );
            holders[i] = holder;
        }

        percentages[numHolders] = formatPercentage(
            (contractBalance * 100000000) / totalSupply
        );
        holders[numHolders] = address(this);

        return (holders, percentages);
    }

    function getRemainingTokensPercentage(string memory _name)
        public
        view
        tokenExists(_name)
        returns (string memory)
    {
        return
            formatPercentage((tokens[_name].currentBalance * 100000000) / 1e27);
    }

    function formatEtherWithPrecision(uint256 amount)
        private
        pure
        returns (string memory)
    {
        uint256 wholePart = amount / 1e18; // Whole Ether
        uint256 decimalPart = (amount % 1e18) / 1e12; // Decimal part (up to 6 decimal places)

        return
            string(
                abi.encodePacked(
                    uintToString(wholePart),
                    ".",
                    padLeft(uintToString(decimalPart), 6)
                )
            );
    }

    function formatPercentage(uint256 percentage)
        private
        pure
        returns (string memory)
    {
        uint256 wholePart = percentage / 1000000;
        uint256 decimalPart = percentage % 1000000;

        return
            string(
                abi.encodePacked(
                    uintToString(wholePart),
                    ".",
                    padLeft(uintToString(decimalPart), 6)
                )
            );
    }

    function padLeft(string memory _str, uint256 _length)
        private
        pure
        returns (string memory)
    {
        bytes memory strBytes = bytes(_str);
        if (strBytes.length >= _length) return _str;

        bytes memory paddedBytes = new bytes(_length);
        uint256 padding = _length - strBytes.length;

        for (uint256 i = 0; i < padding; i++) {
            paddedBytes[i] = bytes1("0");
        }

        for (uint256 i = 0; i < strBytes.length; i++) {
            paddedBytes[padding + i] = strBytes[i];
        }

        return string(paddedBytes);
    }

    function uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 digits;
        uint256 temp = value;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function removeHolder(string memory _name, address holder) private {
        address[] storage holders = tokenHolders[_name];
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == holder) {
                holders[i] = holders[holders.length - 1];
                holders.pop();
                break;
            }
        }
    }
}
