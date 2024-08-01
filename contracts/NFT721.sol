// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

// Импорт библиотеки ERC721 из OpenZeppelin
import "./OpenZeppelinHelpers/ERC721URIStorage.sol";
import "./OpenZeppelinHelpers/Ownable.sol";

// Определение контракта, который наследует от ERC721Metadata и Ownable
contract MyNFT is ERC721URIStorage, Ownable {
	// Конструктор контракта, задает имя, символ и базовый URL для NFT
	constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {   }

	// Функция для множественного мирантия NFT с указанием tokenURI
	function mint(address to, uint256 tokenId, string calldata _tokenURI) public onlyOwner {
		_safeMint(to, tokenId);
		_setTokenURI(tokenId, _tokenURI);
	}

	function mintMany(address to, uint256[] calldata tokenIds, string[] calldata _tokenURIs) public onlyOwner {
		for (uint256 i=0; i<tokenIds.length; i++) {
			_safeMint(to, tokenIds[i]);
			_setTokenURI(tokenIds[i], _tokenURIs[i]);
		}
	}
}