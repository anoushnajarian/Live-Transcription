classdef TempAudioWriter
    methods (Static)
        function wavPath = write(audioData, sampleRate)
            if nargin < 2
                sampleRate = 16000;
            end
            wavPath = fullfile(tempdir, ['transcribe_chunk_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS')) '.wav']);
            audiowrite(wavPath, audioData, sampleRate);
        end
        
        function cleanup(wavPath)
            if isfile(wavPath)
                delete(wavPath);
            end
        end
    end
end
