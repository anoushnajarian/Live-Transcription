classdef Utf8File
    methods (Static)
        function write(filePath, text)
            fid = fopen(filePath, 'w', 'n', 'UTF-8');
            if fid == -1
                error('Utf8File:OpenFailed', 'Cannot open file: %s', filePath);
            end
            fprintf(fid, '%s', text);
            fclose(fid);
        end
        
        function text = read(filePath)
            fid = fopen(filePath, 'r', 'n', 'UTF-8');
            if fid == -1
                error('Utf8File:OpenFailed', 'Cannot open file: %s', filePath);
            end
            text = fread(fid, '*char')';
            fclose(fid);
        end
    end
end
