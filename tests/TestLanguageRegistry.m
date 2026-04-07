classdef TestLanguageRegistry < matlab.unittest.TestCase
    methods (Test)
        function testAllLanguages(testCase)
            langs = LanguageRegistry.all();
            testCase.verifyGreaterThanOrEqual(numel(langs), 10);
        end
        
        function testDisplayNames(testCase)
            names = LanguageRegistry.displayNames();
            testCase.verifyTrue(ismember('English', names));
            testCase.verifyTrue(ismember('Armenian', names));
            testCase.verifyTrue(ismember('Spanish', names));
        end
        
        function testFindByName(testCase)
            lang = LanguageRegistry.findByName('Armenian');
            testCase.verifyEqual(lang.code, 'hy');
            testCase.verifyEqual(lang.googleCode, 'hy-AM');
            testCase.verifyEqual(lang.script, 'armenian');
        end
        
        function testFindByCode(testCase)
            lang = LanguageRegistry.findByCode('es');
            testCase.verifyEqual(lang.name, 'Spanish');
            testCase.verifyEqual(lang.googleCode, 'es-ES');
        end
        
        function testFindUnknownDefaultsToEnglish(testCase)
            lang = LanguageRegistry.findByName('Klingon');
            testCase.verifyEqual(lang.code, 'en');
        end
        
        function testArmenianHasHuggingFaceModel(testCase)
            lang = LanguageRegistry.findByName('Armenian');
            testCase.verifyGreaterThan(strlength(string(lang.hfModel)), 0);
        end
        
        function testEachLanguageHasAllFields(testCase)
            langs = LanguageRegistry.all();
            for i = 1:numel(langs)
                testCase.verifyNotEmpty(langs(i).name, ...
                    sprintf('Language %d missing name', i));
                testCase.verifyNotEmpty(langs(i).code, ...
                    sprintf('Language %d missing code', i));
                testCase.verifyNotEmpty(langs(i).googleCode, ...
                    sprintf('Language %d missing googleCode', i));
                testCase.verifyNotEmpty(langs(i).script, ...
                    sprintf('Language %d missing script', i));
            end
        end
    end
end
