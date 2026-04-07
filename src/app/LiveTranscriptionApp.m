classdef LiveTranscriptionApp < handle
    properties
        Fig               % uifigure
        StartBtn          % Start button
        StopBtn           % Stop button
        ClearBtn          % Clear button
        SaveBtn           % Save button
        DeviceDropDown    % Mic device selector
        ProviderDropDown  % STT provider selector
        LanguageDropDown  % Language selector
        StatusLamp        % Status indicator lamp
        StatusLabel       % Status text
        CaptionLabel      % Large caption display (uilabel)
        TranscriptArea    % Scrolling transcript (uitextarea)
        LevelGauge        % Audio level indicator
        
        MicCapture        % MicrophoneCapture object
        Chunker           % Chunker object
        Provider          % STTProvider object
        CaptionBuf        % CaptionBuffer object
        
        CaptureTimer      % Timer for audio capture loop
        TranscribeTimer   % Timer for transcription (separate from capture)
        TranscribeFuture  % parfeval Future for async transcription
        TranscribeWavPath = ""  % WAV path being transcribed
        ChunkQueue = {}   % Queue of WAV paths awaiting transcription
        IsRunning = false
        Config            % Config object
        TranscribeStartTime = []  % tic value when transcription started
        DotCount = 0              % animation counter for "Transcribing..."
    end
    
    methods
        function app = LiveTranscriptionApp(config)
            if nargin < 1
                config = Config();
            end
            app.Config = config;
            app.buildUI();
            app.initComponents();
        end
        
        function buildUI(app)
            app.Fig = uifigure('Name', 'Live Transcription', ...
                'Position', [100 100 1000 600], ...
                'Color', [0.1 0.1 0.15], ...
                'CloseRequestFcn', @(~,~) app.onClose());
            
            gl = uigridlayout(app.Fig, [5 8]);
            gl.RowHeight = {30, 30, '2x', '1x', 25};
            gl.ColumnWidth = {'1x','1x','1x','1x','1x','1x','0.5x','1x'};
            gl.BackgroundColor = [0.1 0.1 0.15];
            
            % Row 1: Language, Device, Provider, Status
            langLbl = uilabel(gl, 'Text', 'Language:', ...
                'FontColor', [0.8 0.8 0.8]);
            langLbl.Layout.Row = 1; langLbl.Layout.Column = 1;
            
            app.LanguageDropDown = uidropdown(gl, ...
                'Items', LanguageRegistry.displayNames(), ...
                'Value', char(app.Config.Language), ...
                'ValueChangedFcn', @(~,~) app.onLanguageChanged());
            app.LanguageDropDown.Layout.Row = 1; app.LanguageDropDown.Layout.Column = 2;
            
            devLbl = uilabel(gl, 'Text', 'Microphone:', ...
                'FontColor', [0.8 0.8 0.8]);
            devLbl.Layout.Row = 1; devLbl.Layout.Column = 3;
            
            app.DeviceDropDown = uidropdown(gl, 'Items', {'Default'});
            app.DeviceDropDown.Layout.Row = 1; app.DeviceDropDown.Layout.Column = 4;
            
            provLbl = uilabel(gl, 'Text', 'Provider:', ...
                'FontColor', [0.8 0.8 0.8]);
            provLbl.Layout.Row = 1; provLbl.Layout.Column = 5;
            
            app.ProviderDropDown = uidropdown(gl, ...
                'Items', {'Whisper (MATLAB)', 'Whisper (Python)', 'HuggingFace', 'Google Cloud'}, ...
                'ValueChangedFcn', @(~,~) app.onProviderChanged());
            app.ProviderDropDown.Layout.Row = 1; app.ProviderDropDown.Layout.Column = 6;
            
            app.StatusLamp = uilamp(gl, 'Color', [0.5 0.5 0.5]);
            app.StatusLamp.Layout.Row = 1; app.StatusLamp.Layout.Column = 7;
            
            app.StatusLabel = uilabel(gl, 'Text', 'Ready', ...
                'FontColor', [0.8 0.8 0.8]);
            app.StatusLabel.Layout.Row = 1; app.StatusLabel.Layout.Column = 8;
            
            % Row 2: Buttons + Level gauge
            app.StartBtn = uibutton(gl, 'Text', 'Start', ...
                'BackgroundColor', [0.2 0.6 0.3], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.onStart());
            app.StartBtn.Layout.Row = 2; app.StartBtn.Layout.Column = 1;
            
            app.StopBtn = uibutton(gl, 'Text', 'Stop', ...
                'BackgroundColor', [0.7 0.2 0.2], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onStop());
            app.StopBtn.Layout.Row = 2; app.StopBtn.Layout.Column = 2;
            
            app.ClearBtn = uibutton(gl, 'Text', 'Clear', ...
                'ButtonPushedFcn', @(~,~) app.onClear());
            app.ClearBtn.Layout.Row = 2; app.ClearBtn.Layout.Column = 3;
            
            app.SaveBtn = uibutton(gl, 'Text', 'Save Transcript', ...
                'ButtonPushedFcn', @(~,~) app.onSave());
            app.SaveBtn.Layout.Row = 2; app.SaveBtn.Layout.Column = 4;
            
            app.LevelGauge = uigauge(gl, 'linear', ...
                'Limits', [0 1], 'Value', 0, ...
                'ScaleColors', [0.2 0.8 0.2; 0.9 0.9 0.2; 0.9 0.2 0.2], ...
                'ScaleColorLimits', [0 0.5; 0.5 0.8; 0.8 1]);
            app.LevelGauge.Layout.Row = 2; app.LevelGauge.Layout.Column = [5 8];
            
            % Row 3: Main caption display
            selectedFont = FontHelper.selectFontForLanguage(app.Config.Language);
            app.CaptionLabel = uilabel(gl, ...
                'Text', '', ...
                'FontSize', 32, ...
                'FontName', selectedFont, ...
                'FontColor', [1 1 1], ...
                'BackgroundColor', [0.15 0.15 0.2], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'center', ...
                'WordWrap', 'on');
            app.CaptionLabel.Layout.Row = 3; app.CaptionLabel.Layout.Column = [1 8];
            
            % Row 4: Transcript history
            app.TranscriptArea = uitextarea(gl, ...
                'Value', {''}, ...
                'Editable', 'off', ...
                'FontSize', 14, ...
                'FontName', selectedFont, ...
                'FontColor', [0.9 0.9 0.9], ...
                'BackgroundColor', [0.12 0.12 0.17]);
            app.TranscriptArea.Layout.Row = 4; app.TranscriptArea.Layout.Column = [1 8];
            
            % Row 5: Status bar
            statusBar = uilabel(gl, ...
                'Text', sprintf('Live Transcription v1.0 | %s | %s', ...
                    app.Config.Language, app.Config.DefaultProvider), ...
                'FontSize', 11, ...
                'FontColor', [0.5 0.5 0.5]);
            statusBar.Layout.Row = 5; statusBar.Layout.Column = [1 8];
        end
        
        function initComponents(app)
            app.MicCapture = MicrophoneCapture(app.Config);
            app.Chunker = Chunker(app.Config);
            app.CaptionBuf = CaptionBuffer();
            
            % Enumerate microphone devices
            try
                info = audiodevinfo();
                if isfield(info, 'input') && ~isempty(info.input)
                    deviceNames = {info.input.Name};
                    app.DeviceDropDown.Items = ['Default', deviceNames];
                end
            catch
            end
            
            % Load provider (can be slow for Whisper model download)
            app.StartBtn.Enable = 'off';
            app.StatusLabel.Text = 'Loading model...';
            app.StatusLamp.Color = [0.9 0.7 0.1];
            drawnow;
            app.setProvider(app.ProviderDropDown.Value);
            app.StartBtn.Enable = 'on';
            app.StatusLabel.Text = 'Ready';
            app.StatusLamp.Color = [0.5 0.5 0.5];
        end
        
        function setProvider(app, providerName)
            switch providerName
                case 'Whisper (MATLAB)'
                    app.Provider = WhisperMatlabProvider(app.Config);
                case 'Whisper (Python)'
                    app.Provider = WhisperPythonProvider(app.Config);
                case 'HuggingFace'
                    app.Provider = HuggingFaceProvider(app.Config);
                case 'Google Cloud'
                    app.Provider = GoogleSpeechProvider(app.Config);
            end
        end
        
        function onLanguageChanged(app)
            langName = app.LanguageDropDown.Value;
            lang = LanguageRegistry.findByName(langName);
            app.Config.Language = string(lang.name);
            app.Config.LanguageCode = string(lang.code);
            app.Config.GoogleLanguageCode = string(lang.googleCode);
            
            % Update font for new script
            selectedFont = FontHelper.selectFont(lang.script);
            app.CaptionLabel.FontName = selectedFont;
            app.TranscriptArea.FontName = selectedFont;
            
            % Reload provider with new language
            app.StatusLabel.Text = 'Switching language...';
            app.StatusLamp.Color = [0.9 0.7 0.1];
            drawnow;
            app.setProvider(app.ProviderDropDown.Value);
            app.StatusLabel.Text = sprintf('Ready (%s)', langName);
            app.StatusLamp.Color = [0.5 0.5 0.5];
            
            fprintf('[App] Language changed to %s (%s)\n', lang.name, lang.code);
        end
        
        function onStart(app)
            if app.IsRunning
                return;
            end
            app.IsRunning = true;
            app.StartBtn.Enable = 'off';
            app.StopBtn.Enable = 'on';
            app.StatusLamp.Color = [0.2 0.8 0.2];
            app.StatusLabel.Text = 'Listening...';
            
            app.MicCapture.start();
            
            app.CaptureTimer = timer('ExecutionMode', 'fixedSpacing', ...
                'Period', 0.1, ...
                'TimerFcn', @(~,~) app.captureLoop(), ...
                'ErrorFcn', @(~,e) fprintf('[CaptureTimer ERROR] %s\n', e.Data.message));
            start(app.CaptureTimer);
            
            app.TranscribeTimer = timer('ExecutionMode', 'fixedSpacing', ...
                'Period', 0.2, ...
                'TimerFcn', @(~,~) app.transcribeLoop(), ...
                'ErrorFcn', @(~,e) fprintf('[TranscribeTimer ERROR] %s\n', e.Data.message));
            start(app.TranscribeTimer);
            fprintf('[App] Timers started. CaptureTimer running=%s, TranscribeTimer running=%s\n', ...
                app.CaptureTimer.Running, app.TranscribeTimer.Running);
        end
        
        function onStop(app)
            app.IsRunning = false;
            app.ChunkQueue = {};
            app.TranscribeStartTime = [];
            app.StartBtn.Enable = 'on';
            app.StopBtn.Enable = 'off';
            app.StatusLamp.Color = [0.5 0.5 0.5];
            app.StatusLabel.Text = 'Stopped';
            
            if ~isempty(app.CaptureTimer) && isvalid(app.CaptureTimer)
                stop(app.CaptureTimer);
                delete(app.CaptureTimer);
            end
            if ~isempty(app.TranscribeTimer) && isvalid(app.TranscribeTimer)
                stop(app.TranscribeTimer);
                delete(app.TranscribeTimer);
            end
            if ~isempty(app.TranscribeFuture) && isvalid(app.TranscribeFuture)
                cancel(app.TranscribeFuture);
                app.TranscribeFuture = [];
            end
            app.MicCapture.stop();
            app.Chunker.reset();
        end
        
        function onClear(app)
            app.CaptionLabel.Text = '';
            app.TranscriptArea.Value = {''};
            app.CaptionBuf.clear();
        end
        
        function onSave(app)
            [file, path] = uiputfile('*.txt', 'Save Transcript', 'transcript.txt');
            if file ~= 0
                fullPath = fullfile(path, file);
                Utf8File.write(fullPath, app.CaptionBuf.getFullTranscript());
                app.StatusLabel.Text = ['Saved: ' file];
            end
        end
        
        function onProviderChanged(app)
            app.StatusLabel.Text = 'Switching provider...';
            app.StatusLamp.Color = [0.9 0.7 0.1];
            drawnow;
            app.setProvider(app.ProviderDropDown.Value);
            app.StatusLabel.Text = 'Ready';
            app.StatusLamp.Color = [0.5 0.5 0.5];
        end
        
        function captureLoop(app)
            if ~app.IsRunning
                return;
            end
            
            try
                [audioFrame, isValid] = app.MicCapture.readFrame();
                if ~isValid
                    return;
                end
                
                rmsLevel = sqrt(mean(audioFrame.^2));
                app.LevelGauge.Value = min(rmsLevel * 5, 1);
                
                persistent frameCount;
                if isempty(frameCount), frameCount = 0; end
                frameCount = frameCount + 1;
                if mod(frameCount, 50) == 1
                    fprintf('[Capture] frame=%d rms=%.5f noiseFloor=%.5f threshold=%.1f speechDetected=%d bufLen=%.1fs queueLen=%d\n', ...
                        frameCount, rmsLevel, app.Chunker.VAD.NoiseFloor, ...
                        app.Chunker.VAD.Threshold, app.Chunker.SpeechDetected, ...
                        length(app.Chunker.Buffer)/app.Config.SampleRate, ...
                        numel(app.ChunkQueue));
                end
                
                chunk = app.Chunker.addFrame(audioFrame);
                
                if ~isempty(chunk)
                    chunkDur = length(chunk) / app.Config.SampleRate;
                    wavPath = TempAudioWriter.write(chunk, app.Config.SampleRate);
                    app.ChunkQueue{end+1} = wavPath;
                    fprintf('[Capture] CHUNK emitted: %.1fs, queue=%d\n', chunkDur, numel(app.ChunkQueue));
                end
                
                app.updateStatus();
            catch ex
                warning('LiveTranscriptionApp:CaptureError', '%s', ex.message);
            end
        end
        
        function transcribeLoop(app)
            if ~app.IsRunning
                return;
            end
            
            try
                app.transcribeLoopImpl();
            catch ex
                fprintf('[TranscribeLoop] Error: %s\n', ex.message);
            end
        end
        
        function transcribeLoopImpl(app)
            if ~isempty(app.TranscribeFuture) && isvalid(app.TranscribeFuture)
                if strcmp(app.TranscribeFuture.State, 'finished')
                    try
                        [status, output] = fetchOutputs(app.TranscribeFuture);
                        if status == 0 && strlength(output) > 0
                            data = jsondecode(output);
                            if isfield(data, 'text') && strlength(data.text) > 0
                                app.showCaption(data.text);
                            end
                        end
                    catch ex
                        warning('LiveTranscriptionApp:TranscribeError', '%s', ex.message);
                    end
                    TempAudioWriter.cleanup(app.TranscribeWavPath);
                    app.TranscribeFuture = [];
                    app.TranscribeWavPath = "";
                    app.TranscribeStartTime = [];
                    app.StatusLabel.Text = 'Listening...';
                    app.StatusLamp.Color = [0.2 0.8 0.2];
                else
                    return;
                end
            end
            
            if isempty(app.ChunkQueue)
                return;
            end
            
            wavPath = app.ChunkQueue{1};
            app.ChunkQueue(1) = [];
            app.TranscribeStartTime = tic;
            app.DotCount = 0;
            app.StatusLamp.Color = [0.9 0.7 0.1];
            
            if isa(app.Provider, 'WhisperPythonProvider') || ...
                    isa(app.Provider, 'HuggingFaceProvider')
                app.TranscribeWavPath = wavPath;
                cmd = app.Provider.buildCommand(wavPath);
                app.TranscribeFuture = parfeval(backgroundPool, ...
                    @system, 2, cmd);
            else
                app.transcribeSynchronous(wavPath);
            end
        end
        
        function transcribeSynchronous(app, wavPath)
            try
                fprintf('[Transcribe] Starting speech2text (%s)...\n', app.Config.Language);
                result = app.Provider.transcribeChunk(wavPath, struct());
                elapsed = toc(app.TranscribeStartTime);
                fprintf('[Transcribe] Done in %.1fs, text="%s"\n', elapsed, result.text);
                TempAudioWriter.cleanup(wavPath);
                
                if ~app.IsRunning
                    app.TranscribeStartTime = [];
                    return;
                end
                if strlength(result.text) > 0
                    app.showCaption(result.text);
                end
                app.TranscribeStartTime = [];
                drawnow;
                
                app.drainAudioBuffer();
                
                app.StatusLabel.Text = 'Listening...';
                app.StatusLamp.Color = [0.2 0.8 0.2];
            catch ex
                fprintf('[Transcribe] Error: %s\n', ex.message);
                TempAudioWriter.cleanup(wavPath);
                app.StatusLabel.Text = ['Error: ' ex.message];
                app.TranscribeStartTime = [];
            end
        end
        
        function drainAudioBuffer(app)
            drainedFrames = 0;
            frameDuration = app.Config.FrameSize / app.Config.SampleRate;
            while app.IsRunning
                tRead = tic;
                [frame, isValid] = app.MicCapture.readFrame();
                readTime = toc(tRead);
                if ~isValid
                    break;
                end
                
                if readTime > frameDuration * 0.8
                    app.Chunker.addFrame(frame);
                    drainedFrames = drainedFrames + 1;
                    break;
                end
                
                chunk = app.Chunker.addFrame(frame);
                drainedFrames = drainedFrames + 1;
                
                if ~isempty(chunk)
                    chunkDur = length(chunk) / app.Config.SampleRate;
                    wavPath = TempAudioWriter.write(chunk, app.Config.SampleRate);
                    app.ChunkQueue{end+1} = wavPath;
                    fprintf('[Drain] Chunk emitted: %.1fs, queue=%d\n', chunkDur, numel(app.ChunkQueue));
                end
            end
            if drainedFrames > 0
                fprintf('[Drain] Recovered %d frames (%.1fs of audio)\n', ...
                    drainedFrames, drainedFrames * app.Config.FrameSize / app.Config.SampleRate);
            end
        end
        
        function updateStatus(app)
            if ~isempty(app.TranscribeStartTime)
                elapsed = toc(app.TranscribeStartTime);
                app.DotCount = app.DotCount + 1;
                dots = repmat('.', 1, mod(app.DotCount, 4));
                app.StatusLabel.Text = sprintf('Transcribing%s %ds', dots, round(elapsed));
            elseif ~isempty(app.ChunkQueue)
                app.StatusLabel.Text = sprintf('Queued: %d chunks', numel(app.ChunkQueue));
            elseif app.Chunker.SpeechDetected
                app.StatusLabel.Text = 'Hearing speech...';
                app.StatusLamp.Color = [0.2 0.8 0.2];
            end
        end
        
        function showCaption(app, text)
            app.CaptionBuf.addText(text);
            app.CaptionLabel.Text = text;
            app.TranscriptArea.Value = app.CaptionBuf.getLines();
        end
        
        function onClose(app)
            if app.IsRunning
                app.onStop();
            end
            delete(app.Fig);
        end
        
        function delete(app)
            if app.IsRunning
                app.onStop();
            end
        end
    end
end
