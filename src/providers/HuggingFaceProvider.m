classdef HuggingFaceProvider < STTProvider
    properties
        Config
        ModelName = ""
        PythonReady = false
    end
    
    methods
        function obj = HuggingFaceProvider(config)
            if nargin < 1
                config = Config();
            end
            obj.Config = config;
            
            % Use explicit model from config, or look up per-language default
            if strlength(config.HuggingFaceModel) > 0
                obj.ModelName = config.HuggingFaceModel;
            else
                lang = LanguageRegistry.findByName(config.Language);
                if strlength(string(lang.hfModel)) > 0
                    obj.ModelName = string(lang.hfModel);
                else
                    obj.ModelName = "openai/whisper-medium";
                end
            end
            
            obj.checkPython();
        end
        
        function tf = isAvailable(obj)
            tf = obj.PythonReady;
        end
        
        function result = transcribeChunk(obj, wavPath, options)
            if nargin < 3
                options = struct();
            end
            
            device = 'cpu';
            if isfield(options, 'device')
                device = options.device;
            end
            
            lang = char(obj.Config.LanguageCode);
            
            try
                pyScript = obj.getPythonScript();
                cmd = sprintf('python "%s" "%s" --model %s --language %s --device %s', ...
                    pyScript, wavPath, obj.ModelName, lang, device);
                
                [status, output] = system(cmd);
                
                if status ~= 0
                    warning('HuggingFaceProvider:TranscribeFailed', ...
                        'HuggingFace transcription failed: %s', output);
                    result = obj.makeResult('', false);
                    return;
                end
                
                data = jsondecode(output);
                result = obj.makeResult(data.text, true, ...
                    data.start_time, data.end_time, data);
                
            catch ex
                warning('HuggingFaceProvider:Error', '%s', ex.message);
                result = obj.makeResult('', false);
            end
        end
        
        function cmd = buildCommand(obj, wavPath)
            pyScript = obj.getPythonScript();
            pythonExe = HuggingFaceProvider.findPython();
            lang = char(obj.Config.LanguageCode);
            cmd = sprintf('"%s" "%s" "%s" --model %s --language %s', ...
                pythonExe, pyScript, wavPath, obj.ModelName, lang);
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
            scriptPath = fullfile(thisDir, '..', '..', 'python', 'hf_transcribe.py');
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
