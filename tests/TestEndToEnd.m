classdef TestEndToEnd < matlab.unittest.TestCase
    methods (Test)
        function testCaptionBufferAddAndRetrieve(testCase)
            buf = CaptionBuffer(50);
            buf.addText("Hello");
            buf.addText("World");
            
            lines = buf.getLines();
            testCase.verifyEqual(numel(lines), 2);
            
            transcript = buf.getFullTranscript();
            testCase.verifySubstring(transcript, 'Hello');
            testCase.verifySubstring(transcript, 'World');
        end
        
        function testCaptionBufferClear(testCase)
            buf = CaptionBuffer();
            buf.addText("test");
            buf.clear();
            
            lines = buf.getLines();
            testCase.verifyEmpty(lines);
        end
        
        function testCaptionBufferDuplicateSkip(testCase)
            buf = CaptionBuffer();
            buf.addText("same text");
            buf.addText("same text");
            
            lines = buf.getLines();
            testCase.verifyEqual(numel(lines), 1);
        end
        
        function testTempAudioWriter(testCase)
            audio = randn(16000, 1) * 0.1;
            wavPath = TempAudioWriter.write(audio, 16000);
            cleanup = onCleanup(@() TempAudioWriter.cleanup(wavPath));
            
            testCase.verifyTrue(isfile(wavPath));
            
            [loaded, fs] = audioread(wavPath);
            testCase.verifyEqual(fs, 16000);
            testCase.verifyEqual(numel(loaded), 16000, 'AbsTol', 10);
        end
    end
end
