classdef TestUnicode < matlab.unittest.TestCase
    methods (Test)
        function testArmenianStringCreation(testCase)
            hello = string(char([1330, 1377, 1408, 1381, 1410]));
            testCase.verifyGreaterThan(strlength(hello), 0);
        end
        
        function testArmenianStringEquality(testCase)
            s1 = string(char([1344, 1377, 1397]));
            s2 = string(char([1344, 1377, 1397]));
            testCase.verifyEqual(s1, s2);
        end
        
        function testUtf8RoundTrip(testCase)
            armenianText = string(char([1330, 1377, 1408, 1381, 1410, 32, ...
                1393, 1381, 1382]));
            
            tempFile = fullfile(tempdir, 'test_utf8.txt');
            cleanup = onCleanup(@() delete(tempFile));
            
            Utf8File.write(tempFile, armenianText);
            loaded = string(Utf8File.read(tempFile));
            
            testCase.verifyEqual(strtrim(loaded), armenianText);
        end
        
        function testCyrillicRoundTrip(testCase)
            russianText = string(char([1055, 1088, 1080, 1074, 1077, 1090]));
            
            tempFile = fullfile(tempdir, 'test_cyrillic_utf8.txt');
            cleanup = onCleanup(@() delete(tempFile));
            
            Utf8File.write(tempFile, russianText);
            loaded = string(Utf8File.read(tempFile));
            
            testCase.verifyEqual(strtrim(loaded), russianText);
        end
        
        function testFontHelperReturnsFont(testCase)
            fontName = FontHelper.selectFont();
            testCase.verifyNotEmpty(fontName);
            testCase.verifyClass(fontName, 'char');
        end
        
        function testFontHelperPerScript(testCase)
            scripts = {'latin', 'armenian', 'cyrillic', 'arabic', 'cjk', 'devanagari'};
            for i = 1:numel(scripts)
                fontName = FontHelper.selectFont(scripts{i});
                testCase.verifyNotEmpty(fontName, ...
                    sprintf('FontHelper returned empty for script: %s', scripts{i}));
            end
        end
        
        function testFontHelperForLanguage(testCase)
            fontName = FontHelper.selectFontForLanguage('Armenian');
            testCase.verifyNotEmpty(fontName);
        end
    end
end
