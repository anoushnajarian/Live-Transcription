classdef Config < handle
    properties
        % Audio settings
        SampleRate = 16000
        FrameSize = 1600        % 100ms at 16kHz
        NumChannels = 1
        
        % Chunking settings
        MinChunkDuration = 3.0  % seconds
        MaxChunkDuration = 8.0  % seconds
        ChunkOverlap = 0.5     % seconds
        TargetChunkDuration = 5.0
        
        % VAD settings
        VADThreshold = 3.0
        SilenceTimeout = 0.5   % seconds
        
        % Provider settings
        DefaultProvider = "Whisper (MATLAB)"
        
        % Language settings
        Language = "English"           % display name
        LanguageCode = "en"            % ISO 639-1 code for Whisper
        GoogleLanguageCode = "en-US"   % BCP-47 for Google
        
        % Whisper settings
        WhisperModel = "medium"
        
        % Google settings
        GoogleApiKey = ""
        
        % HuggingFace settings
        HuggingFaceModel = ""  % auto-selected per language if empty
        
        % UI settings
        MaxTranscriptLines = 100
        CaptionFontSize = 32
        
        % File settings
        TempDir = ""
    end
    
    methods
        function obj = Config()
            obj.TempDir = tempdir;
        end
        
        function loadFromFile(obj, filePath)
            if ~isfile(filePath)
                warning('Config:FileNotFound', 'Config file not found: %s', filePath);
                return;
            end
            data = jsondecode(fileread(filePath));
            fields = fieldnames(data);
            for i = 1:numel(fields)
                if isprop(obj, fields{i})
                    val = data.(fields{i});
                    % Coerce char to string for string properties
                    if ischar(val) && isstring(obj.(fields{i}))
                        val = string(val);
                    end
                    obj.(fields{i}) = val;
                end
            end
        end
        
        function saveToFile(obj, filePath)
            data = struct();
            props = properties(obj);
            for i = 1:numel(props)
                data.(props{i}) = obj.(props{i});
            end
            fid = fopen(filePath, 'w', 'n', 'UTF-8');
            fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
            fclose(fid);
        end
    end
end
