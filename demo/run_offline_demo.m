function run_offline_demo(wavFile, language)
%RUN_OFFLINE_DEMO Run transcription on a pre-recorded WAV file
%
%   run_offline_demo(wavFile) transcribes a pre-recorded WAV file.
%   run_offline_demo(wavFile, language) uses the specified language.
%
%   Example:
%       run_offline_demo('test_audio.wav', 'Armenian')

    if nargin < 2
        language = 'English';
    end
    if nargin < 1
        fprintf('No WAV file specified. Generating synthetic test audio...\n');
        wavFile = generateTestAudio();
    end
    
    % Add source directories to path
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(projectRoot, 'src')));
    
    fprintf('=== Live Transcription - Offline Demo ===\n');
    fprintf('Input file: %s\n', wavFile);
    fprintf('Language: %s\n\n', language);
    
    % Configure language
    cfg = Config();
    lang = LanguageRegistry.findByName(language);
    cfg.Language = string(lang.name);
    cfg.LanguageCode = string(lang.code);
    cfg.GoogleLanguageCode = string(lang.googleCode);
    
    % Read audio file
    [audio, fs] = audioread(wavFile);
    if size(audio, 2) > 1
        audio = mean(audio, 2);
    end
    
    if fs ~= cfg.SampleRate
        audio = resample(audio, cfg.SampleRate, fs);
        fs = cfg.SampleRate;
    end
    
    fprintf('Audio duration: %.1f seconds\n', length(audio) / fs);
    fprintf('Sample rate: %d Hz\n\n', fs);
    
    % Create provider
    provider = WhisperPythonProvider(cfg);
    
    if ~provider.isAvailable()
        fprintf('[WARN] Whisper not available.\n');
        return;
    end
    
    % Chunk and transcribe
    chunkDuration = cfg.TargetChunkDuration;
    chunkSamples = round(chunkDuration * fs);
    overlapSamples = round(cfg.ChunkOverlap * fs);
    
    selectedFont = FontHelper.selectFont(lang.script);
    
    fig = uifigure('Name', sprintf('Transcription - %s', language), ...
        'Position', [200 200 700 400], ...
        'Color', [0.1 0.1 0.15]);
    
    captionLabel = uilabel(fig, ...
        'Text', 'Processing...', ...
        'Position', [20 200 660 150], ...
        'FontSize', 28, ...
        'FontName', selectedFont, ...
        'FontColor', [1 1 1], ...
        'BackgroundColor', [0.15 0.15 0.2], ...
        'HorizontalAlignment', 'center', ...
        'WordWrap', 'on');
    
    transcriptArea = uitextarea(fig, ...
        'Position', [20 20 660 160], ...
        'Editable', 'off', ...
        'FontSize', 14, ...
        'FontName', selectedFont, ...
        'FontColor', [0.9 0.9 0.9], ...
        'BackgroundColor', [0.12 0.12 0.17]);
    
    allText = {};
    startIdx = 1;
    numChunks = ceil(length(audio) / (chunkSamples - overlapSamples));
    
    for i = 1:numChunks
        endIdx = min(startIdx + chunkSamples - 1, length(audio));
        chunk = audio(startIdx:endIdx);
        
        if length(chunk) < fs * 0.5
            break;
        end
        
        wavPath = TempAudioWriter.write(chunk, fs);
        result = provider.transcribeChunk(wavPath, struct());
        TempAudioWriter.cleanup(wavPath);
        
        if strlength(result.text) > 0
            captionLabel.Text = result.text;
            allText{end+1} = char(result.text); %#ok<AGROW>
            transcriptArea.Value = allText;
            fprintf('  [%.1f-%.1fs] %s\n', ...
                (startIdx-1)/fs, endIdx/fs, result.text);
        end
        
        startIdx = endIdx - overlapSamples + 1;
        drawnow;
    end
    
    fprintf('\nTranscription complete.\n');
end

function wavFile = generateTestAudio()
    fs = 16000;
    duration = 3;
    audio = randn(fs * duration, 1) * 0.001;
    wavFile = fullfile(tempdir, 'test_audio.wav');
    audiowrite(wavFile, audio, fs);
end
