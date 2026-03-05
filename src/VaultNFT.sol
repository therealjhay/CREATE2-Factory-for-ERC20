// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base64} from "./utils/Base64.sol";
import {Strings} from "./utils/Strings.sol";
import {Vault} from "./Vault.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";

contract VaultNFT {
    // custom errors
    error NotFactory();
    error ZeroAddress();
    error InvalidToken();
    error ApproveToOwner();
    error NotAuthorized();
    error ApproveToCaller();
    error NotOwner();

    using Strings for uint256;

    string public name = "Vault Position";
    string public symbol = "VAULT-NFT";

    struct VaultInfo {
        address vault;
        address token;
        address creator;
    }

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => VaultInfo) public vaultInfo;
    uint256 public nextId = 1;

    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert NotFactory();
        _;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidToken();
        return owner;
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApproveToOwner();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
            revert NotAuthorized();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert InvalidToken();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert ApproveToCaller();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != from) revert NotOwner();
        if (to == address(0)) revert ZeroAddress();

        bool isApproved = (msg.sender == owner ||
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender));
        if (!isApproved) revert NotAuthorized();

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata
    ) external {
        transferFrom(from, to, tokenId);
    }

    function mintForVault(
        address to,
        address vault,
        address token
    ) external onlyFactory returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        tokenId = nextId;
        nextId += 1;

        _owners[tokenId] = to;
        _balances[to] += 1;

        vaultInfo[tokenId] = VaultInfo({
            vault: vault,
            token: token,
            creator: to
        });

        emit Transfer(address(0), to, tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        VaultInfo memory info = vaultInfo[tokenId];
        if (info.vault == address(0)) revert InvalidToken();

        Vault vault = Vault(info.vault);
        uint256 totalDeposits = vault.totalDeposits();

        IERC20Metadata meta = IERC20Metadata(info.token);
        string memory tokenName = meta.name();
        string memory tokenSymbol = meta.symbol();
        uint8 tokenDecimals = meta.decimals();

        string memory image = _buildSVG(
            tokenName,
            tokenSymbol,
            tokenDecimals,
            info.token,
            info.vault,
            info.creator,
            totalDeposits
        );

        string memory json = string(
            abi.encodePacked(
                '{"name":"Vault for ',
                tokenSymbol,
                '","description":"Vault for ',
                tokenName,
                ' deposits.","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(image)),
                '","attributes":[',
                '{"trait_type":"Token","value":"',
                tokenSymbol,
                '"},',
                '{"trait_type":"Total Deposits","value":"',
                totalDeposits.toString(),
                '"}',
                "]}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function _buildSVG(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address token,
        address vault,
        address creator,
        uint256 totalDeposits
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' width='500' height='500' style='background:#0b1020;'>",
                    "<style>.title{font: bold 20px sans-serif; fill: #ffffff;} .label{font: 14px sans-serif; fill: #aaaaaa;} .value{font: 14px monospace; fill: #ffffff;}</style>",
                    "<text x='20' y='40' class='title'>Vault NFT</text>",
                    "<text x='20' y='80' class='label'>Token:</text>",
                    "<text x='120' y='80' class='value'>",
                    tokenName,
                    " (",
                    tokenSymbol,
                    ")</text>",
                    "<text x='20' y='110' class='label'>Decimals:</text>",
                    "<text x='120' y='110' class='value'>",
                    uint256(tokenDecimals).toString(),
                    "</text>",
                    "<text x='20' y='140' class='label'>Token Address:</text>",
                    "<text x='20' y='160' class='value'>",
                    _toHexString(token),
                    "</text>",
                    "<text x='20' y='190' class='label'>Vault Address:</text>",
                    "<text x='20' y='210' class='value'>",
                    _toHexString(vault),
                    "</text>",
                    "<text x='20' y='240' class='label'>Creator:</text>",
                    "<text x='20' y='260' class='value'>",
                    _toHexString(creator),
                    "</text>",
                    "<text x='20' y='290' class='label'>Total Deposits:</text>",
                    "<text x='200' y='290' class='value'>",
                    totalDeposits.toString(),
                    "</text>",
                    "</svg>"
                )
            );
    }

    function _toHexString(
        address account
    ) internal pure returns (string memory) {
        return _toHexString(abi.encodePacked(account));
    }

    function _toHexString(
        bytes memory data
    ) internal pure returns (string memory) {
        bytes16 hexSymbols = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = hexSymbols[uint8(data[i] >> 4)];
            str[3 + i * 2] = hexSymbols[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}
