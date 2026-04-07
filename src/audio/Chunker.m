classdef Chunker < handle
    properties
        Config
        Buffer = []
        SilenceCount = 0
        SpeechDetected = false
        VAD  % VoiceActivityDetector
    end
    
    methods
        function obj = Chunker(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
            obj.VAD = VoiceActivityDetector(config.VADThreshold, ...
                round(config.SilenceTimeout * config.SampleRate / config.FrameSize));
        end
        
        function chunk = addFrame(obj, frame)
            chunk = [];
            obj.Buffer = [obj.Buffer; frame];
            
            % Use VoiceActivityDetector for speech detection
            [isSpeech, ~] = obj.VAD.detect(frame);
            
            bufferDuration = length(obj.Buffer) / obj.Config.SampleRate;
            
            if isSpeech
                obj.SpeechDetected = true;
                obj.SilenceCount = 0;
            else
                if obj.SpeechDetected
                    obj.SilenceCount = obj.SilenceCount + 1;
                end
            end
            
            silenceDuration = obj.SilenceCount * obj.Config.FrameSize / obj.Config.SampleRate;
            
            % Emit chunk conditions
            shouldEmit = false;
            if obj.SpeechDetected
                if silenceDuration >= obj.Config.SilenceTimeout && bufferDuration >= obj.Config.MinChunkDuration
                    shouldEmit = true;
                elseif bufferDuration >= obj.Config.MaxChunkDuration
                    shouldEmit = true;
                end
            end
            
            if shouldEmit
                % Keep overlap samples for next chunk
                overlapSamples = round(obj.Config.ChunkOverlap * obj.Config.SampleRate);
                chunk = obj.Buffer;
                
                if overlapSamples > 0 && length(obj.Buffer) > overlapSamples
                    obj.Buffer = obj.Buffer(end-overlapSamples+1:end);
                else
                    obj.Buffer = [];
                end
                
                obj.SpeechDetected = false;
                obj.SilenceCount = 0;
            end
            
            % Prevent unbounded buffer growth during silence
            maxBufferSamples = obj.Config.MaxChunkDuration * obj.Config.SampleRate * 2;
            if length(obj.Buffer) > maxBufferSamples && ~obj.SpeechDetected
                obj.Buffer = obj.Buffer(end - obj.Config.FrameSize * 5 : end);
            end
        end
        
        function reset(obj)
            obj.Buffer = [];
            obj.SilenceCount = 0;
            obj.SpeechDetected = false;
            obj.VAD.reset();
        end
    end
end
