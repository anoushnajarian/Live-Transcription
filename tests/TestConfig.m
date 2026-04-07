classdef TestConfig < matlab.unittest.TestCase
    methods (Test)
        function testConfigCreation(testCase)
            cfg = Config();
            testCase.verifyEqual(cfg.SampleRate, 16000);
            testCase.verifyEqual(cfg.FrameSize, 1600);
            testCase.verifyEqual(cfg.NumChannels, 1);
            testCase.verifyEqual(cfg.Language, "English");
            testCase.verifyEqual(cfg.LanguageCode, "en");
        end
        
        function testConfigSaveLoad(testCase)
            cfg = Config();
            cfg.WhisperModel = "medium";
            cfg.Language = "Armenian";
            cfg.LanguageCode = "hy";
            
            tempFile = fullfile(tempdir, 'test_config.json');
            cleanup = onCleanup(@() delete(tempFile));
            
            cfg.saveToFile(tempFile);
            
            cfg2 = Config();
            cfg2.loadFromFile(tempFile);
            
            testCase.verifyEqual(string(cfg2.WhisperModel), "medium");
            testCase.verifyEqual(string(cfg2.Language), "Armenian");
            testCase.verifyEqual(string(cfg2.LanguageCode), "hy");
        end
        
        function testConfigLoadCoercesCharToString(testCase)
            % jsondecode returns char, Config should coerce to string
            tempFile = fullfile(tempdir, 'test_config_coerce.json');
            cleanup = onCleanup(@() delete(tempFile));
            
            fid = fopen(tempFile, 'w');
            fprintf(fid, '{"Language": "Spanish", "LanguageCode": "es"}');
            fclose(fid);
            
            cfg = Config();
            cfg.loadFromFile(tempFile);
            testCase.verifyClass(cfg.Language, 'string');
            testCase.verifyEqual(cfg.Language, "Spanish");
        end
    end
end
