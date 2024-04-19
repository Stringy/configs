
function git-rebase-progress
    # ( RMD="$( git rev-parse --git-path 'rebase-merge/' )" && N=$( cat "${RMD}msgnum" ) && L=$( cat "${RMD}end" ) && echo "${N} / ${L}" ; )
    # https://stackoverflow.com/a/57292015
    set -l rmd (git rev-parse --git-path 'rebase-merge/')
    set -l n (cat $rmd"msgnum")
    set -l l (cat $rmd"end")
    echo "$n / $l"
end
