function setup_paths()
%SETUP_PATHS Add Live Transcription source directories to MATLAB path
%
%   setup_paths() adds all source directories to the MATLAB path so
%   that the application classes can be found.
%
%   Run this once per MATLAB session before using the application.

    projectRoot = fileparts(mfilename('fullpath'));
    
    addpath(fullfile(projectRoot, 'src', 'app'));
    addpath(fullfile(projectRoot, 'src', 'audio'));
    addpath(fullfile(projectRoot, 'src', 'providers'));
    addpath(fullfile(projectRoot, 'src', 'captions'));
    addpath(fullfile(projectRoot, 'src', 'ui'));
    addpath(fullfile(projectRoot, 'src', 'utils'));
    addpath(fullfile(projectRoot, 'tests'));
    addpath(fullfile(projectRoot, 'demo'));
    
    % Add Whisper medium model if available
    whisperModelDir = fullfile(getenv('USERPROFILE'), ...
        'OneDrive - MathWorks', 'Documents', 'whisperMediumDownload', 'whisper-medium');
    if isfolder(whisperModelDir)
        addpath(whisperModelDir);
        fprintf('Whisper medium model path added.\n');
    end
    
    fprintf('Live Transcription paths added.\n');
    fprintf('  Run "run_demo" to start the application.\n');
    fprintf('  Run "runtests(''tests'')" to run tests.\n');
end
