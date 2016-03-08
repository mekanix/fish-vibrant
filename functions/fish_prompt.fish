# name: Vibrant
# -----------------------
# Vibrant prompt for fish
# by Jannis R
# MIT License
# -----------------------


function _vibrant_timestamp; command date +%s; end


function _vibrant_cmd_duration
    set -l duration 0
    if [ $CMD_DURATION ]; set duration $CMD_DURATION; end

    set full_seconds (math "$duration / 1000")
    set second_parts (math "$duration % 1000 / 10")
    set seconds      (math "$full_seconds % 60")
    set minutes      (math "$full_seconds / 60 % 60")
    set hours        (math "$full_seconds / 60 / 60 % 24")
    set days         (math "$full_seconds / 60/ 60 /24")

    if [ $days -gt 0 ];    echo -ns $days 'd ';    end
    if [ $hours -gt 0 ];   echo -ns $hours 'h ';   end
    if [ $minutes -gt 0 ]; echo -ns $minutes 'm '; end

    if [ $full_seconds -ge 5 ]
        echo -s $seconds.$second_parts 's'
    end
end


function unique_async_job
    set -l job_unique_flag $argv[1]
    set -l callback_function $argv[2]
    set -l cmd $argv[3]

    if set -q $job_unique_flag; return 0; end

    set -g $job_unique_flag
    set -l async_job_result _async_job_result_(random)

    fish -c "set -U $async_job_result (eval $cmd)" &
    set -l pid (jobs -l -p)

    function _async_job_$pid -p $pid -V pid -V async_job_result -V callback_function -V job_unique_flag
        set -e $job_unique_flag
        eval $callback_function $$async_job_result
        functions -e _async_job_$pid
        set -e $async_job_result
    end
end


function _vibrant_async_git_fetch
    if set -q _vibrant_git_async_fetch_running; return 0; end

    set -l working_tree $argv[1]

    pushd $working_tree
    if [ ! (command git rev-parse --abbrev-ref @'{u}' ^ /dev/null) ]
        popd
    return 0
    end

    set -l git_fetch_required no
    if [ ! -e .git/FETCH_HEAD ]
        set git_fetch_required yes
    else
        set -l last_fetch_timestamp (command stat -f "%m" .git/FETCH_HEAD)
        set -l current_timestamp (_vibrant_timestamp)
        set -l time_since_last_fetch (math "$current_timestamp - $last_fetch_timestamp")
        if [ $time_since_last_fetch -gt 1800 ]
            set git_fetch_required yes
        end
    end

    if [ $git_fetch_required = no ]; popd; return 0; end

    set -l cmd "env GIT_TERMINAL_PROMPT=0 command git -c gc.auto=0 fetch > /dev/null ^ /dev/null"
    unique_async_job "_vibrant_async_git_fetch_running" "kill -WINCH %self" $cmd

    popd
end


function _vibrant_git_arrows
    set -l working_tree $argv[1]

    pushd $working_tree
    if [ ! (command git rev-parse --abbrev-ref @'{u}' ^ /dev/null) ]
        popd
        return 0
    end

    set -l left (command git rev-list --left-only --count HEAD...@'{u}' ^ /dev/null)
    set -l right (command git rev-list --right-only --count HEAD...@'{u}' ^ /dev/null)

    popd

    if [ $left -eq 0 -a $right -eq 0 ]; return 0; end

    if [ $left -gt 0 ];  echo -n '⇡'; end
    if [ $right -gt 0 ]; echo -n '⇣'; end
    echo -en "\n"
end


function _vibrant_dirty_mark_completion
    set -g _vibrant_git_last_dirty_check_timestamp (_vibrant_timestamp)
    set -g _vibrant_git_dirty_files_count $argv[1]
    kill -WINCH %self
end


function _vibrant_git_info
    if not set -q _vibrant_git_last_dirty_check_timestamp
        set -g _vibrant_git_last_dirty_check_timestamp 0
    end

    set -l working_tree $argv[1]
    set -l current_timestamp (_vibrant_timestamp)
    set -l time_since_last_dirty_check (math "$current_timestamp - $_vibrant_git_last_dirty_check_timestamp")

    pushd $working_tree
    if [ $time_since_last_dirty_check -gt 10 ]
        set -l cmd "command git status -unormal --porcelain --ignore-submodules ^/dev/null | wc -l"
        unique_async_job "_vibrant_async_git_dirty_check_running" _vibrant_dirty_mark_completion $cmd
    end

    set -l git_branch_name (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
    popd

    if test -n $git_branch_name
        set -l git_dirty_mark

        if set -q _vibrant_git_dirty_files_count
            if test $_vibrant_git_dirty_files_count -gt 0
                set git_dirty_mark "*"
            end
        end
        echo -ns $git_branch_name $git_dirty_mark
    end
end


function _vibrant_update_git_last_pwd
    set -l working_tree $argv[1]
    if not set -q _vibrant_git_last_pwd
        set -g _vibrant_git_last_pwd $working_tree
        return 0
    end

    if [ $_vibrant_git_last_pwd = $working_tree ]; return 0; end

    # Reset git dirty state on directory change
    set -g _vibrant_git_last_pwd $working_tree
    set -e _vibrant_git_dirty_files_count
    set -e _vibrant_git_last_dirty_check_timestamp

    # Mask any failed statuses of set calls
    return 0
end


function fish_prompt
    set last_status $status

    set -l cyan    (set_color cyan)
    set -l yellow  (set_color yellow)
    set -l red     (set_color red)
    set -l blue    (set_color blue)
    set -l green   (set_color green)
    set -l normal  (set_color normal)
    set -l magenta (set_color magenta)
    set -l white   (set_color white)
    set -l gray    (set_color 666)

    # Output the prompt, left to right

    echo -e '' # Add a newline before new prompts

    # Display username and hostname if logged in as root, in sudo or ssh session
    if [ \( (id -u) -eq 0 -o $SUDO_USER \) -o $SSH_CONNECTION ]
        echo -ns $yellow $USER $gray '@' $cyan (command hostname | command cut -f 1 -d '.') ' ' $normal
    end

    echo -ns (pwd | sed "s:^$HOME:~:") # Print pwd or full path

    # Print last command duration
    set -l cmd_duration (_vibrant_cmd_duration)
    if [ $cmd_duration ]; echo -ns $yellow ' ' $cmd_duration $normal; end

    set -l git_working_tree (command git rev-parse --show-toplevel ^/dev/null)

    # Show git branch an status
    if [ $git_working_tree ]
        _vibrant_update_git_last_pwd $git_working_tree
        set -l git_info (_vibrant_git_info $git_working_tree)
        if [ $git_info ]; echo -ns $blue ' ' $git_info $normal; end

        set -l git_arrows (_vibrant_git_arrows $git_working_tree)
        if [ $git_arrows ]; echo -ns $red ' ' $git_arrows $normal; end

        _vibrant_async_git_fetch $git_working_tree
        if set -q _vibrant_async_git_fetch_running
            echo -ns $yellow ' ⇣' $normal
        end
    end

    #echo -ns '          ' # Redraw tail of prompt on winch

    set prompt_color $green
    if [ $last_status != 0 ]; set prompt_color $red; end

    # Terminate with a nice prompt char
    echo -es $prompt_color ' ❯ ' $normal
end
