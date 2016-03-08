set -g _vbr_timestamp 0
set -g _vbr_pwd       ''



function _vbr_fetch # <repo>
    set -l now (command date +%s)
    set -l elapsed (math $now - $_vbr_timestamp)

    if test $_vbr_pwd != $argv[1] -o $elapsed -gt 600
        set -g _vbr_timestamp $now
        set -g _vbr_pwd       $argv[1]
        pushd $argv[1]
        git -c gc.auto=0 fetch > /dev/null ^ /dev/null &
        popd
    end
end



# [user host] <path> [branch [files]] <prompt>
function fish_prompt
    set -l _status $status

    # Colors
    set -l cyan    (set_color cyan)
    set -l yellow  (set_color yellow)
    set -l red     (set_color red)
    set -l blue    (set_color blue)
    set -l green   (set_color green)
    set -l normal  (set_color normal)
    set -l magenta (set_color magenta)
    set -l white   (set_color white)
    set -l gray    (set_color 666)


    # User Information
    # Display username and hostname if logged in as root, in sudo or ssh session
    if test \( (id -u) -eq 0 -o $SUDO_USER \) -o $SSH_CONNECTION
        set -l host (command hostname | command cut -f 1 -d '.')
        echo -ns $yellow $USER $gray '@' $cyan $host ' ' $normal
    end


    # Path
    echo -ns (pwd | sed "s:^$HOME:~:")


    # Git
    set -l repo (command git rev-parse --show-toplevel ^/dev/null)
    if [ $repo ]
        _vbr_fetch $repo


        # Git – Read Data
        pushd $repo

        set -l branch (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
        if [ -z $branch ]
            set branch (command git rev-parse --short HEAD ^ /dev/null)
        end

        set -l up 0
        set -l down 0
        if test (command git remote | wc -l | bc) -gt 0
            set up   (command git rev-list --left-only --count HEAD...@'{u}' ^/dev/null | bc)
            set down (command git rev-list --right-only --count HEAD...@'{u}' ^/dev/null | bc)
        end

        git status --porcelain --ignore-submodules -b 2> /dev/null | read -z files
        #echo -e "   \n" | read -z files

        popd


        # Git – Untracked, Unstaged & Staged File
        set untracked (echo $files | grep '^\?'     | wc -l | bc)
        set unstaged  (echo $files | grep '^[^#][A-Z]' | wc -l | bc)
        set staged    (echo $files | grep '^[A-Z]'  | wc -l | bc)

        if [ $untracked -gt 0 -o $unstaged -gt 0 -o $staged -gt 0 ]; echo -ns ' '; end
        if test $untracked -gt 0; echo -ns $red    '*' $untracked $normal; end
        if test $unstaged -gt 0;  echo -ns $red    '±' $unstaged $normal;  end
        if test $staged -gt 0;    echo -ns $yellow '⇈' $staged $normal;    end


        # Git – Branch
        echo -ns $blue ' ' $branch $normal


        # Git – Unpulled & Unpushed Commits
        if [ $up -gt 0 -o $down -gt 0 ]; echo -ns ' '; end
        if [ $up -gt 0 ];   echo -ns $yellow '⇡' $up   $normal; end
        if [ $down -gt 0 ]; echo -ns $red    '⇣' $down $normal; end

    end


    # Prompt Symbol
    if [ $_status != 0 ]; echo -es $red   ' ♦ ' $normal
    else;                 echo -es $green ' ♦ ' $normal; end
end
