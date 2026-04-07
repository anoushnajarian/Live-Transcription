classdef TestCaptionMerger < matlab.unittest.TestCase
    methods (Test)
        function testNoOverlap(testCase)
            result = CaptionMerger.mergeOverlap("hello world", "foo bar");
            testCase.verifyEqual(result, "foo bar");
        end
        
        function testSimpleOverlap(testCase)
            result = CaptionMerger.mergeOverlap("the quick brown", "brown fox jumps");
            testCase.verifyEqual(result, "fox jumps");
        end
        
        function testMultiWordOverlap(testCase)
            result = CaptionMerger.mergeOverlap("one two three four", "three four five six");
            testCase.verifyEqual(result, "five six");
        end
        
        function testEmptyPrevText(testCase)
            result = CaptionMerger.mergeOverlap("", "hello world");
            testCase.verifyEqual(result, "hello world");
        end
        
        function testEmptyNewText(testCase)
            result = CaptionMerger.mergeOverlap("hello world", "");
            testCase.verifyEqual(result, "");
        end
        
        function testIdenticalTexts(testCase)
            result = CaptionMerger.mergeOverlap("hello world", "hello world");
            testCase.verifyEqual(result, "hello world");
        end
        
        function testCaseInsensitiveOverlap(testCase)
            result = CaptionMerger.mergeOverlap("Hello World", "world peace");
            testCase.verifyEqual(result, "peace");
        end
    end
end
