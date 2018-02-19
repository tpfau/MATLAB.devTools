function checkSystem(callerName, repoName, printLevel)
% Checks the configuration of the system (installation of git and curl)
%
% USAGE:
%
%    checkSystem(callerName, repoName)
%
% INPUT:
%   callerName:     Name of the function calling `checkSystem()`
%   repoName:       Name of the repository for which the devTools shall
%                   be configured (default: `opencobra/cobratoolbox`)
%   printLevel:     Level of verbose
%
% .. Author:
%      - Laurent Heirendt


    global gitConf
    global gitCmd
    global DEFAULTREPONAME

    % set the repoName if not given
    if ~exist('repoName', 'var')
        repoName = DEFAULTREPONAME;
    end

    if ~exist('printLevel', 'var') && isempty(gitConf)
        printLevel = 0;
    end

    % if a configuration has already been set, configure the devTools accordingly
    if isempty(gitConf)
        % default configuration of the devTools is the opencobra/cobratoolbox repository
        confDevTools(repoName, 'printLevel', printLevel);
    else
        confDevTools(gitConf.nickName, 'remoteRepoURL', gitConf.remoteRepoURL, 'launcher', gitConf.launcher, ...
                     'printLevel', gitConf.printLevel);
    end

    % set the callerName
    if nargin < 3
        callerName = '';
    else
        callerName = ['(caller: ', callerName, ')'];
    end

    % add the public key from github.com to the known hosts
    addKeyToKnownHosts();

    % check if git is properly installed
    [status_gitVersion, result_gitVersion] = system('git --version');

    if status_gitVersion == 0 && ~isempty(strfind(result_gitVersion, 'git version'))
        printMsg(mfilename, [callerName, ' git is properly installed.']);
    else
        fprintf(result_gitVersion);
        error([gitCmd.lead, ' [', mfilename, ']', callerName, ' git is not installed. Please follow the guidelines how to install git.']);
    end

    % check if curl is properly installed
    [status_curl, result_curl] = system('curl --version');

    if status_curl == 0 && ~isempty(strfind(result_curl, 'curl')) && ~isempty(strfind(result_curl, 'http'))
        printMsg(mfilename, [callerName, ' curl is properly installed.']);
    else
        fprintf(result_curl);
        error([gitCmd.lead, ' [', mfilename, ']', callerName, ' curl is not installed. Please follow the guidelines how to install curl.']);
    end
end
