classdef CaptionMerger
    methods (Static)
        function merged = mergeOverlap(prevText, newText)
            % Remove overlapping words between end of prevText and start of newText
            if strlength(prevText) == 0 || strlength(newText) == 0
                merged = newText;
                return;
            end
            
            prevWords = split(prevText);
            newWords = split(newText);
            
            % Find longest overlap
            maxOverlap = min(numel(prevWords), numel(newWords));
            overlapLen = 0;
            
            for k = 1:maxOverlap
                tailWords = prevWords(end - k + 1 : end);
                headWords = newWords(1:k);
                if isequal(lower(tailWords), lower(headWords))
                    overlapLen = k;
                end
            end
            
            if overlapLen > 0
                % Remove overlapping prefix from new text
                remainingWords = newWords(overlapLen + 1 : end);
                if isempty(remainingWords)
                    merged = newText;
                else
                    merged = strjoin(remainingWords);
                end
            else
                merged = newText;
            end
        end
    end
end
