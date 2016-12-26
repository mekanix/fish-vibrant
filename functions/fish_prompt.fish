set __fish_git_prompt_color_branch blue

set __fish_git_prompt_char_upstream_prefix ' '
set __fish_git_prompt_char_stateseparator ' '

set __fish_git_prompt_show_informative_status true
set __fish_git_prompt_color_upstream_ahead yellow
set __fish_git_prompt_char_upstream_ahead '↑'
set __fish_git_prompt_color_upstream_behind yellow
set __fish_git_prompt_char_upstream_behind '↓'



set __fish_git_prompt_color_untrackedfiles red
set __fish_git_prompt_char_untrackedfiles '*'

set __fish_git_prompt_showdirtystate true
set __fish_git_prompt_color_dirtystate red
set __fish_git_prompt_char_dirtystate '±'

set __fish_git_prompt_color_stagedstate yellow
set __fish_git_prompt_char_stagedstate '⇈'

set __fish_git_prompt_showuntrackedfiles true
set __fish_git_prompt_color_cleanstate 777
set __fish_git_prompt_char_cleanstate '✔'



set _vbr_cyan    (set_color cyan)
set _vbr_yellow  (set_color yellow)
set _vbr_red     (set_color red)
set _vbr_blue    (set_color blue)
set _vbr_green   (set_color green)
set _vbr_gray    (set_color 777)



# [user@host] path [branch [git status]] prompt
function fish_prompt
  set -l exit_code $status
  set prompt ''

  echo
  if [ \( (id -u) -eq 0 -o $SUDO_USER \) -o $SSH_CONNECTION ]
    set -l host (hostname | cut -f 1 -d '.')
    set user_prompt $_vbr_yellow$USER$_vbr_gray'@'$_vbr_cyan$host
    echo $user_prompt
  end

  set git_prompt (__fish_git_prompt '%s')
  if [ ! -z "$git_prompt" ]
    echo $git_prompt
  end

  if [ $exit_code != 0 ]
    set symbol_prompt $prompt $_vbr_red'♦ '
  else
    set symbol_prompt $prompt $_vbr_green'♦ '
  end

  set path_prompt $_vbr_cyan(pwd | sed "s:^$HOME:~:")
  echo $path_prompt $symbol_prompt
end
