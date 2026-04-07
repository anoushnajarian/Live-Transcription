classdef WhisperPythonProvider < STTProvider
    properties
        Config
        ModelSize = "small"
        PythonReady = false
    end
    
    methods
        function obj = WhisperPythonProvider(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
            obj.ModelSize = config.WhisperModel;
            obj.checkPython();
        end
        
        function tf = isAvailable(obj)
            tf = obj.PythonReady;
        end
        
        function result = transcribeChunk(obj, wavPath, options)
            if nargin < 3
                options = struct();
            end
            
            lang = char(obj.Config.LanguageCode);
            if isfield(options, 'language')
                lang = options.language;
            end
            
            try
                pyScript = obj.getPythonScript();
                cmd = sprintf('python "%s" "%s" --model %s --language %s', ...
                    pyScript, wavPath, obj.ModelSize, lang);
                
                [status, output] = system(cmd);
                
                if status ~= 0
                    warning('WhisperPythonProvider:TranscribeFailed', ...
                        'Whisper transcription failed: %s', output);
                    result = obj.makeResult('', false);
                    return;
                end
                
                data = jsondecode(output);
                result = obj.makeResult(data.text, true, ...
                    data.start_time, data.end_time, data);
                
            catch ex
                warning('WhisperPythonProvider:Error', '%s', ex.message);
                result = obj.makeResult('', false);
            end
        end
        
        function cmd = buildCommand(obj, wavPath)
            pyScript = obj.getPythonScript();
            pythonExe = WhisperPythonProvider.findPython();
            lang = char(obj.Config.LanguageCode);
            cmd = sprintf('"%s" "%s" "%s" --model %s --language %s', ...
                pythonExe, pyScript, wavPath, obj.ModelSize, lang);
        end
    end
    
    methods (Access = private)
        function checkPython(obj)
            try
                [status, ~] = system('python --version');
                obj.PythonReady = (status == 0);
            catch
                obj.PythonReady = false;
            end
        end
        
        function scriptPath = getPythonScript(obj) %#ok<MANU>
            thisDir = fileparts(mfilename('fullpath'));
            scriptPath = fullfile(thisDir, '..', '..', 'python', 'whisper_transcribe.py');
        end
    end
    
    methods (Static, Access = private)
        function exe = findPython()
            try
                pe = pyenv;
                if pe.Executable ~= ""
                    exe = char(pe.Executable);
                    exe = strrep(exe, 'pythonw.exe', 'python.exe');
                    return;
                end
            catch
            end
            candidates = { ...
                'C:\Program Files\Python313\python.exe', ...
                'C:\Program Files\Python312\python.exe', ...
                'C:\Program Files\Python311\python.exe', ...
                'C:\Program Files\Python310\python.exe'};
            for i = 1:numel(candidates)
                if isfile(candidates{i})
                    exe = candidates{i};
                    return;
                end
            end
            exe = 'python';
        end
    end
end
