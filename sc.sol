// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    struct Product {
        uint256 id;
        string name;
        address owner;
        address[] history; // Mehsul transfer tarixcesi
    }

    struct User {
        string name;
        address userAddress;
        bool isAdmin;
    }

    address public admin;
    address public currentUser; // Hal-hazirda istifade olunan hesab
    uint256 public productCounter = 0;
    mapping(uint256 => Product) public generalWarehouse;
    mapping(address => Product[]) public userWarehouses;

    User[] public users;

    // Istifadecileri baslat
    constructor() {
        admin = 0xB874C7ce83632ce17Dc746C3eebF0732bF2038f5; // Admin unvani
        users.push(User("Ramin", admin, true)); // Admin istifadeci

        // Normal istifadeciler
        users.push(User("User2", 0xFB2116f8C04DdDE83a66b6c09421dD0722B0c313, false));
        users.push(User("User3", 0x940Ba084d29a9c3178d8239b6E8736A37BF90972, false));
        users.push(User("User4", 0x1e914BEF7e275402e5Ea3A28bd3301e0895CFBDB, false));
        users.push(User("User5", 0xb60451148B72E50a26fa399e61aA0a61Fb5E15ed, false));
        users.push(User("User6", 0xFd5E5eb4866c8e0A35D1C252d84056cF24A44b0C, false));
        users.push(User("User7", 0x4adc466e11C07F8AbB6C09c825F528DDf1125c44, false));
        users.push(User("User8", 0xF3b2ac76e7E25DB7756F79A9aec89A0a2bf8Aa1F, false));
        users.push(User("User9", 0xBcEa4dd68905779F08f0799ca6e1309107A19f81, false));
        users.push(User("User10", 0x1bC075565A4023cBbBe9e71A905893503697C692, false));

        currentUser = admin; // Ilk olaraq admin hesabi
    }

    // Admin funksiyalarina mehdudiyyet qoyan modifikator
    modifier onlyAdmin() {
        require(msg.sender == admin, "Yalniz admin bu emeliyyati ede biler");
        _;
    }

    // Hesabi deyisme ve secme funksiyasi
    function chooseAccount(uint256 _index) public {
        require(_index < users.length, "Bu index movcud deyil");
        currentUser = users[_index].userAddress; // Istifadeci hesabini secir
        emit AccountChoice(_index, users[_index].name); // Event gonder
    }

    // Yeni mehsul elave et (Yalniz admin)
    function addProductToGeneralWarehouse(string memory _name) public onlyAdmin {
        productCounter++;
        Product storage newProduct = generalWarehouse[productCounter];
        newProduct.id = productCounter;
        newProduct.name = _name;
        newProduct.owner = admin;
        newProduct.history.push(admin); // Ilk sahibin tarixceye elave edilmesi
    }

    // Admin umumidepodan istifadeciye mehsul transfer ede biler
    function transferProductFromGeneral(uint256 _productId, address _to) public onlyAdmin {
        require(generalWarehouse[_productId].id != 0, "Mehsul umumidepoda movcud deyil");

        Product storage product = generalWarehouse[_productId];
        product.owner = _to;

        // Istifadecinin deposuna elave et
        userWarehouses[_to].push(product);
        product.history.push(_to); // Tarixceni yenileyin

        // Umumi depodan sil
        delete generalWarehouse[_productId];
    }

    // İstifadəçilər arası məhsul transferi
    function transferProduct(uint256 _productId, address _to) public {
        bool productFound = false;

        // Hal-hazırki istifadəçinin deposunu yoxlayırıq
        Product[] storage warehouse = userWarehouses[msg.sender];

        for (uint256 i = 0; i < warehouse.length; i++) {
            if (warehouse[i].id == _productId) {
                // Məhsul tapıldı, sahibini yeniləyirik
                Product storage product = warehouse[i];
                product.owner = _to;
                product.history.push(_to);

                // Məhsulu yeni istifadəçinin deposuna əlavə edirik
                userWarehouses[_to].push(product);

                // Köhnə sahibdən məhsulu silirik
                removeProductFromUser(msg.sender, _productId);

                // Məhsulun transfer edildiyini hadisə kimi qeyd edirik
                emit ProductTransferred(_productId, _to);

                productFound = true;
                break;
            }
        }

        require(productFound, "Mehsul istifadeci deposunda tapilmadi");
    }

    // İstifadəçinin deposundan məhsulu silmək üçün köməkçi funksiya
    function removeProductFromUser(address _user, uint256 _productId) internal {
        Product[] storage warehouse = userWarehouses[_user];

        for (uint256 i = 0; i < warehouse.length; i++) {
            if (warehouse[i].id == _productId) {
                // Məhsulu silirik
                warehouse[i] = warehouse[warehouse.length - 1]; // Ən sonuncu məhsul ilə əvəz edirik
                warehouse.pop(); // Sonuncunu silirik
                break;
            }
        }
    }

    // Admin mehsulun adini yenileye biler
    function updateProductName(uint256 _productId, string memory _newName) public onlyAdmin {
        Product storage product = generalWarehouse[_productId];

        if (product.id == 0) {
            // Umumi depoda mehsul yoxdursa, istifadeci depolarinda axtar
            for (uint256 i = 0; i < users.length; i++) {
                Product[] storage warehouse = userWarehouses[users[i].userAddress];
                for (uint256 j = 0; j < warehouse.length; j++) {
                    if (warehouse[j].id == _productId) {
                        product = warehouse[j];
                        break;
                    }
                }
            }
        }

        require(product.id != 0, "Mehsul tapilmadi");
        product.name = _newName;
    }

    // Mehsul tarixcesini elde et (Umumi ve ya istifadeci deposuna esaslanaraq)
    function getProductHistory(uint256 _productId) public view returns (address[] memory) {
        Product memory product = generalWarehouse[_productId];

        if (product.id == 0) {
            for (uint256 i = 0; i < users.length; i++) {
                for (uint256 j = 0; j < userWarehouses[users[i].userAddress].length; j++) {
                    if (userWarehouses[users[i].userAddress][j].id == _productId) {
                        product = userWarehouses[users[i].userAddress][j];
                        break;
                    }
                }
            }
        }

        require(product.id != 0, "Mehsul tapilmadi");
        return product.history;
    }

    // Məhsul ID-sinə görə Detalları əldə et
    function getProductById(uint256 _productId) public view returns (Product memory) {
        Product memory product = generalWarehouse[_productId];

        if (product.id == 0) {
            for (uint256 i = 0; i < users.length; i++) {
                for (uint256 j = 0; j < userWarehouses[users[i].userAddress].length; j++) {
                    if (userWarehouses[users[i].userAddress][j].id == _productId) {
                        product = userWarehouses[users[i].userAddress][j];
                        break;
                    }
                }
            }
        }

        require(product.id != 0, "Mehsul tapilmadi");
        return product; // Product qaytarılır
    }

    // Hesab secimi ucun event (UI ucun)
    event AccountChoice(uint256 index, string name);

    // Məhsul transfer edildiyi zaman event
    event ProductTransferred(uint256 indexed productId, address indexed to);
}