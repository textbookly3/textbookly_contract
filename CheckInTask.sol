// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract CheckInTask is Ownable, EIP712 {
    using ECDSA for bytes32;
    
    // 打卡记录结构
    struct CheckInRecord {
        uint256 timestamp;
        uint256 experienceGained;
        string message;
    }
    
    // 用户打卡记录
    mapping(address => CheckInRecord[]) public userCheckIns;
    
    // 用户每日打卡状态 (日期 => 是否已打卡)
    mapping(address => mapping(uint256 => bool)) public dailyCheckInStatus;
    
    // 用户总经验值
    mapping(address => uint256) public userExperience;
    
    // 配置参数
    uint256 public dailyExperienceReward = 10; // 每日打卡奖励经验值
    uint256 public consecutiveBonus = 5; // 连续打卡额外奖励
    uint256 public maxConsecutiveDays = 7; // 最大连续天数
    
    // 事件
    event CheckInCompleted(address indexed user, uint256 timestamp, uint256 experienceGained, string message);
    event ExperienceRewarded(address indexed user, uint256 amount, string reason);
    
    // EIP712 域名
    bytes32 public constant CHECKIN_TYPEHASH = keccak256("CheckIn(address user,uint256 date,string message)");
    
    constructor() EIP712("Textbookly CheckIn", "1.0.0") Ownable(msg.sender) {}
    
    /**
     * @dev 每日打卡（需要签名验证）
     * @param date 打卡日期（YYYYMMDD格式）
     * @param message 打卡消息
     * @param signature 服务器签名
     */
    function checkIn(
        uint256 date,
        string memory message,
        bytes memory signature
    ) external {
        require(!dailyCheckInStatus[msg.sender][date], "Already checked in today");
        require(date <= getCurrentDate(), "Cannot check in for future date");
        
        // 验证签名
        bytes32 structHash = keccak256(abi.encode(CHECKIN_TYPEHASH, msg.sender, date, keccak256(bytes(message))));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        
        require(signer == owner(), "Invalid signature");
        
        // 计算奖励经验值
        uint256 experienceGained = calculateExperienceReward(msg.sender, date);
        
        // 记录打卡
        CheckInRecord memory record = CheckInRecord({
            timestamp: block.timestamp,
            experienceGained: experienceGained,
            message: message
        });
        
        userCheckIns[msg.sender].push(record);
        dailyCheckInStatus[msg.sender][date] = true;
        userExperience[msg.sender] += experienceGained;
        
        emit CheckInCompleted(msg.sender, block.timestamp, experienceGained, message);
        emit ExperienceRewarded(msg.sender, experienceGained, "Daily check-in");
    }
    
    /**
     * @dev 计算打卡奖励经验值
     */
    function calculateExperienceReward(address user, uint256 currentDate) internal view returns (uint256) {
        uint256 consecutiveDays = getConsecutiveDays(user, currentDate);
        uint256 bonus = 0;
        
        if (consecutiveDays > 1) {
            bonus = (consecutiveDays - 1) * consecutiveBonus;
            if (bonus > maxConsecutiveDays * consecutiveBonus) {
                bonus = maxConsecutiveDays * consecutiveBonus;
            }
        }
        
        return dailyExperienceReward + bonus;
    }
    
    /**
     * @dev 获取连续打卡天数
     */
    function getConsecutiveDays(address user, uint256 currentDate) internal view returns (uint256) {
        uint256 consecutiveDays = 0;
        uint256 checkDate = currentDate;
        
        while (dailyCheckInStatus[user][checkDate]) {
            consecutiveDays++;
            checkDate = getPreviousDate(checkDate);
        }
        
        return consecutiveDays;
    }
    
    /**
     * @dev 获取当前日期（YYYYMMDD格式）
     */
    function getCurrentDate() public view returns (uint256) {
        return uint256(block.timestamp / 86400) * 86400;
    }
    
    /**
     * @dev 获取前一天日期
     */
    function getPreviousDate(uint256 date) internal pure returns (uint256) {
        return date - 86400;
    }
    
    /**
     * @dev 获取用户打卡记录
     */
    function getUserCheckIns(address user) external view returns (CheckInRecord[] memory) {
        return userCheckIns[user];
    }
    
    /**
     * @dev 获取用户打卡记录数量
     */
    function getUserCheckInCount(address user) external view returns (uint256) {
        return userCheckIns[user].length;
    }
    
    /**
     * @dev 获取用户总经验值
     */
    function getUserExperience(address user) external view returns (uint256) {
        return userExperience[user];
    }
    
    /**
     * @dev 检查用户今天是否已打卡
     */
    function hasCheckedInToday(address user) external view returns (bool) {
        return dailyCheckInStatus[user][getCurrentDate()];
    }
    
    /**
     * @dev 获取连续打卡天数（公开接口）
     */
    function getConsecutiveDaysPublic(address user) external view returns (uint256) {
        return getConsecutiveDays(user, getCurrentDate());
    }
} 