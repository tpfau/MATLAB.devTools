if ~isempty(strfind(getenv('HOME'), 'jenkins'))
    % do not change the paths below
    addpath(genpath('/home/sbg-jenkins/MOcov'));
    addpath(genpath('/home/sbg-jenkins/jsonlab'));

    % change the directory on the CI server
    cd([pwd, '/../'])
end

% include the root folder and all subfolders
addpath(genpath(pwd))

exit_code = 0;

% enable profiler
profile on;

if ~isempty(strfind(getenv('HOME'), 'jenkins'))
    % check the code quality
    listFiles = rdir(['./src', '/**/*.m']);

    % count the number of failed code quality checks per file
    nMsgs = 0;
    nCodeLines = 0;
    nEmptyLines = 0;
    nCommentLines = 0;

    for i = 1:length(listFiles)
        nMsgs = nMsgs + length(checkcode(listFiles(i).name));

        fid = fopen(listFiles(i).name);
        res = {};
        while ~feof(fid)
            lineOfFile = strtrim(fgetl(fid));
            if length(lineOfFile) > 0 && length(strfind(lineOfFile(1), '%')) ~= 1  ...
               && length(strfind(lineOfFile, 'end')) ~= 1 && length(strfind(lineOfFile, 'otherwise')) ~= 1 ...
               && length(strfind(lineOfFile, 'switch')) ~= 1 && length(strfind(lineOfFile, 'else')) ~= 1  ...
               && length(strfind(lineOfFile, 'case')) ~= 1 && length(strfind(lineOfFile, 'function')) ~= 1

                res{end+1, 1} = lineOfFile;

            elseif length(lineOfFile) == 0
                nEmptyLines = nEmptyLines + 1;

            elseif length(strfind(lineOfFile(1), '%')) == 1
                nCommentLines = nCommentLines + 1;
            end
        end
        fclose(fid);
        nCodeLines = nCodeLines + numel(res);
    end

    % average number of messages per codeLines
    avMsgsPerc = floor(nMsgs / nCodeLines * 100 );

    grades = {'A', 'B', 'C', 'D', 'E', 'F'};
    intervals = [0, 3;
                 3, 6;
                 6, 9;
                 9, 12;
                 12, 15;
                 15, 100];

    grade = 'F';
    for i = 1:length(intervals)
        if avMsgsPerc >= intervals(i, 1) && avMsgsPerc < intervals(i, 2)
            grade = grades{i};
            fprintf(' >> The code grade is %s.\n', grade)
        end
    end

    % set the new badge
    system(['cp /mnt/prince-data/jenkins/userContent/codegrade-', grade, '.svg /mnt/prince-data/jenkins/userContent/codegrade-MATLABdevTools.svg']);

    % secure copy the badge from the slave
    system('scp -P 8022 /mnt/prince-data/jenkins/userContent/codegrade-MATLABdevTools.svg jenkins@prince-server.lcsb.uni.lux:/var/lib/jenkins/userContent');

end

try
    % run the tests in the subfolder recursively
    result = runtests('./test', 'Recursively', true);

    % write coverage based on profile('info')
    mocov('-cover','./src',...
          '-profile_info',...
          '-cover_json_file','coverage.json',...
          '-cover_method', 'profile');

    sumFailed = 0;
    sumIncomplete = 0;

    for i = 1:size(result,2)
        sumFailed = sumFailed + result(i).Failed;
        sumIncomplete = sumIncomplete + result(i).Incomplete;
    end

    % load the coverage file
    data = loadjson('coverage.json', 'SimplifyCell', 1);

    sf = data.source_files;
    clFiles = zeros(length(sf), 1);
    tlFiles = zeros(length(sf), 1);

    for i = 1:length(sf)
        clFiles(i) = nnz(sf(i).coverage);
        tlFiles(i) = length(sf(i).coverage);
    end

    % average the values for each file
    cl = sum(clFiles);
    tl = sum(tlFiles);

    % print out a summary table
    table(result)

    % print out the coverage as requested by gitlab
    fprintf('Covered Lines: %i, Total Lines: %i, Coverage: %f%%.\n', cl, tl, cl/tl * 100);

    if sumFailed > 0 || sumIncomplete > 0
        exit_code = 1;
    end

    % ensure that we ALWAYS call exit
    exit(exit_code);
catch
    exit(1);
end
