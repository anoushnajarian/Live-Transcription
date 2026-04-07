classdef LanguageRegistry
    % Maps display names to language codes and script metadata.
    % Used by Config and the UI to populate the language dropdown.
    
    methods (Static)
        function languages = all()
            % Returns a struct array of supported languages.
            languages = struct( ...
                'name',        {'Arabic', 'Armenian', 'Chinese', 'Dutch', 'English', 'French', 'German', 'Greek', 'Hebrew', 'Hindi', 'Italian', 'Japanese', 'Korean', 'Persian', 'Polish', 'Portuguese', 'Russian', 'Spanish', 'Turkish', 'Ukrainian'}, ...
                'code',        {'ar',     'hy',       'zh',      'nl',    'en',      'fr',     'de',     'el',    'he',     'hi',    'it',      'ja',       'ko',     'fa',      'pl',     'pt',         'ru',      'es',      'tr',      'uk'}, ...
                'googleCode',  {'ar-SA',  'hy-AM',    'zh-CN',   'nl-NL', 'en-US',   'fr-FR',  'de-DE',  'el-GR', 'he-IL',  'hi-IN', 'it-IT',   'ja-JP',    'ko-KR',  'fa-IR',   'pl-PL',  'pt-BR',      'ru-RU',   'es-ES',   'tr-TR',   'uk-UA'}, ...
                'script',      {'arabic', 'armenian', 'cjk',     'latin', 'latin',   'latin',  'latin',  'greek', 'hebrew', 'devanagari','latin','cjk',     'cjk',    'arabic',  'latin',  'latin',      'cyrillic','latin',   'latin',   'cyrillic'}, ...
                'hfModel',     {'',       'Chillarmo/whisper-small-hy-AM','','','',    '',       '',       '',      'ivrit-ai/whisper-v2-d3-e3','','',       '',       '',        '',       '',    '',           '',        '',        '',        ''} ...
            );
        end
        
        function names = displayNames()
            langs = LanguageRegistry.all();
            names = {langs.name};
        end
        
        function lang = findByName(name)
            langs = LanguageRegistry.all();
            idx = find(strcmp({langs.name}, name), 1);
            if isempty(idx)
                lang = langs(1); % default to English
            else
                lang = langs(idx);
            end
        end
        
        function lang = findByCode(code)
            langs = LanguageRegistry.all();
            idx = find(strcmp({langs.code}, code), 1);
            if isempty(idx)
                lang = langs(1);
            else
                lang = langs(idx);
            end
        end
    end
end
