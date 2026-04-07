classdef GoogleSpeechProvider < STTProvider
    properties
        Config
        ApiKey = ""
        LanguageCode = "en-US"
    end
    
    methods
        function obj = GoogleSpeechProvider(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
            obj.ApiKey = config.GoogleApiKey;
            obj.LanguageCode = config.GoogleLanguageCode;
        end
        
        function tf = isAvailable(obj)
            tf = strlength(obj.ApiKey) > 0;
        end
        
        function result = transcribeChunk(obj, wavPath, options)
            if nargin < 3
                options = struct();
            end
            
            try
                % Read and base64-encode the WAV file
                fid = fopen(wavPath, 'rb');
                audioBytes = fread(fid, Inf, 'uint8=>uint8');
                fclose(fid);
                audioContent = matlab.net.base64encode(audioBytes);
                
                % Build request
                requestBody = struct();
                requestBody.config = struct( ...
                    'encoding', 'LINEAR16', ...
                    'sampleRateHertz', obj.Config.SampleRate, ...
                    'languageCode', obj.LanguageCode, ...
                    'enableAutomaticPunctuation', true);
                requestBody.audio = struct('content', audioContent);
                
                % Send request
                url = sprintf('https://speech.googleapis.com/v1/speech:recognize?key=%s', obj.ApiKey);
                opts = weboptions('MediaType', 'application/json', ...
                    'Timeout', 30, ...
                    'ContentType', 'json');
                
                response = webwrite(url, requestBody, opts);
                
                % Parse response
                if isfield(response, 'results') && ~isempty(response.results)
                    text = response.results(1).alternatives(1).transcript;
                    result = obj.makeResult(text, true, 0, 0, response);
                else
                    result = obj.makeResult('', true, 0, 0, response);
                end
                
            catch ex
                warning('GoogleSpeechProvider:Error', '%s', ex.message);
                result = obj.makeResult('', false);
            end
        end
    end
end
