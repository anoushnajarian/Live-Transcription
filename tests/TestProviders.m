classdef TestProviders < matlab.unittest.TestCase
    methods (Test)
        function testWhisperPythonCreation(testCase)
            cfg = Config();
            provider = WhisperPythonProvider(cfg);
            testCase.verifyNotEmpty(provider);
        end
        
        function testMakeResult(testCase)
            cfg = Config();
            provider = WhisperPythonProvider(cfg);
            result = provider.makeResult('test text', true, 0, 1.5);
            testCase.verifyEqual(result.text, "test text");
            testCase.verifyTrue(result.isFinal);
            testCase.verifyEqual(result.startTime, 0);
            testCase.verifyEqual(result.endTime, 1.5);
        end
        
        function testEmptyResultOnMissingWav(testCase)
            cfg = Config();
            provider = WhisperPythonProvider(cfg);
            result = provider.transcribeChunk('nonexistent_file.wav');
            testCase.verifyEqual(strlength(result.text), 0);
        end
        
        function testGoogleProviderCreation(testCase)
            cfg = Config();
            provider = GoogleSpeechProvider(cfg);
            testCase.verifyNotEmpty(provider);
        end
        
        function testGoogleNotAvailableWithoutKey(testCase)
            cfg = Config();
            cfg.GoogleApiKey = "";
            provider = GoogleSpeechProvider(cfg);
            testCase.verifyFalse(provider.isAvailable());
        end
        
        function testGoogleAvailableWithKey(testCase)
            cfg = Config();
            cfg.GoogleApiKey = "test-key-12345";
            provider = GoogleSpeechProvider(cfg);
            testCase.verifyTrue(provider.isAvailable());
        end
        
        function testHuggingFaceCreation(testCase)
            cfg = Config();
            provider = HuggingFaceProvider(cfg);
            testCase.verifyNotEmpty(provider);
        end
        
        function testHuggingFaceDefaultModel(testCase)
            cfg = Config();
            provider = HuggingFaceProvider(cfg);
            testCase.verifyEqual(provider.ModelName, "openai/whisper-medium");
        end
        
        function testHuggingFaceArmenianModel(testCase)
            cfg = Config();
            cfg.Language = "Armenian";
            cfg.LanguageCode = "hy";
            provider = HuggingFaceProvider(cfg);
            testCase.verifyTrue(contains(provider.ModelName, "hy"));
        end
        
        function testHuggingFaceExplicitModel(testCase)
            cfg = Config();
            cfg.HuggingFaceModel = "my-org/custom-model";
            provider = HuggingFaceProvider(cfg);
            testCase.verifyEqual(provider.ModelName, "my-org/custom-model");
        end
        
        function testProviderLanguageFromConfig(testCase)
            cfg = Config();
            cfg.Language = "Spanish";
            cfg.LanguageCode = "es";
            cfg.GoogleLanguageCode = "es-ES";
            
            google = GoogleSpeechProvider(cfg);
            testCase.verifyEqual(google.LanguageCode, "es-ES");
        end
    end
end
