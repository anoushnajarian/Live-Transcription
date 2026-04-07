classdef FontHelper
    % Selects the best available font for a given script.
    % Replaces ArmenianFontHelper with multi-script support.
    
    methods (Static)
        function fontName = selectFont(script)
            % Returns the best available font for the given script.
            % script: 'latin', 'armenian', 'cyrillic', 'arabic', 'cjk',
            %         'devanagari', or '' (default)
            if nargin < 1
                script = 'latin';
            end
            
            candidates = FontHelper.fontsForScript(script);
            
            try
                availableFonts = listfonts();
            catch
                fontName = 'Arial';
                return;
            end
            
            for i = 1:numel(candidates)
                if any(strcmpi(availableFonts, candidates{i}))
                    fontName = candidates{i};
                    return;
                end
            end
            
            fontName = 'Arial';
        end
        
        function fontName = selectFontForLanguage(languageName)
            % Convenience: select font by language name via LanguageRegistry
            lang = LanguageRegistry.findByName(languageName);
            fontName = FontHelper.selectFont(lang.script);
        end
    end
    
    methods (Static, Access = private)
        function fonts = fontsForScript(script)
            switch lower(script)
                case 'armenian'
                    fonts = {'Noto Sans Armenian', 'Noto Sans', 'DejaVu Sans', ...
                             'Sylfaen', 'Arial Unicode MS', 'Segoe UI', 'Arial'};
                case 'cyrillic'
                    fonts = {'Noto Sans', 'DejaVu Sans', 'Segoe UI', ...
                             'Arial Unicode MS', 'Times New Roman', 'Arial'};
                case 'arabic'
                    fonts = {'Noto Sans Arabic', 'Noto Sans', 'Segoe UI', ...
                             'Arial Unicode MS', 'Traditional Arabic', 'Arial'};
                case 'cjk'
                    fonts = {'Noto Sans CJK', 'Microsoft YaHei', 'MS Gothic', ...
                             'Malgun Gothic', 'SimHei', 'Arial Unicode MS', 'Arial'};
                case 'devanagari'
                    fonts = {'Noto Sans Devanagari', 'Noto Sans', 'Mangal', ...
                             'Arial Unicode MS', 'Segoe UI', 'Arial'};
                case 'greek'
                    fonts = {'Noto Sans', 'DejaVu Sans', 'Segoe UI', ...
                             'Arial Unicode MS', 'Times New Roman', 'Arial'};
                case 'hebrew'
                    fonts = {'Noto Sans Hebrew', 'Noto Sans', 'David', ...
                             'Arial Unicode MS', 'Segoe UI', 'Arial'};
                otherwise  % latin
                    fonts = {'Segoe UI', 'Noto Sans', 'DejaVu Sans', ...
                             'Helvetica', 'Arial'};
            end
        end
    end
end
