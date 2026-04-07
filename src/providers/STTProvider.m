classdef (Abstract) STTProvider < handle
    methods (Abstract)
        result = transcribeChunk(obj, wavPath, options)
        % Returns struct with fields:
        %   text     - transcribed text (string)
        %   isFinal  - boolean
        %   startTime - double (seconds)
        %   endTime   - double (seconds)
        %   raw      - raw provider response
    end
    
    methods
        function tf = isAvailable(obj) %#ok<MANU>
            tf = true;
        end
        
        function result = makeResult(~, text, isFinal, startTime, endTime, raw)
            if nargin < 6, raw = struct(); end
            if nargin < 5, endTime = 0; end
            if nargin < 4, startTime = 0; end
            if nargin < 3, isFinal = true; end
            result.text = string(text);
            result.isFinal = isFinal;
            result.startTime = startTime;
            result.endTime = endTime;
            result.raw = raw;
        end
    end
end
