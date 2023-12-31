// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {RiskFramework} from "../contracts/RiskFramework.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RiskFrameworkTest is Test {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint256 internal constant ETH_NETWORK_ID = 1;
    uint256 internal constant BSC_NETWORK_ID = 56;
    uint256 internal constant POL_NETWORK_ID = 137;
    uint256 internal constant FTM_NETWORK_ID = 250;
    uint256 internal constant BASE_NETWORK_ID = 8453;
    uint256 internal constant AVAX_NETWORK_ID = 43114;
    uint256 internal constant OP_NETWORK_ID = 10;
    uint256 internal constant LINEA_NETWORK_ID = 59144;
    uint256 internal constant ARB_NETWORK_ID = 42161;

    RiskFramework internal riskFramework;
    address internal configurator;
    address internal admin;
    uint256 internal constant CURRENT_SCORES = 7;
    uint256 internal constant MAX_SCORES = 15;

    function setUp() public {
        configurator = address(0x2);
        admin = address(0x3);
        riskFramework = new RiskFramework(configurator, admin, CURRENT_SCORES);
    }

    function test_fromScoreToList_successful_max_score() external {
        uint8[] memory scores = new uint8[](7);
        scores[0] = 5;
        scores[1] = 5;
        scores[2] = 5;
        scores[3] = 5;
        scores[4] = 5;
        scores[5] = 5;
        scores[6] = 5;
        uint128 expectedScore = 5541893285;
        uint128 expectedAverageScore = 5 * 1000;

        _fromScoreToList_successful(scores, expectedScore, expectedAverageScore);
    }

    function test_fromScoreToList_successful_min_score() external {
        uint8[] memory scores = new uint8[](7);
        scores[0] = 1;
        scores[1] = 1;
        scores[2] = 1;
        scores[3] = 1;
        scores[4] = 1;
        scores[5] = 1;
        scores[6] = 1;
        uint128 expectedScore = 1108378657;
        uint128 expectedAverageScore = 1 * 1000;

        _fromScoreToList_successful(scores, expectedScore, expectedAverageScore);
    }

    function test_fromScoreToList_successful() external {

        uint8[] memory scores = new uint8[](7);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        scores[5] = 2;
        scores[6] = 1;
        uint128 expectedScore = 5471572033;
        uint128 expectedAverageScore = 2857;

        _fromScoreToList_successful(scores, expectedScore, expectedAverageScore);
    }

    function test_fromScoreToList_successful_incorrect_scores_length() external {
        uint8[] memory scores = new uint8[](5);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        uint128 expectedScore = 0;
        uint128 expectedAverageScore = 0;

        (uint128 score, uint128 averageScore) = riskFramework.fromListToScore(scores);

        (uint8[] memory expectedScores,) = riskFramework.fromScoreToList(score);

        assertEq(score, expectedScore, "invalid score");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        for (uint256 index = 0; index < scores.length; ++index) {
            assertEq(expectedScores[index], 0, "invalid item score");
        }
    }

    function test_setUp_successful(address _configurator, address _admin, uint256 _scores) external {
        vm.assume(_configurator != address(0x0));
        vm.assume(_admin != address(0x0));
        vm.assume(_scores > 0 && _scores <= MAX_SCORES);
        address deployer = address(0x9999999999);
        hoax(deployer);
        RiskFramework instance = new RiskFramework(_configurator, _admin, _scores);

        assertEq(instance.currentScores(), _scores, "invalid scores");
        assertTrue(instance.hasRole(instance.CONFIGURATOR_ROLE(), _configurator), "invalid configurator");
        assertTrue(instance.hasRole(instance.DEFAULT_ADMIN_ROLE(), _admin), "invalid admin");
        assertFalse(instance.hasRole(instance.CONFIGURATOR_ROLE(), deployer), "invalid configurator (deployer)");
        assertFalse(instance.hasRole(instance.DEFAULT_ADMIN_ROLE(), deployer), "invalid admin (deployer)");
    }

    function test_setUp_invalid_configurator(address _admin, uint256 _scores) external {
        address initialConfigurator = address(0x0);
        vm.assume(_admin != address(0x0));
        vm.assume(_scores > 0 && _scores <= MAX_SCORES);
        address deployer = address(0x9999999999);
        hoax(deployer);
        vm.expectRevert("!initial_configurator");
        new RiskFramework(initialConfigurator, _admin, _scores);
    }

    function test_setUp_invalid_admin(address _configurator, uint256 _scores) external {
        address initialAdmin = address(0x0);
        vm.assume(_configurator != address(0x0));
        vm.assume(_scores > 0 && _scores <= MAX_SCORES);
        address deployer = address(0x9999999999);
        hoax(deployer);
        vm.expectRevert("!initial_admin");
        new RiskFramework(_configurator, initialAdmin, _scores);
    }

    function test_setScoresAndTags_successful_same_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "curve";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 3;
        scores[1] = 3;
        scores[2] = 3;
        scores[3] = 3;
        scores[4] = 3;
        scores[5] = 3;
        scores[6] = 3;
        uint128 _score = 3325135971;
        uint256 _expectedAverageScore = 3000; // (21 / 7) * 1000
        uint256 _expectedTagsListLength = 1;
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);
    }

    function test_setScoresAndTags_successful_diff_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        scores[5] = 2;
        scores[6] = 1;
        uint128 _score = 5471572033;
        uint256 _expectedAverageScore = 2857; // (20 / 7) * 1000
        uint256 _expectedTagsListLength = 2;
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);
    }

    function test_setScoresAndTags_successful_max_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "compound";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 5;
        scores[2] = 5;
        scores[3] = 5;
        scores[4] = 5;
        scores[5] = 5;
        scores[6] = 5;
        uint128 _score = 5541893285;
        uint256 _expectedAverageScore = 5000; // (35 / 7) * 1000
        uint256 _expectedTagsListLength = 1;
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);
    }

    function test_setScoresAndTags_successful_min_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "aave";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 1;
        scores[1] = 1;
        scores[2] = 1;
        scores[3] = 1;
        scores[4] = 1;
        scores[5] = 1;
        scores[6] = 1;
        uint128 _score = 1108378657;
        uint256 _expectedAverageScore = 1000; // (7 / 7) * 1000
        uint256 _expectedTagsListLength = 1;
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);
    }

    function test_setScoreAndTags_invalid_scores_targets_length(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "aave";
        uint128[] memory _scores = new uint128[](2);
        _scores[0] = 1108378657;
        _scores[1] = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!target_scores_length");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _scores);
    }

    function test_setScoreAndTags_invalid_target_empty() external {
        address target = address(0x0);
        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "aave";
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!target");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(target), _tags, _score);
    }

    function test_setScoreAndTags_invalid_tags_empty(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](0);
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!tags_list");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
    }

    function test_setScoreAndTags_invalid_score_zero(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "aave";
        uint128 _score = 0;
        
        hoax(configurator);
        vm.expectRevert("!score");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
    }

    function test_setScoreAndTags_invalid_tags_empty_item(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "";
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!tag_empty");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
    }

    function test_setScoreAndTags_invalid_tag_already_set(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "aave";
        _tags[1] = "curve";
        _tags[2] = "aave";
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!tag_already_set");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
    }

    function test_setScoreAndTags_invalid_targets_empty() external {
        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "aave";
        _tags[1] = "curve";
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!targets");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, new address[](0), _tags, _score);
    }

    function test_setScoreAndTags_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));
        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "aave";
        _tags[1] = "curve";
        uint128 _score = 1108378657;
        address _sender = address(0x127a11d);
        
        hoax(_sender);
        vm.expectRevert("!configurator");
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
    }

    function test_setScoresAndTags_targets_successful_diff_scores(address _target1, address _target2) external {
        vm.assume(_target1 != address(0x0));
        vm.assume(_target2 != address(0x0));
        vm.assume(_target2 != _target1);

        address[] memory _targets = new address[](2);
        _targets[0] = _target1;
        _targets[1] = _target2;

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        scores[5] = 2;
        scores[6] = 1;
        uint128 _score = 5471572033;
        uint256 _expectedAverageScore = 2857; // (20 / 7) * 1000
        uint256 _expectedTagsListLength = 2;
        _setScoreAndTags_successful(configurator, _score, _tags, _targets, scores, _expectedAverageScore, _expectedTagsListLength);
    }

    function test_removeTags_successful_partially_removed(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);

        bytes32[] memory _tagsToRemove = new bytes32[](2);
        _tagsToRemove[0] = "curve";
        _tagsToRemove[1] = "convex";
        
        hoax(configurator);
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tagsToRemove);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");

        uint256 totalTagsToRemove = _tagsToRemove.length;
        uint256 totalTagsToCheck = tagsList.length;
        assertEq(totalTagsToCheck, _tags.length - totalTagsToRemove);
        for (uint256 i = 0; i < totalTagsToRemove; ++i) {
            bytes32 _tag = _tagsToRemove[i];
            bool found = false;
            for (uint256 j = 0; j < totalTagsToCheck; ++j) {
                found = tagsList[j] == _tag;
                if (found) {
                    break;
                }
            }
            assertFalse(found, "tag should have been removed");
        }
    }

    function test_removeTags_successful_fully_removed(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
        
        hoax(configurator);
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tags);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, 0, "should have removed all tags");
    }

    function test_removeTags_invalid_empty_tag(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);

        bytes32[] memory _tagsToRemove = new bytes32[](1);
        _tagsToRemove[0] = "";
        
        hoax(configurator);
        vm.expectRevert("!tag_empty");
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tagsToRemove);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_removeTags_invalid_tag_not_present(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);

        bytes32[] memory _tagsToRemove = new bytes32[](2);
        _tagsToRemove[0] = "curve";
        _tagsToRemove[1] = "aave";
        
        hoax(configurator);
        vm.expectRevert("!tag_removed");
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tagsToRemove);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_removeTags_invalid_empty_tags(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
        bytes32[] memory _tagsToRemove = new bytes32[](0);

        
        hoax(configurator);
        vm.expectRevert("!tags_list");
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tagsToRemove);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_removeTags_invalid_empty_target(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
        
        hoax(configurator);
        vm.expectRevert("!targets");
        riskFramework.removeTags(ETH_NETWORK_ID, new address[](0), _tags);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_removeTags_invalid_empty_target_item(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
        
        hoax(configurator);
        vm.expectRevert("!score");
        riskFramework.removeTags(ETH_NETWORK_ID, new address[](1), _tags);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_removeTags_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](3);
        _tags[0] = "curve";
        _tags[1] = "convex";
        _tags[2] = "compound";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);
        
        hoax(address(0x99999999));
        vm.expectRevert("!configurator");
        riskFramework.removeTags(ETH_NETWORK_ID, _toArray(_target), _tags);
        
        (
            ,
            ,
            ,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "target should be active");
        assertEq(tagsList.length, _tags.length, "should have not removed any tag");
    }

    function test_setTags_successful(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";

        hoax(configurator);
        riskFramework.setTags(ETH_NETWORK_ID, _toArray(_target), _tags);

        uint128 expectedAverageScore = 2857;
        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "Target should be inactive");
        assertEq(scores, _score, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        assertEq(tagsList.length, _tags.length, "invalid tags length");
    }

    function test_setTags_invalid_no_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";

        hoax(configurator);
        vm.expectRevert("!score");
        riskFramework.setTags(ETH_NETWORK_ID, _toArray(_target), _tags);

        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setTags_invalid_empty_tags(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        bytes32[] memory _tags = new bytes32[](0);

        hoax(configurator);
        vm.expectRevert("!tags_list");
        riskFramework.setTags(ETH_NETWORK_ID, _toArray(_target), _tags);

        uint128 expectedAverageScore = 2857;
        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "Target should be inactive");
        assertEq(scores, _score, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setTags_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";

        hoax(address(0x1234567890));
        vm.expectRevert("!configurator");
        riskFramework.setTags(ETH_NETWORK_ID, _toArray(_target), _tags);

        uint128 expectedAverageScore = 2857;
        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertTrue(isActive, "Target should be inactive");
        assertEq(scores, _score, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setTags_invalid_empty_targets() external {
        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";

        hoax(configurator);
        vm.expectRevert("!targets");
        riskFramework.setTags(ETH_NETWORK_ID, new address[](0), _tags);

        address _target = address(0x0);
        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setTargetsStatus_successful(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);

        bool initialIsActive = riskFramework.INACTIVE();

        hoax(configurator);
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, _toArray(_target), initialIsActive);

        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertEq(initialIsActive, isActive, "is active should be equal");
    }

    function test_setTargetsStatus_invalid_already_active(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128 _score = 5471572033;

        hoax(configurator);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _toArray(_target), _tags, _score);

        bool initialIsActive = riskFramework.ACTIVE();

        hoax(configurator);
        vm.expectRevert("!status");
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, _toArray(_target), initialIsActive);

        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertTrue(isActive, "Status should be equal to active");
    }

    function test_setTargetsStatus_invalid_no_exist(address _target) external {
        vm.assume(_target != address(0x0));

        bool initialIsActive = riskFramework.INACTIVE();

        hoax(configurator);
        vm.expectRevert("!status");
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, _toArray(_target), initialIsActive);

        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertFalse(isActive, "Status should be equal to inactive");
    }

    function test_setTargetsStatus_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));

        bool initialIsActive = riskFramework.ACTIVE();

        hoax(address(0x1234567890));
        vm.expectRevert("!configurator");
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, _toArray(_target), initialIsActive);

        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertFalse(isActive, "Status should be equal to inactive");
    }

    function test_setTargetsStatus_invalid_empty_target_list() external {
        bool initialIsActive = riskFramework.ACTIVE();

        hoax(configurator);
        vm.expectRevert("!targets");
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, new address[](0), initialIsActive);

        address _target = address(0x0);
        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertFalse(isActive, "Status should be equal to inactive");
    }

    function test_setTargetsStatus_invalid_empty_target_item() external {
        address _target = address(0x0);

        bool initialIsActive = riskFramework.ACTIVE();

        hoax(configurator);
        vm.expectRevert("!target");
        riskFramework.setTargetsStatus(ETH_NETWORK_ID, new address[](1), initialIsActive);

        bool isActive = riskFramework.isTargetActive(ETH_NETWORK_ID, _target);
        assertFalse(isActive, "Status should be equal to inactive");
    }

    function test_copyScores_successful_max_scores(address _target) external {
        vm.assume(_target != address(0x0));

        bytes32[] memory _tags = new bytes32[](1);
        _tags[0] = "compound";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 5;
        scores[2] = 5;
        scores[3] = 5;
        scores[4] = 5;
        scores[5] = 5;
        scores[6] = 5;
        uint128 _score = 5541893285;
        uint256 _expectedAverageScore = 5000; // (35 / 7) * 1000
        uint256 _expectedTagsListLength = 1;

        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);

        address[] memory _toTargets = new address[](2);
        _toTargets[0] = address(0x00000001111111);
        _toTargets[1] = address(0x00000002222222);

        hoax(configurator);
        riskFramework.copyScores(ETH_NETWORK_ID, _target, _toTargets, _tags);
        uint256 totalTargets = _toTargets.length;

        for (uint256 globalIndex = 0; globalIndex < totalTargets; ++globalIndex) {
            _assert_setScoresAndTags_successful(_score, _tags, _toTargets[globalIndex], scores, _expectedAverageScore, _expectedTagsListLength, totalTargets + 1);
        }
    }

    function test_copyScores_successful_successful_diff_scores(address _target) external {
        vm.assume(_target != address(0x0));

        address[] memory _toTargets = new address[](2);
        _toTargets[0] = address(0x000011111111111);
        _toTargets[1] = address(0x000022222222222);
        bytes32[] memory _toTargetTags = new bytes32[](2);
        _toTargetTags[0] = "aura";
        _toTargetTags[1] = "compound";

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        scores[5] = 2;
        scores[6] = 1;
        uint128 _score = 5471572033;
        uint256 _expectedAverageScore = 2857; // (20 / 7) * 1000
        uint256 _expectedTagsListLength = 2;
        
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);

        hoax(configurator);
        riskFramework.copyScores(ETH_NETWORK_ID, _target, _toTargets, _toTargetTags);
        uint256 totalTargets = _toTargets.length;

        for (uint256 globalIndex = 0; globalIndex < totalTargets; ++globalIndex) {
            _assert_setScoresAndTags_successful(_score, _toTargetTags, _toTargets[globalIndex], scores, _expectedAverageScore, _expectedTagsListLength, totalTargets);
        }
    }

    function test_copyScores_successful_successful_diff_scores_and_empty_tags(address _target) external {
        vm.assume(_target != address(0x0));

        address[] memory _toTargets = new address[](2);
        _toTargets[0] = address(0x000011111111111);
        _toTargets[1] = address(0x000022222222222);
        bytes32[] memory _toTargetTags = new bytes32[](0);

        bytes32[] memory _tags = new bytes32[](2);
        _tags[0] = "curve";
        _tags[1] = "convex";
        uint128[] memory scores = new uint128[](7);
        scores[0] = 5;
        scores[1] = 3;
        scores[2] = 2;
        scores[3] = 3;
        scores[4] = 4;
        scores[5] = 2;
        scores[6] = 1;
        uint128 _score = 5471572033;
        uint256 _expectedAverageScore = 2857; // (20 / 7) * 1000
        uint256 _expectedTagsListLength = 2;
        
        _setScoreAndTags_successful(configurator, _score, _tags, _toArray(_target), scores, _expectedAverageScore, _expectedTagsListLength);

        hoax(configurator);
        riskFramework.copyScores(ETH_NETWORK_ID, _target, _toTargets, _toTargetTags);
        uint256 totalTargets = _toTargets.length;

        for (uint256 globalIndex = 0; globalIndex < totalTargets; ++globalIndex) {
            _assert_setScoresAndTags_successful(_score, _tags, _toTargets[globalIndex], scores, _expectedAverageScore, _expectedTagsListLength, totalTargets + 1);
        }
    }

    function test_copyScores_successful_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));

        address[] memory _toTargets = new address[](2);
        _toTargets[0] = address(0x000011111111111);
        _toTargets[1] = address(0x000022222222222);
        bytes32[] memory _toTargetTags = new bytes32[](2);
        _toTargetTags[0] = "aura";
        _toTargetTags[1] = "compound";

        address _sender = address(0x127a11d);

        hoax(_sender);
        vm.expectRevert("!configurator");
        riskFramework.copyScores(ETH_NETWORK_ID, _target, _toTargets, _toTargetTags);
    }

    function test_copyScores_successful_invalid_score_zero(address _fromTarget) external {
        vm.assume(_fromTarget != address(0x0));

        address[] memory _toTargets = new address[](2);
        _toTargets[0] = address(0x000011111111111);
        _toTargets[1] = address(0x000022222222222);
        bytes32[] memory _toTargetTags = new bytes32[](2);
        _toTargetTags[0] = "aura";
        _toTargetTags[1] = "compound";

        hoax(configurator);
        vm.expectRevert("!score");
        riskFramework.copyScores(ETH_NETWORK_ID, _fromTarget, _toTargets, _toTargetTags);
    }

    function test_copyScores_successful_invalid_to_targets_empty(address _target) external {
        vm.assume(_target != address(0x0));

        address[] memory _toTargets = new address[](0);
        bytes32[] memory _toTargetTags = new bytes32[](2);
        _toTargetTags[0] = "aura";
        _toTargetTags[1] = "compound";
        
        hoax(configurator);
        vm.expectRevert("!to_targets");
        riskFramework.copyScores(ETH_NETWORK_ID, _target, _toTargets, _toTargetTags);
    }

    function test_setScore_invalid_empty_targets_length() external {
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!targets");
        riskFramework.setScore(ETH_NETWORK_ID, new address[](0), _score);

        address _target = address(0x0);
        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setScore_invalid_target_empty_item() external {
        address _target = address(0x0);
        uint128 _score = 1108378657;
        
        hoax(configurator);
        vm.expectRevert("!target");
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setScore_invalid_score_zero(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 0;
        
        hoax(configurator);
        vm.expectRevert("!score");
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }


    function test_setScore_invalid_sender(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 1108378657;
        address _sender = address(0x127a11d);
        
        hoax(_sender);
        vm.expectRevert("!configurator");
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        assertFalse(isActive, "Target should be inactive");
        assertEq(scores, 0, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, 0, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setScore_successful(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 1108378657;
        
        hoax(configurator);
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);

        (
            uint128 scores,
            uint8[] memory scoresList,
            uint128 averageScore,
            bytes32[] memory tagsList,
            bool isActive
        ) = riskFramework.getTargetInfo(ETH_NETWORK_ID, _target);

        uint128 expectedAverageScore = 1 * 1000;
        assertTrue(isActive, "Target should be inactive");
        assertEq(scores, _score, "invalid score");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        assertEq(tagsList.length, 0, "invalid tags length");
    }

    function test_setScore_successful_multinetwork(address _target) external {
        vm.assume(_target != address(0x0));
        uint128 _score = 1108378657;
        
        hoax(configurator);
        riskFramework.setScore(ETH_NETWORK_ID, _toArray(_target), _score);
        hoax(configurator);
        riskFramework.setScore(FTM_NETWORK_ID, _toArray(_target), _score);

        uint256[] memory networks = riskFramework.getNetworksByTarget(_target);
        assertEq(networks.length, 2, "invalid network length");
        assertEq(networks[0], ETH_NETWORK_ID, "invalid eth network");
        assertEq(networks[1], FTM_NETWORK_ID, "invalid eth network");
    }

    // Internal Functions

    function _assert_setScoresAndTags_successful(uint128 _score, bytes32[] memory _tags, address _target, uint128[] memory _expectedScores, uint256 _expectedAverageScore, uint256 _expectedTagsListLength, uint256 _expectedTargetsByTag) internal {
        uint256[] memory networks = riskFramework.getNetworksByTarget(_target);
        assertEq(networks.length, 1, "networks length should be 1");
        assertEq(networks[0], ETH_NETWORK_ID, "networks should be eth mainnet");

        assertEq(riskFramework.getScoresByTarget(ETH_NETWORK_ID, _target), _score, "invalid scores");
        (uint128 scores, uint8[] memory scoresList, uint128 averageScore, bytes32[] memory tagsList, bool isActive) = riskFramework
            .getTargetInfo(ETH_NETWORK_ID, _target);
        
        assertTrue(isActive, "target should be active");
        assertEq(scores, _score, "invalid scores");
        assertEq(scoresList.length, CURRENT_SCORES, "invalid scores length");
        for (uint256 index = 0; index < CURRENT_SCORES; ++index) {
            assertTrue(scoresList[index] > 0 && scoresList[index] <= 5, "invalid item score range");
            assertEq(scoresList[index], _expectedScores[index], "invalid item score");
        }

        assertEq(averageScore, _expectedAverageScore, "invalid average score");
        assertEq(tagsList.length, _expectedTagsListLength, "invalid tags length");

        assertEq(tagsList[0], _tags[0], "invalid tag");
        for (uint256 index = 0; index < _expectedTagsListLength; ++index) {
            assertEq(tagsList[index], _tags[index], "invalid tag");
            assertEq(riskFramework.getTargetsByTag(_tags[index]).length, _expectedTargetsByTag, "invalid targets by tag length");
        }
    }

    function _fromScoreToList_successful(uint8[] memory scores, uint128 expectedScore, uint128 expectedAverageScore) internal {
        (uint128 score, uint128 averageScore) = riskFramework.fromListToScore(scores);

        (uint8[] memory expectedScores,) = riskFramework.fromScoreToList(score);

        assertEq(score, expectedScore, "invalid score");
        assertEq(averageScore, expectedAverageScore, "invalid average score");
        for (uint256 index = 0; index < scores.length; ++index) {
            assertEq(scores[index], expectedScores[index], "invalid item score");
        }
    }

    function _setScoreAndTags_successful(address sender, uint128 _score, bytes32[] memory _tags, address[] memory _targets, uint128[] memory _expectedScores, uint256 _expectedAverageScore, uint256 _expectedTagsListLength) internal {
        hoax(sender);
        riskFramework.setScoreAndTags(ETH_NETWORK_ID, _targets, _tags, _score);
        uint256 totalTargets = _targets.length;

        for (uint256 globalIndex = 0; globalIndex < totalTargets; ++globalIndex) {
            _assert_setScoresAndTags_successful(_score, _tags, _targets[globalIndex], _expectedScores, _expectedAverageScore, _expectedTagsListLength, totalTargets);
        }
    }

    function _toArray(address item) internal pure returns (address[] memory) {
        address[] memory items = new address[](1);
        items[0] = item;
        return items;
    }
}
