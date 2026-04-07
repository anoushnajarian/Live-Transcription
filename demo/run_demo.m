function run_demo()
%RUN_DEMO Launch the Live Transcription application
%
%   run_demo() starts the Live Transcription application with
%   default settings. Ensure you have:
%     - Audio Toolbox installed
%     - Python 3.10+ with faster-whisper (for Whisper provider)
%
%   Example:
%       run_demo()
%
%   See also: LiveTranscriptionApp, Config

    fprintf('=== Live Transcription Demo ===\n');
    fprintf('Starting application...\n\n');
    
    % Add source directories to path
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(projectRoot, 'src')));
    
    % Check prerequisites
    checkPrerequisites();
    
    % Create config
    cfg = Config();
    
    % Check for config file
    configFile = fullfile(projectRoot, 'config.json');
    if isfile(configFile)
        fprintf('Loading config from: %s\n', configFile);
        cfg.loadFromFile(configFile);
    end
    
    % Launch app
    fprintf('Launching Live Transcription...\n');
    fprintf('  Language: %s (%s)\n', cfg.Language, cfg.LanguageCode);
    fprintf('  Sample Rate: %d Hz\n', cfg.SampleRate);
    fprintf('  Provider: %s\n', cfg.DefaultProvider);
    fprintf('  Whisper Model: %s\n', cfg.WhisperModel);
    fprintf('\n');
    
    app = LiveTranscriptionApp(cfg); %#ok<NASGU>
    
    fprintf('Application started. Use the GUI controls to begin.\n');
    fprintf('  - Select a language from the dropdown\n');
    fprintf('  - Click "Start" to begin listening\n');
    fprintf('  - Click "Stop" to pause\n');
    fprintf('  - Click "Save Transcript" to export\n');
    fprintf('\n');
end

function checkPrerequisites()
    % Check Audio Toolbox
    hasAudioToolbox = ~isempty(ver('audio'));
    if hasAudioToolbox
        fprintf('[OK] Audio Toolbox detected\n');
    else
        fprintf('[WARN] Audio Toolbox not found. Using audiorecorder fallback.\n');
    end
    
    % Check MATLAB Python bridge
    try
        pe = pyenv;
        if pe.Version ~= ""
            fprintf('[OK] Python detected via pyenv: %s\n', pe.Version);
        else
            fprintf('[WARN] No Python configured in MATLAB (pyenv).\n');
        end
    catch
        fprintf('[WARN] Could not check Python.\n');
    end
    
    % Check font availability
    fontName = FontHelper.selectFont();
    fprintf('[OK] Default font: %s\n', fontName);
    
    % Show supported languages
    fprintf('[OK] Supported languages: %s\n', strjoin(LanguageRegistry.displayNames(), ', '));
    
    fprintf('\n');
end
