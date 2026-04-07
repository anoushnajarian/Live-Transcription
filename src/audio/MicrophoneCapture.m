classdef MicrophoneCapture < handle
    properties
        Reader          % audioDeviceReader
        Config          % Config object
        IsActive = false
    end
    
    methods
        function obj = MicrophoneCapture(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
        end
        
        function start(obj)
            if obj.IsActive
                return;
            end
            
            % Release any stale reader
            if ~isempty(obj.Reader)
                try release(obj.Reader); catch; end
                obj.Reader = [];
            end
            
            try
                obj.Reader = audioDeviceReader( ...
                    'SampleRate', obj.Config.SampleRate, ...
                    'SamplesPerFrame', obj.Config.FrameSize, ...
                    'NumChannels', 1);
                setup(obj.Reader);
                obj.IsActive = true;
            catch ex
                warning('MicrophoneCapture:StartFailed', ...
                    'Could not start microphone: %s', ex.message);
            end
        end
        
        function [frame, isValid] = readFrame(obj)
            frame = [];
            isValid = false;
            if ~obj.IsActive || isempty(obj.Reader)
                return;
            end
            try
                frame = obj.Reader();
                isValid = true;
            catch
                isValid = false;
            end
        end
        
        function stop(obj)
            if obj.IsActive && ~isempty(obj.Reader)
                release(obj.Reader);
            end
            obj.IsActive = false;
        end
        
        function delete(obj)
            obj.stop();
        end
    end
end
