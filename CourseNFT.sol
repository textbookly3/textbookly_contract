// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CourseNFT is ERC721, ERC721URIStorage, Ownable {
    // 自定义计数器替代 Counters
    uint256 private _tokenIds;

    // 课程信息结构
    struct Course {
        uint256 courseId;
        address creator;
        string title;
        string description;
        uint256 creditCost;
        uint256 experienceReward;
        bool isActive;
        uint256 createdAt;
    }

    // 课程ID到课程信息的映射
    mapping(uint256 => Course) public courses;

    // 用户创建的课程
    mapping(address => uint256[]) public userCourses;

    // 事件
    event CourseCreated(uint256 indexed courseId, address indexed creator, string title, uint256 creditCost);

    constructor() ERC721("Textbookly Course", "TBC") Ownable(msg.sender) {}

    /**
     * @dev 创建课程NFT
     * @param title 课程标题
     * @param description 课程描述
     * @param creditCost 创建课程需要的credit数量
     * @param experienceReward 完成课程获得的经验值
     * @param tokenURI NFT元数据URI
     */
    function createCourse(
        string memory title,
        string memory description,
        uint256 creditCost,
        uint256 experienceReward,
        string memory tokenURI
    ) external returns (uint256) {
        // 这里需要与Credit合约交互，扣除用户的credit
        // ICredit creditContract = ICredit(creditContractAddress);
        // creditContract.burn(msg.sender, creditCost);

        _tokenIds++;
        uint256 newCourseId = _tokenIds;

        // 创建课程信息
        courses[newCourseId] = Course({
            courseId: newCourseId,
            creator: msg.sender,
            title: title,
            description: description,
            creditCost: creditCost,
            experienceReward: experienceReward,
            isActive: true,
            createdAt: block.timestamp
        });

        // 铸造NFT给创建者
        _safeMint(msg.sender, newCourseId);
        _setTokenURI(newCourseId, tokenURI);

        // 记录用户创建的课程
        userCourses[msg.sender].push(newCourseId);

        emit CourseCreated(newCourseId, msg.sender, title, creditCost);

        return newCourseId;
    }

    /**
     * @dev 获取用户创建的所有课程
     */
    function getUserCourses(address user) external view returns (uint256[] memory) {
        return userCourses[user];
    }

    /**
     * @dev 获取课程信息
     */
    function getCourse(uint256 courseId) external view returns (Course memory) {
        return courses[courseId];
    }

    /**
     * @dev 获取当前tokenId计数
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIds;
    }

    // 重写必要的函数
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}