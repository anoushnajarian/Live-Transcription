classdef WhisperMatlabProvider < STTProvider
    properties
        Config
        Client  % speechClient object
    end
    
    methods
        function obj = WhisperMatlabProvider(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
            
            try
                % For English, omit Language to use the multilingual model
                % with auto-detect (avoids requiring whisper-medium.en).
                % For other languages, force it to prevent misdetection.
                langCode = char(config.LanguageCode);
                if strcmp(langCode, 'en')
                    obj.Client = speechClient("whisper", ...
                        ModelSize=config.WhisperModel, ...
                        Segmentation="none", ...
                        TimeStamps=false);
                else
                    langName = WhisperMatlabProvider.codeToWhisperLang(langCode);
                    obj.Client = speechClient("whisper", ...
                        ModelSize=config.WhisperModel, ...
                        Language=langName, ...
                        Segmentation="none", ...
                        TimeStamps=false);
                end
            catch ex
                warning('WhisperMatlabProvider:InitFailed', ...
                    'Could not initialize Whisper: %s', ex.message);
                obj.Client = [];
            end
        end
        
        function tf = isAvailable(obj)
            tf = ~isempty(obj.Client);
        end
        
        function result = transcribeChunk(obj, wavPath, options) %#ok<INUSD>
            if ~obj.isAvailable()
                result = obj.makeResult('', false);
                return;
            end
            
            [audioData, fs] = audioread(wavPath);
            
            text = speech2text(audioData, fs, Client=obj.Client);
            text = strtrim(char(text));
            
            % Filter out Whisper hallucinations (repetitive patterns)
            if obj.isHallucination(text)
                text = '';
            end
            
            duration = numel(audioData) / fs;
            result = obj.makeResult(text, true, 0, duration);
        end
    end
    
    methods (Access = private)
        function tf = isHallucination(~, text)
            tf = false;
            if strlength(text) < 5
                return;
            end
            
            words = split(string(text));
            numWords = numel(words);
            
            if numWords < 4
                return;
            end
            
            % Long outputs are likely hallucination (Whisper generates
            % repetitive text on silence/noise)
            if numWords > 50
                tf = true;
                return;
            end
            
            % Check for short repeated patterns (2-3 word sequences)
            if numWords >= 6
                for patLen = 2:3
                    for startIdx = 1:(numWords - patLen * 2 + 1)
                        pat = strjoin(words(startIdx:startIdx+patLen-1));
                        repeats = 0;
                        idx = startIdx;
                        while idx + patLen - 1 <= numWords
                            candidate = strjoin(words(idx:idx+patLen-1));
                            if candidate == pat
                                repeats = repeats + 1;
                                idx = idx + patLen;
                            else
                                idx = idx + 1;
                            end
                        end
                        if repeats >= 3
                            tf = true;
                            return;
                        end
                    end
                end
            end
            
            % Check unique word ratio
            uniqueWords = numel(unique(words));
            repetitionRatio = uniqueWords / numWords;
            if repetitionRatio < 0.25
                tf = true;
            end
        end
    end
    
    methods (Static, Access = private)
        function langName = codeToWhisperLang(code)
            % Map ISO 639-1 codes to Whisper language names
            map = containers.Map( ...
                {'en','hy','es','fr','de','ru','ar','zh','ja','ko','pt','it','tr','fa','hi','he','nl','el','pl','uk'}, ...
                {'english','armenian','spanish','french','german','russian','arabic','chinese','japanese','korean','portuguese','italian','turkish','persian','hindi','hebrew','dutch','greek','polish','ukrainian'});
            code = char(code);
            if map.isKey(code)
                langName = map(code);
            else
                langName = 'english';
            end
        end
    end
end
