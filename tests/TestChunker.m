classdef TestChunker < matlab.unittest.TestCase
    properties
        Cfg
    end
    
    methods (TestMethodSetup)
        function setupConfig(testCase)
            testCase.Cfg = Config();
            testCase.Cfg.SampleRate = 16000;
            testCase.Cfg.FrameSize = 1600;
            testCase.Cfg.MinChunkDuration = 0.5;
            testCase.Cfg.MaxChunkDuration = 2.0;
            testCase.Cfg.SilenceTimeout = 0.3;
            testCase.Cfg.VADThreshold = 3.0;
            testCase.Cfg.ChunkOverlap = 0.2;
        end
    end
    
    methods (Test)
        function testChunkerCreation(testCase)
            c = Chunker(testCase.Cfg);
            testCase.verifyNotEmpty(c);
        end
        
        function testSilenceProducesNoChunk(testCase)
            c = Chunker(testCase.Cfg);
            for i = 1:20
                frame = zeros(testCase.Cfg.FrameSize, 1);
                chunk = c.addFrame(frame);
            end
            testCase.verifyEmpty(chunk);
        end
        
        function testLoudSignalProducesChunk(testCase)
            c = Chunker(testCase.Cfg);
            
            for i = 1:10
                frame = randn(testCase.Cfg.FrameSize, 1) * 0.001;
                c.addFrame(frame);
            end
            
            numSpeechFrames = ceil(testCase.Cfg.MinChunkDuration * testCase.Cfg.SampleRate / testCase.Cfg.FrameSize) + 5;
            for i = 1:numSpeechFrames
                frame = randn(testCase.Cfg.FrameSize, 1) * 0.5;
                c.addFrame(frame);
            end
            
            chunk = [];
            hangoverFrames = round(testCase.Cfg.SilenceTimeout * testCase.Cfg.SampleRate / testCase.Cfg.FrameSize);
            silenceFramesNeeded = ceil(testCase.Cfg.SilenceTimeout * testCase.Cfg.SampleRate / testCase.Cfg.FrameSize);
            numSilenceFrames = hangoverFrames + silenceFramesNeeded + 5;
            for i = 1:numSilenceFrames
                frame = randn(testCase.Cfg.FrameSize, 1) * 0.001;
                result = c.addFrame(frame);
                if ~isempty(result)
                    chunk = result;
                end
            end
            
            testCase.verifyNotEmpty(chunk);
            testCase.verifyGreaterThan(length(chunk), 0);
        end
        
        function testMaxChunkDurationEnforced(testCase)
            c = Chunker(testCase.Cfg);
            
            for i = 1:10
                frame = randn(testCase.Cfg.FrameSize, 1) * 0.001;
                c.addFrame(frame);
            end
            
            chunk = [];
            numFrames = ceil(testCase.Cfg.MaxChunkDuration * testCase.Cfg.SampleRate / testCase.Cfg.FrameSize) + 5;
            for i = 1:numFrames
                frame = randn(testCase.Cfg.FrameSize, 1) * 0.5;
                result = c.addFrame(frame);
                if ~isempty(result)
                    chunk = result;
                    break;
                end
            end
            
            testCase.verifyNotEmpty(chunk);
            duration = length(chunk) / testCase.Cfg.SampleRate;
            testCase.verifyLessThanOrEqual(duration, testCase.Cfg.MaxChunkDuration + 0.2);
        end
        
        function testResetClearsState(testCase)
            c = Chunker(testCase.Cfg);
            c.addFrame(randn(testCase.Cfg.FrameSize, 1) * 0.5);
            c.reset();
            testCase.verifyEmpty(c.Buffer);
            testCase.verifyFalse(c.SpeechDetected);
        end
    end
end
