classdef CaptionBuffer < handle
    properties
        Lines = string.empty
        MaxLines = 100
        LastText = ""
    end
    
    methods
        function obj = CaptionBuffer(maxLines)
            if nargin >= 1
                obj.MaxLines = maxLines;
            end
        end
        
        function addText(obj, text)
            text = string(strtrim(char(text)));
            if strlength(text) == 0
                return;
            end
            
            % Simple dedup: skip if identical to last
            if text == obj.LastText
                return;
            end
            
            % Remove overlapping prefix with last text
            text = CaptionMerger.mergeOverlap(obj.LastText, text);
            
            obj.LastText = text;
            
            % Add timestamp
            timestamp = string(datestr(now, 'HH:MM:SS'));
            line = "[" + timestamp + "] " + text;
            obj.Lines(end+1) = line;
            
            % Trim to max lines
            if numel(obj.Lines) > obj.MaxLines
                obj.Lines = obj.Lines(end - obj.MaxLines + 1 : end);
            end
        end
        
        function lines = getLines(obj)
            lines = cellstr(obj.Lines);
        end
        
        function text = getFullTranscript(obj)
            text = strjoin(cellstr(obj.Lines), newline);
        end
        
        function clear(obj)
            obj.Lines = string.empty;
            obj.LastText = "";
        end
    end
end
