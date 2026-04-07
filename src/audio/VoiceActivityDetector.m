classdef VoiceActivityDetector < handle
    properties
        NoiseFloor = 0.01
        Threshold = 3.0
        HangoverFrames = 5
        CalibrationFrames = 10
        FramesSeen = 0
        HangoverCount = 0
    end
    
    methods
        function obj = VoiceActivityDetector(threshold, hangoverFrames)
            if nargin >= 1
                obj.Threshold = threshold;
            end
            if nargin >= 2
                obj.HangoverFrames = hangoverFrames;
            end
        end
        
        function [isSpeech, rms] = detect(obj, frame)
            rms = sqrt(mean(frame.^2));
            obj.FramesSeen = obj.FramesSeen + 1;
            
            % Calibrate noise floor from initial frames
            if obj.FramesSeen <= obj.CalibrationFrames
                obj.NoiseFloor = max(obj.NoiseFloor, rms * 1.2);
                isSpeech = false;
                return;
            end
            
            if rms > obj.NoiseFloor * obj.Threshold
                isSpeech = true;
                obj.HangoverCount = obj.HangoverFrames;
            elseif obj.HangoverCount > 0
                isSpeech = true;
                obj.HangoverCount = obj.HangoverCount - 1;
            else
                isSpeech = false;
                % Slowly adapt noise floor
                obj.NoiseFloor = 0.95 * obj.NoiseFloor + 0.05 * rms;
            end
        end
        
        function reset(obj)
            obj.NoiseFloor = 0.01;
            obj.FramesSeen = 0;
            obj.HangoverCount = 0;
        end
    end
end
