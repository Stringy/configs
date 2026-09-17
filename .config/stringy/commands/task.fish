if command -q task
    alias t="task"
    alias tn="task next"
    alias ta="task add"
    alias td="task done"
    alias te="task edit"
    alias tw="task waiting"
    alias to="task overdue"

    function tready --description "Show ready Taskwarrior tasks"
        task ready $argv
    end

    function tstart --description "Start a Taskwarrior task by ID"
        task $argv start
    end

    function tstop --description "Stop a Taskwarrior task by ID"
        task $argv stop
    end

    function tactive --description "Show active Taskwarrior tasks"
        task active $argv
    end

    function twork --description "Show work Taskwarrior tasks"
        task project:work $argv
    end

    function tpersonal --description "Show personal Taskwarrior tasks"
        task project:personal $argv
    end

    function trox --description "Add a StackRox Taskwarrior task"
        task add project:work.stackrox $argv
    end

    function tcollector --description "Add a collector Taskwarrior task"
        task add project:work.collector $argv
    end

    function tfact --description "Add a FACT Taskwarrior task"
        task add project:work.fact $argv
    end

    function thandbook --description "Add a handbook Taskwarrior task"
        task add project:work.handbook $argv
    end

    function tstringy --description "Add a Stringy Taskwarrior task"
        task add project:personal.stringy $argv
    end

    function tnotes --description "Add a notes Taskwarrior task"
        task add project:personal.notes $argv
    end

    function tnovel --description "Add a novel Taskwarrior task"
        task add project:personal.novel $argv
    end

    complete -c t -w task
    complete -c tn -w task
    complete -c ta -w task
    complete -c td -w task
    complete -c te -w task
    complete -c tw -w task
    complete -c to -w task
    complete -c tready -w task
    complete -c tstart -w task
    complete -c tstop -w task
    complete -c tactive -w task
    complete -c twork -w task
    complete -c tpersonal -w task
end
