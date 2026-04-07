classdef TestVAD < matlab.unittest.TestCase
    methods (Test)
        function testVADCreation(testCase)
            vad = VoiceActivityDetector(3.0, 5);
            testCase.verifyEqual(vad.Threshold, 3.0);
            testCase.verifyEqual(vad.HangoverFrames, 5);
        end
        
        function testCalibrationPhase(testCase)
            vad = VoiceActivityDetector(3.0, 5);
            for i = 1:10
                frame = randn(1600, 1) * 0.001;
                [isSpeech, ~] = vad.detect(frame);
                testCase.verifyFalse(isSpeech);
            end
        end
        
        function testSpeechDetection(testCase)
            vad = VoiceActivityDetector(3.0, 5);
            
            for i = 1:10
                frame = randn(1600, 1) * 0.001;
                vad.detect(frame);
            end
            
            loudFrame = randn(1600, 1) * 0.5;
            [isSpeech, ~] = vad.detect(loudFrame);
            testCase.verifyTrue(isSpeech);
        end
        
        function testSilenceAfterHangover(testCase)
            vad = VoiceActivityDetector(3.0, 5);
            
            for i = 1:10
                vad.detect(randn(1600, 1) * 0.001);
            end
            
            vad.detect(randn(1600, 1) * 0.5);
            
            for i = 1:10
                [isSpeech, ~] = vad.detect(randn(1600, 1) * 0.001);
            end
            testCase.verifyFalse(isSpeech);
        end
        
        function testReset(testCase)
            vad = VoiceActivityDetector();
            vad.detect(randn(1600, 1) * 0.5);
            vad.reset();
            testCase.verifyEqual(vad.FramesSeen, 0);
            testCase.verifyEqual(vad.HangoverCount, 0);
        end
    end
end
