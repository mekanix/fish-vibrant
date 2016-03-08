set -g _vbr_timestamp 0
set -g _vbr_pwd       ''
set -g _vbr_branch    '-'
set -g _vbr_up        0
set -g _vbr_down      0
set -g _vbr_status    ''



set cyan    (set_color cyan)
set yellow  (set_color yellow)
set red     (set_color red)
set blue    (set_color blue)
set green   (set_color green)
set normal  (set_color normal)
set magenta (set_color magenta)
set white   (set_color white)
set gray    (set_color 666)



function _vbr_update # <repo>
    set -l now (command date +%s)
    set -l elapsed (math $now - $_vbr_timestamp)

    if test $_vbr_pwd != $argv[1] -o $elapsed -gt 5
        set -g _vbr_pwd       $argv[1]
        set -g _vbr_timestamp $now
        pushd $argv[1]
        set -g _vbr_branch (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
        set -l remotes  (command git remote | wc -l | bc)
        if test $remotes -gt 0
            set -g _vbr_up     (command git rev-list --left-only --count HEAD...@'{u}' ^ /dev/null)
            set -g _vbr_down   (command git rev-list --right-only --count HEAD...@'{u}' ^ /dev/null)
        else
            set -g _vbr_up 0
            set -g _vbr_down 0
        end
        git status --porcelain --ignore-submodules 2> /dev/null | read -z _vbr_status
        popd
    end

    if test $_vbr_pwd != $argv[1] -o $elapsed -gt 600
        pushd $argv[1]
        git -c gc.auto=0 fetch > /dev/null ^ /dev/null &
        popd
    end
end



function _vbr_prompt_login
    # Display username and hostname if logged in as root, in sudo or ssh session
    if test \( (id -u) -eq 0 -o $SUDO_USER \) -o $SSH_CONNECTION
        set -l host (command hostname | command cut -f 1 -d '.')
        echo -ns $yellow $USER $gray '@' $cyan $host ' ' $normal
    end
end

# Print pwd or full path
function _vbr_prompt_path; echo -ns (pwd | sed "s:^$HOME:~:"); end

# Print Git branch
function _vbr_prompt_branch; echo -ns $blue ' ' $_vbr_branch $normal; end

function _vbr_prompt_files
    set untracked (echo $_vbr_status | grep '^\?'     | wc -l | bc)
    set unstaged  (echo $_vbr_status | grep '^.[A-Z]' | wc -l | bc)
    set staged    (echo $_vbr_status | grep '^[A-Z]'  | wc -l | bc)

    echo -ns ' '
    if test $untracked -gt 0; echo -ns $red    '*' $untracked $normal; end
    if test $unstaged -gt 0;  echo -ns $red    '±' $unstaged $normal;  end
    if test $staged -gt 0;    echo -ns $yellow '⇈' $staged $normal;    end
end

function _vbr_prompt_remote
    if [ $_vbr_up -eq 0 -a $_vbr_down -eq 0 ]; return 0; end
    echo -ns ' '
    if [ $_vbr_up -gt 0 ];   echo -ns $yellow '⇡' $_vbr_up   $normal; end
    if [ $_vbr_down -gt 0 ]; echo -ns $red    '⇣' $_vbr_down $normal; end
end



# [user host] <path> [branch [files]] <prompt>
function fish_prompt
    set -l _status $status

    _vbr_prompt_login
    _vbr_prompt_path

    # Show git branch and status
    set -l repo (command git rev-parse --show-toplevel ^/dev/null)
    if [ $repo ]
        _vbr_update $repo

        _vbr_prompt_files
        _vbr_prompt_branch
        _vbr_prompt_remote
    end

    if [ $_status != 0 ]; echo -es $red   ' ♦ ' $normal
    else;                 echo -es $green ' ♦ ' $normal; end
end
