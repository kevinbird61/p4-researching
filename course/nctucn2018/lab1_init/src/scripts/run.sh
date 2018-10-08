# Switch into namespace h1
ip netns exec h1 /bin/bash --rcfile <(echo "PS1=\"h1> \"")
# Switch into namespace h2
ip netns exec h2 /bin/bash --rcfile <(echo "PS1=\"h2> \"")