This is the folder that holds the neighbourhood selection simulator.

At some point this will be packaged properly. For now, you can run it in this
directory using the "nslocal" script, which sets the correct RUBYLIB for you.

Simply running

% ./nslocal

Will give you some helpful advice on how to run experiments. Individual
subcommands have their own help pages, e.g.

% ./nslocal help run

As an example of running a simple experiment, try:

% ./nslocal run testexperiment

This will run a simple test experiment, which is defined in
config/experiments.yml. Take a look there for more information about it. Its
results will go in ./results/testexperiments/ which is specified by the option
results_dir in config/experiments.yml.

By default, raw results will be output to text files, and PDFs of various graphs
will be produced. Take a look in the results directory to see what has been
produced.

You can disable either the re-running of experiments, and therefore only
regenerate graphs, or else disable the generation of graphs and only run the
experiments by using either --nographs or --noexperiments respectively. You can
actually also use both of these options together, but that doesn't do much.

Each experiment is specified as a YAML tree in config/experiments.yml, and
references a scenario. The scenarios are found in the corresponding scenario
configuration file, typically config/scenarios.yml.

You can add your own scenarios and experiments to these files and run them as
described above. When doing this, be sure to set an appropriate results_dir, so
that you don't overwrite results from other experiments.
